NetSH WinHTTP Import Proxy Source=IE
Set-ExecutionPolicy RemoteSigned

#ModInstall
Install-Module -Name MSOnline
Install-Module -Name AzureAD
Install-Module -Name ExchangeOnlineManagement

#Modimport
Import-Module -Name MSOnline
Import-Module -Name AzureAD
Import-Module -Name ExchangeOnlineManagement

#Login & Sessions
$Domain = $args[2]
$Username = $args[0]
$Password = $args[1]
$SecSTR = New-Object -TypeName System.Security.SecureString
$Password.ToCharArray() | ForEach-Object {$SecSTR.AppendChar($_)}
$O365Cred= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecSTR
Connect-AzureAD -Credential $O365Cred
Connect-MSOLService -Credential $O365Cred
Connect-IPPSSession -ConnectionUri https://eur04b.ps.compliance.protection.outlook.com/Powershell-LiveId/ -Credential $O365Cred
$EXOSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365Cred -Authentication Basic -AllowRedirection
$SCCSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $O365Cred -Authentication Basic -AllowRedirection
Import-PSSession $EXOSession -AllowClobber
Import-PSSession $SCCSession -AllowClobber

#read csv
$csv = Import-Csv -Path .\export\Students.csv -Delimiter ','
$csv | Format-Table
ForEach($user in $csv){
	$DisplayName = $user.name + ' ' + $user.surname
	$UPN = $user.surname + '.' + $user.name + $domain
    $MailNickName = $user.Name + ' ' + $user.Surname

	$check = Get-AzureADUser -ObjectId $user.surname+'.'+$user.name+$domain
	if($check){
	#USER EXISTS
	#TODO add user enrollment purge then enroll to new groups
	
	} else {
	#USER DOESN'T EXIST
        #$PasswordProfile=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
        #$PasswordProfile.Password=$defaultPassword
        New-AzureADUser -DisplayName $DisplayName -GivenName $user.name -SurName $user.urname -UserPrincipalName $UPN -UsageLocation "Pl" -MailNickName $MailNickName -PasswordProfile $user.password -AccountEnabled $True
        Write-Host 'Added user '+$user.name+' '+$user.surname
	}
}
#give a minute for M$ to process users
Start-Sleep -seconds 90

#Enroll users
ForEach($user in $csv){
    $groups = $user.groups.Split("*")
    $user = $user.surname + '.' + $user.name + $domain
    ForEach($group in groups){
        $gp = $group + $domain
        Add-UnifiedGroupLinks –Identity $gp –LinkType "Members" –Links $user
        Write-Host "Added user" $user "to group:" $gp
    }
}


