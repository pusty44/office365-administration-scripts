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

Param([ValidateNotNullOrEmpty()][Alias("UserToRemove")][String[]]$Identity,[switch]$IncludeAADSecurityGroups,[switch]$IncludeOffice365Groups) 


# check if can connect to exchange remote powershell
function Check-Connectivity { 
    [cmdletbinding()] 
  
    param([switch]$IncludeAADSecurityGroups) 
   # Write-Verbose "Checking connectivity to Exchange Remote PowerShell..."
    if (!$session -or ($session.State -ne "Opened")) { 
        try { $script:session = Get-PSSession -InstanceId (Get-AcceptedDomain | select -First 1).RunspaceId.Guid -ErrorAction Stop  } 
        catch { 
            try {  
                $script:session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential (Get-Credential) -Authentication Basic -AllowRedirection -ErrorAction Stop  
                Import-PSSession $session -ErrorAction Stop | Out-Null  
            }   
            catch { Write-Error "No active Exchange Remote PowerShell session detected, please connect first. To connect to ExO: https://technet.microsoft.com/en-us/library/jj984289(v=exchg.160).aspx" -ErrorAction Stop } 
        } 
    } 
    if ($IncludeAADSecurityGroups) { 
        #Write-Verbose "Checking connectivity to Azure AD..."
        if (!(Get-Module AzureAD -ListAvailable -Verbose:$false | ? {($_.Version.Major -eq 2 -and $_.Version.Build -eq 0 -and $_.Version.Revision -gt 55) -or ($_.Version.Major -eq 2 -and $_.Version.Build -eq 1)})) { Write-Host -BackgroundColor Red "This script requires a recent version of the AzureAD PowerShell module. Download it here: https://www.powershellgallery.com/packages/AzureAD/"; return} 
        try { Get-AzureADCurrentSessionInfo -ErrorAction Stop -WhatIf:$false -Verbose:$false | Out-Null } 
        catch { try { Connect-AzureAD -WhatIf:$false -Verbose:$false -ErrorAction Stop | Out-Null } catch { return $false } } 
    } 
  
    return $true 
} 
  
function Remove-UserFromAllGroups { 
    [CmdletBinding(SupportsShouldProcess=$true)] 
    Param 
    ( 
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ValueFromRemainingArguments=$false)] 
        [ValidateNotNullOrEmpty()][Alias("UserToRemove")][String[]]$Identity, 
        [switch]$IncludeAADSecurityGroups, 
        [switch]$IncludeOffice365Groups) 
  
    Begin { 
        if (Check-Connectivity -IncludeAADSecurityGroups:$IncludeAADSecurityGroups) { Write-Verbose "Parsing the Identity parameter..." } 
        else { Write-Host "ERROR: Connectivity test failed, exiting the script..." -ForegroundColor Red; continue }  
    } 
  
    Process { 
        $GUIDs = @{} 
  
        foreach ($us in $Identity) { 
            Start-Sleep -Milliseconds 80 
            $GUID = Invoke-Command -Session $session -ScriptBlock { Get-User $using:us | Select-Object DistinguishedName,ExternalDirectoryObjectId } -ErrorAction SilentlyContinue 
            if (!$GUID) { Write-Verbose "Security principal with identifier $us not found, skipping..."; continue } 
            elseif (($GUID.count -gt 1) -or ($GUIDs[$us]) -or ($GUIDs.ContainsValue($GUID))) { Write-Verbose "Multiple users matching the identifier $us found, skipping..."; continue } 
            else { $GUIDs[$us] = $GUID | Select-Object DistinguishedName,ExternalDirectoryObjectId } 
        } 
        if (!$GUIDs -or ($GUIDs.Count -eq 0)) { Write-Host "ERROR: No matching users found for ""$Identity"", check the parameter values." -ForegroundColor Red; return } 
        #Write-Verbose "The following list of users will be used: ""$($GUIDs.Values.DistinguishedName -join ", ")"""
        foreach ($user in $GUIDs.GetEnumerator()) { 
            #Write-Verbose "Processing user ""$($user.name)""..."
            Start-Sleep -Milliseconds 80 
            #Write-Verbose "Obtaining group list for user ""$($user.name)""..."
            if ($IncludeOffice365Groups) { $GroupTypes = @("GroupMailbox","MailUniversalDistributionGroup","MailUniversalSecurityGroup") } 
            else { $GroupTypes = @("MailUniversalDistributionGroup","MailUniversalSecurityGroup") } 
            $Groups = Invoke-Command -Session $session -ScriptBlock { Get-Recipient -Filter "Members -eq '$($using:user.Value.DistinguishedName)'" -RecipientTypeDetails $Using:GroupTypes | Select-Object DisplayName,ExternalDirectoryObjectId,RecipientTypeDetails } -ErrorAction SilentlyContinue -HideComputerName 
            #if (!$Groups) { Write-Verbose "No matching groups found for ""$($user.name)"", skipping..." }
            #else { Write-Verbose "User ""$($user.name)"" is a member of $(($Groups | measure).count) group(s)." }
            foreach ($Group in $Groups) { 
                #Write-Verbose "Removing user ""$($user.name)"" from group ""$($Group.DisplayName)"""
                if ($Group.RecipientTypeDetails.Value -eq "GroupMailbox") { 
                    try { Invoke-Command -Session $session -ScriptBlock { Remove-UnifiedGroupLinks -Identity $using:Group.ExternalDirectoryObjectId -Links $using:user.Value.DistinguishedName -LinkType Member -Confirm:$false -WhatIf:$using:WhatIfPreference } -ErrorAction Stop -HideComputerName } 
                    catch [System.Management.Automation.RemoteException] { 
                        if ($_.CategoryInfo.Reason -eq "ManagementObjectNotFoundException") { Write-Host "ERROR: The specified object not found, this should not happen..." -ForegroundColor Red } 
                        elseif ($_.CategoryInfo.Reason -eq "RecipientTaskException" -and $_.Exception -match "Couldn't find object") { Write-Host "ERROR: User object ""$($user.name)"" not found, this should not happen..." -ForegroundColor Red } 
                        elseif ($_.CategoryInfo.Reason -eq "RecipientTaskException" -and $_.Exception -match "Only Members who are not owners") { Write-Host "ERROR: User object ""$($user.name)"" is Owner of the ""$($Group.DisplayName)"" group and cannot be removed..." -ForegroundColor Red } 
                        else {$_ | fl * -Force; continue} 
                    } 
                    catch {$_ | fl * -Force; continue} 
                } 
                else {  
                    try { Invoke-Command -Session $session -ScriptBlock { Remove-DistributionGroupMember -Identity $using:Group.ExternalDirectoryObjectId -Member $using:user.Value.DistinguishedName -BypassSecurityGroupManagerCheck -Confirm:$false -WhatIf:$using:WhatIfPreference -ErrorAction Stop } } 
                    catch [System.Management.Automation.RemoteException] { 
                        if ($_.CategoryInfo.Reason -eq "ManagementObjectNotFoundException") { Write-Host "ERROR: The specified object not found, this should not happen..." -ForegroundColor Red } 
                        elseif ($_.CategoryInfo.Reason -eq "MemberNotFoundException") { Write-Host "ERROR: User ""$($user.name)"" is not a member of the ""$($Group.DisplayName)"" group..." -ForegroundColor Red } 
                        else {$_ | fl * -Force; continue} 
                    } 
                    catch {$_ | fl * -Force; continue} 
                } 
            } 
            if ($IncludeAADSecurityGroups) { 
                #Write-Verbose "Obtaining security group list for user ""$($user.name)""..."
                $GroupsAD = Get-AzureADUserMembership -ObjectId $user.Value.ExternalDirectoryObjectId -All $true | ? {$_.ObjectType -eq "Group" -and $_.SecurityEnabled -eq $true -and $_.MailEnabled -eq $false} 
  
                #if (!$GroupsAD) { Write-Verbose "No matching security groups found for ""$($user.name)"", skipping..." }
                #else { Write-Verbose "User ""$($user.name)"" is a member of $(($GroupsAD | measure).count) security group(s)." }
                foreach ($groupAD in $GroupsAD) { 
                    #Write-Verbose "Removing user ""$($user.name)"" from group ""$($GroupAD.DisplayName)"""
                    if (!$WhatIfPreference) { 
                        try { Remove-AzureADGroupMember -ObjectId $GroupAD.ObjectId -MemberId $user.Value.ExternalDirectoryObjectId -ErrorAction Stop } 
                        catch [Microsoft.Open.AzureAD16.Client.ApiException] { 
                            if ($_.Exception.Message -match ".*Insufficient privileges to complete the operation") { Write-Host "ERROR: You cannot remove members of the ""$($groupAD.DisplayName)"" Dynamic group, adjust the membership filter instead..." -ForegroundColor Red } 
                            elseif ($_.Exception.Message -match ".*Invalid object identifier") { Write-Host "ERROR: Group ""$($groupAD.DisplayName)"" not found, this should not happen..." -ForegroundColor Red } 
                            elseif ($_.Exception.Message -match ".*Unsupported referenced-object resource identifier") { Write-Host "ERROR: User ""$($user.name)"" not found, this should not happen..." -ForegroundColor Red } 
                            elseif ($_.Exception.Message -match ".*does not exist or one of its queried reference-property") { Write-Host "ERROR: User ""$($user.name)"" is not a member of the ""$($groupAD.DisplayName)"" group..." -ForegroundColor Red } 
                            else {$_ | fl * -Force; continue} 
                        } 
                        catch {$_ | fl * -Force; continue} 
                    } 
                    else { Write-Host "WARNING: The Azure AD module cmdlets do not support the use of -WhatIf parameter, action was skipped..." } 
            }} 
        }} 
} 



#read csv
$csv = Import-Csv -Path .\export\Students.csv -Delimiter ','
$csv | Format-Table
ForEach($user in $csv){
	$DisplayName = $user.name + ' ' + $user.surname
	$UPN = $user.surname + '.' + $user.name + $domain
    $MailNickName = $user.name + ' ' + $user.surname

	$UserCheck = Get-MsolUser -UserPrincipalName $UPN -ErrorAction SilentlyContinue
	if($UserCheck -ne $Null){
	#USER EXISTS
        if (($PSBoundParameters | measure).count) {
        Remove-UserFromAllGroups @PSBoundParameters -Identity $UPN -IncludeOffice365Groups:$true
        }  else {
        Write-Host "INFO: The script was run without parameters, consider dot-sourcing it instead." -ForegroundColor Cyan
        }

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


