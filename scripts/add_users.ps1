Install-module -name AzureAD
Import-module -name AzureAD

#connection
netsh winhttp import proxy source=ie
import-module exchangeonlinemanagement
$username = $args[0]
$password = $args[1]
$domain = $args[2]
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$O365Cred= new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr 
Connect-AzureAD -Credential $O365Cred

#Create new default password for users


#read csv
$csv = Import-Csv -Path .\export\Students.csv -Delimiter ','
$csv | Format-Table
ForEach($user in $csv){
	$groups = $user.groups.Split("*")
	$check = Get-AzureADUser -ObjectId $user.surname+'.'+$user.name+$domain
	if($check){
	#USER EXISTS
	#TODO add user enrollment purge then enroll to new groups
	
	} else {
	#USER DOESN'T EXIST
        #$PasswordProfile=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
        #$PasswordProfile.Password=$defaultPassword
		New-AzureADUser -DisplayName $user.name+' '+$user.surname -GivenName $user.name -SurName $user.surname -UserPrincipalName $user.surname+'.'+$user.name+$domain -UsageLocation "PL"	-MailNickName $user.name+' '+$user.surname -PasswordProfile $user.password -AccountEnabled $true
		Write-Host 'Added user '+$user.name+' '+$user.surname
        #enroll user to new groups
		ForEach($groups in $group){
			Add-UnifiedGroupLinks –Identity $group.alias+$domain –LinkType "Members" –Links $user.surname+'.'+$user.name+$domain
			Write-Host 'Added user '+$user.name+' '+$user.surname+' to group: '+$group.alias
		}

	}
	
	
}


