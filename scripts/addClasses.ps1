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
    $GroupID = Get-UnifiedGroup $alias | select -expand ExternalDirectoryObjectId
    $TeamCheck = "0"
    $TeamCheck = Get-Team -GroupID $GroupID

    if($check -ne $Null){
        #Write-Host `n "The group" $Group.name "-" $GroupAddress  "exists in Azure AD" -ForegroundColor Green
        If ($TeamCheck -ne "0") {
            #Write-Host "A team was detected for" $Group.Alias -ForegroundColor Green                                                                   }
        } else {
            #Write-Host "A team was not detected for" $Group.Alias -ForegroundColor Red
            New-Team -Group $GroupID
            #Write-Host "Created a new team for" $Group.name -ForegroundColor Green
        }

    } else {
        #create new group
    	#Write-Host `n "The group" $group.name "does not exist." -ForegroundColor Red
        #Write-Host "Need to create" $Group.name "-" $GroupAddress -ForegroundColor Cyan
        New-UnifiedGroup -DisplayName $group.name -Alias $alias -AccessType Private
        Start-Sleep -seconds 2
        #Write-Host "Added group " $Group.name "-" $GroupAddress -ForegroundColor Green
        Start-Sleep -seconds 2
        New-Team -Group $GroupID
        #Write-Host "Created a new team for" $Group.name -ForegroundColor Green
    }
}