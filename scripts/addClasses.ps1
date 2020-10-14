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
$csv = Import-Csv -Path .\export\Groups.csv -Delimiter ','
$csv | Format-Table
ForEach($group in $csv){
    $alias = $group.alias+$domain
    $check = Get-UnifiedGroup -Identity $alias
    if($check){
        #do nothing
    } else {
        #create new group
    	New-UnifiedGroup -DisplayName $group.name -Alias $group.alias -EmailAddresses $alias -AccessType Private
    	Write-Host 'Added group '+$group.name
    }

}