Install-module -name AzureAD
Import-module -name AzureAD

#connection
netsh winhttp import proxy source=ie
import-module exchangeonlinemanagement
$username = $args[0]
$password = $args[1]
$defaultPassword = $args[2]
$domain = $args[3]
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$O365Cred= new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr 
Connect-AzureAD -Credential $O365Cred

#Create new default password for users
$PasswordProfile=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password=$defaultPassword

##############################
##########ADD GROUPS##########
##############################
#import groups.csv
#csv looks like: name;alias;
$csv = Import-Csv -Path .\groups.csv -Delimiter ','
$csv | Format-Table
ForEach($group in $csv){
	New-UnifiedGroup -DisplayName $group.name -Alias $group.alias -EmailAddresses $group.alias+$domain -AccessType Private
	Write-Host 'Added group '+$group.name
}

##############################
##########ADD USERS###########
##############################
#import users.csv
#csv looks like: name;surname;position;groups;
$csv = Import-Csv -Path .\users.csv -Delimiter ','
$csv | Format-Table
ForEach($user in $csv){
	$groups = $user.groups.Split("*")
	$check = Get-AzureADUser -ObjectId $user.surname+'.'+$user.name+$domain
	if($check){
	#USER EXISTS
	
	} else {
	#USER DOESN'T EXIST
		New-AzureADUser -DisplayName $user.name+' '+$user.surname -GivenName $user.name -SurName $user.surname -UserPrincipalName $user.surname+'.'+$user.name+$domain -UsageLocation "PL"	-MailNickName $user.name+' '+$user.surname -PasswordProfile $PasswordProfile -AccountEnabled $true
		Write-Host 'Added user '+$user.name+' '+$user.surname
		##############################
		#####ADD USERS TO GROUPS######
		##############################
		ForEach($groups in $group){
			Add-UnifiedGroupLinks –Identity $group.alias+$domain –LinkType "Members" –Links $user.surname+'.'+$user.name+$domain
			Write-Host 'Added user '+$user.name+' '+$user.surname+' to group: '+$group.alias
		}

	}
	
	
}


