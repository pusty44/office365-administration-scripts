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

#read csv
$csv = Import-Csv -Path .\export\Groups.csv -Delimiter ','
$csv | Format-Table
ForEach($group in $csv){
    $check = Get-UnifiedGroup -Identity $group.alias+$domain
    if($check){
        #do nothing
    } else {
        #create new group
    	New-UnifiedGroup -DisplayName $group.name -Alias $group.alias -EmailAddresses $group.alias+$domain -AccessType Private
    	Write-Host 'Added group '+$group.name
    }

}