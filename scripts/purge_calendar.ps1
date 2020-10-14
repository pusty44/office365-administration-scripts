#Get required modules
install-module exchangeonlinemanagement

#Connect
netsh winhttp import proxy source=ie
import-module exchangeonlinemanagement
$username = $args[0]
$password = $args[1]
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$O365Cred= new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr 
Connect-IPPSSession -ConnectionUri https://eur04b.ps.compliance.protection.outlook.com/Powershell-LiveId/ -Credential $O365Cred 
$EXOSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365Cred -Authentication Basic -AllowRedirection
Import-PSSession $EXOSession -AllowClobber
$SCCSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $O365Cred -Authentication Basic -AllowRedirection
Import-PSSession $SCCSession -AllowClobber

$groupList = Get-UnifiedGroup
ForEach($item in $groupList){
	#Create and run new compliance search
	#-name - set name for search
	#-exchangelocation - group mail
	new-compliancesearch -name $item.GUID -exchangelocation $item.EmailAddresses -contentmatchquery kind:meetings
	start-compliancesearch -identity $item.GUID
	#Run purge request based on previous search
	new-compliancesearchaction -searchname $item.GUID -purge -purgetype harddelete
}

#Check action state
get-compliancesearchaction -identity "test_Purge" | fl

write-host "Kalendarze wszystkich grup zostały wyczyszczone!" 


