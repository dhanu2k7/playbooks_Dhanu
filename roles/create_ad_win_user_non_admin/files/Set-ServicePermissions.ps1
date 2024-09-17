[CmdletBinding()]
Param (
    [parameter(Mandatory = $false, Position = 0)]
        [Alias('username')]
        [string] $user
)


# Log: Write to console or logfile
Function Log($trace) {
    $current_time = Get-Date
    try {
        if ($stdout) {
            Write-Host "$current_time $trace"
        } 
        # Write to logfile
        Add-Content $script:log_filepath "[$current_time] $trace"
    }
    catch {
        if ($stdout) {
            Write-Host "[$current_time] Log(): Error occurred while using logfile - detail - $_"
        }
    }
}

# LogDebug: Write to console or logfile only if debug flag on
Function LogDebug($trace) {
    if ($debug_all -ne $false) {
        Log $trace
    }
}

# SaveOriginal: Save the original setting of a property before applying a change to it
# for reverting if necessary
Function SaveOriginal($prop_name, $prop_val) {
    $current_time = Get-Date
    try {
        Log "SaveOriginal: Saving original value `"$prop_val`" for property `"$prop_name`""
        # Save to backup file
        Add-Content $script:original_settings_path "[$current_time]  `"$prop_name`" ==> `"$prop_val`" "
    }
    catch {
        Log "[$current_time] SaveOriginal: Error occurred while saving original setting for `"$prop_name`" - detail - $_"
    }
}

# IsRunByAdmin: Ensure the user executing the script has Administrator rights - this is not requiring the account used in the configuration
# to be in the Administrator group
Function IsRunByAdmin() {
    $bAdmin = $false
    Log "IsRunByAdmin: Checking if user running this utility in an Administrator context ..."
    try {
        $bAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    catch {
        Log "IsRunByAdmin: Exception caught while retrieving current user role - detail - $_"
    }

    if ($bAdmin -eq $false) {
        if ($silent) {
            Log "IsRunByAdmin: Error - this script is not being run by a member of the Administrator's group on this computer.  It must be run under an administrative account to be successful."
        }
        else {
            Log "IsRunByAdmin: Error - this script is not being run by a member of the Administrator's group on this computer.  It must be run under an administrative account to be successful."
            [System.Windows.Forms.MessageBox]::Show("You do not have Administrator rights to run this script! Please re-run this script as an Administrator.", "Error", $script:okButton)
        }
    }
    return $bAdmin
}

# GetAccountSID: Retrieves the S-xxx security identifier for the user account chosen for use for configuration and returns
# either a SecurityIdentifier object or the SID string representation (if return_string is true)
Function GetAccountSID($user_account, $return_string)
{
    $objUser = $null
    $sid = $null
    $user = $null
    $domain = $null
    $sid_obj = $null


    if ($user_account.Contains('\')) {
        $domainaccount = $user_account.Split('\')
        $domain = $domainaccount[0]
        $user = $domainaccount[1]
    } elseif ($user_account.Contains('@')) {
        $user, $domain = $user_account.Split('@') # both results will be send to the appropriate variable
    } else {
        $user = $user_account
    }

    try {
        if (($domain -ne $null) -and ($domain.Length -gt 0)) {
            Log "GetAccountSID: Creating object for (AD user) domain: `"$domain`" and user `"$user`""
            $objUser = New-Object System.Security.Principal.NTAccount($domain, $user)
        } else {
            Log "GetAccountSID: Creating object for local (non-AD) user `"$user`""
            $objUser = New-Object System.Security.Principal.NTAccount($user)
        }

        if ($objUser -ne $null) {
            Log "GetAccountSID: Translating account object to SID instance"
            $sid_obj = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
            $sid = $sid_obj.Value
            $sid = $sid.ToString()
            Log "GetAccountSID: SID retrieved for the specified user account to be used as SL1 credential is `"$sid`""
        }
    } catch {
        Log "GetAccountSID: Exception caught while translating account to SID - detail - $_"
    }

    # Return string representation or SID object, which caller may need to use in other APIs
    if ($return_string) {
        return $sid
    } else {
        return $sid_obj
    }
}

Function IsAccountInAdminGroup($account_name)
{
    $bInAdminGrp = $false
    $bPrependDomainToLocalUser = $true
    $members = @()
    if (($account_name -ne $null) -and ($account_name.Length -gt 0)) {
        $groupObj = [ADSI]"WinNT://./Administrators,group"
        $membersObj = @($groupObj.psbase.Invoke("Members"))

        # First try ADSpath so we have domain\user format
        Log "IsAccountInAdminGroup: Querying ADS path for Administrators members"
        $members = ($membersObj | ForEach-Object { $_.GetType().InvokeMember('ADspath', 'GetProperty', $null, $_, $null).Replace('WinNT://', '').Replace("/", "\") })
        if ($members.Count -eq 0) {
            # Get user names only in the Administrators group for comparison
            $members = ($membersObj | ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)})
            $bPrependDomainToLocalUser = $false  # Do not match on usernames with domain prepended since Name property does not contain domain names
        }

        # Fix $account_name based on whether our list has domain names or not
        if (($bPrependDomainToLocalUser -eq $true) -and (-not $account_name.Contains('\'))) {
            $account_name = $script:localhost_name + '\' + $account_name
        }

        # Check members array for the user account
        Log "IsAccountInAdminGroup: Looking for user `"$account_name`" in Administrators group"
        if ($members -Contains $account_name) {
            Log "IsAccountInAdminGroup: User `"$account_name`" is in the Administrators group, so returning True."
            $bInAdminGrp = $true
        } else {
            Log "IsAccountInAdminGroup: User `"$account_name`" is *not* in the Administrators group, so returning False."
        }
    } else {
        Log "IsAccountInAdminGroup: A null or empty account name was passed in, so we cannot determine group membership."
    }
    return $bInAdminGrp
}

# SetServicePermissions
Function SetServicePermissions() {
    $bSuccess = $true
    $sddl = $null
    $final_sddl = $null
    Log "SetServicePermissions: Enter"

    # If user is in the Administrators group, no need to proceed here.
    if (IsAccountInAdminGroup($script:account) -eq $true) {
        Log "SetServicePermissions: User `"$script:account`" is already in the local Administrators group, so no need to add this user."
        return $bSuccess
    }

    # Set SDDL snippet we want to on SCMANAGER and each service
    # Grants SERVICE_QUERY_CONFIG (CC), SERVICE_QUERY_STATUS (LC), READ_CONTROL (RC),
    # and SERVICE_START (RP), SERVICE_ENUMERATE_DEPENDENTS(SW), SERVICE_INTERROGATE(LO)
    $sddl_insertion_scm = "A;;CCLCSWLORPRC;;;$script:account_sid"
    $sddl_insertion_svc = "A;;CCLCSWLORPRC;;;$script:account_sid"

    # HKLM\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\Security holds these updates

    # (1) Get SDDL for SCMANAGER and insert permission for SL1 credential user specified
    LogDebug "SetServicePermissions: Running `"sc.exe sdshow SCMANAGER`" to get SDDL for services control manager."
    $scm_sddl = Invoke-Command -ScriptBlock { sc.exe sdshow SCMANAGER }
    if (($scm_sddl -ne $null) -and ($scm_sddl.Length -gt 0)) {
        $output = $null
        $scm_sddl = $scm_sddl.Trim()
        LogDebug "SetServicePermissions: -- SDDL for SCMANAGER returned is: `"$scm_sddl`""
        SaveOriginal "SDDL (SCMANAGER)" $scm_sddl
        $final_sddl = CreateFinalSDDL $script:account_sid $sddl_insertion_scm $scm_sddl
        if (($final_sddl -ne $null) -and ($final_sddl.Length -gt 0)) {
            # Set the SDDL in SCMANAGER
            LogDebug "SetServicePermissions: -- Calling sc.exe sdset SCMANAGER to set new SDDL to `"$final_sddl`""
            $output = Invoke-Command -ScriptBlock { sc.exe sdset SCMANAGER $final_sddl } -ErrorAction SilentlyContinue
            if (($output -ne $null) -and ($output.Length -gt 0)) {
                Log "SetServicePermissions: -- Setting permissions on SCMANAGER returned: `"$output`""
            }
            else {
                Log "SetServicePermissions: -- Nothing returned by sc.exe sdset SCMANAGER."
            }

            # We can add later another call to 'sdshow SCMANAGER' to see if updated SDDL was saved properly - the output will typically
            # set us from sdset
        }
        else {
            Log "SetServicePermissions: -- Warning - no final SDDL string was returned for setting in service permissions - this may be fine if the ACL already exists."
        }

    }
    else {
        Log "SetServicePermissions: -- Error: unable to get the existing SDDL set for SCMANAGER, so cannot provide permissions to SL1 credential user"
        $bSuccess = $false
    }

    if ($error.count -gt 0) {
        $error_string = $error[0].ToString()
        Log "SetServicePermissions: After fetching SDDL for SCMANAGER, most recent error => $error_string"
    }
    $error.clear()



    # (2) Get SDDL for every Windows service and insert permission for SL1 credential user specified
    $service_list = Get-Service
    foreach ($service in $service_list) {
        $service = $service.ToString()
        LogDebug "SetServicePermissions: -- Getting SDDL for service `"$service`""
        $scm_sddl = Invoke-Command -ScriptBlock { sc.exe sdshow $service }
        if (($scm_sddl -ne $null) -and ($scm_sddl.Length -gt 0)) {
            $output = $null
            $scm_sddl = $scm_sddl.Trim()
            LogDebug "SetServicePermissions: -- SDDL for this service returned is: `"$scm_sddl`""
            SaveOriginal "SDDL ($service)" $scm_sddl
            $final_sddl = CreateFinalSDDL $script:account_sid $sddl_insertion_svc $scm_sddl
            if (($final_sddl -ne $null) -and ($final_sddl.Length -gt 0)) {
                # Set the SDDL in SCMANAGER
                Log "SetServicePermissions:--  Calling `"sc.exe sdset $service`" to set new SDDL to `"$final_sddl`""
                $output = Invoke-Command -ScriptBlock { sc.exe sdset $service $final_sddl } -ErrorAction SilentlyContinue
                if (($output -ne $null) -and ($output.Length -gt 0)) {
                    Log "SetServicePermissions: -- Setting permissions on service `"$service`" returned: `"$output`""
                }
                else {
                    Log "SetServicePermissions: -- Nothing returned by sc.exe sdset for this service. "
                }
                # We can add later another call to 'sdshow $service' to see if updated SDDL was saved properly - the output will typically
                # set us from sdset
            }
            else {
                Log "SetServicePermissions: -- Warning - no final SDDL string was returned for setting in service permissions - this may be fine if the ACL already exists."
            }
        }
        else {
            Log "SetServicePermissions: -- Error - unable to get the existing SDDL set for service `"$service`" so cannot provide permissions to SL1 credential user"
            $bSuccess = $false
        }

        if ($error.count -gt 0) {
            $error_string = $error[0].ToString()
            Log "SetServicePermissions: After fetching SDDL for every service and updating it, most recent error => $error_string"
        }
        $error.clear()

    }  # end foreach service

    Log "SetServicePermissions: Exit"

    return $bSuccess
}

# CreateFinalSDDL: take two strings of SDDL and place the insertion string in the Discretionary ACL portion
# of the SDDL and return the final string for use.
Function CreateFinalSDDL([String] $user_sid, [String] $insertion_string, [String] $sddl) {
    $final_sddl = ""
    $sacl = ""
    $dacl = ""
    LogDebug "CreateFinalSDDL: Enter with user SID `"$user_sid`" and SDDL string `"$sddl`""

    # Separate the SACL (System Access Control List) from DACL (Discretionary Access List), and then insert
    # our required SL1 SID ACL at the end of DACL list, putting entire SDDL back together.
    $found_sacl = $false
    $remove_existing_acl = $false

    # First ensure the SID for this user is not already in the SDDL - if it is, if it is not what we are setting, remove it, so we 
    # can reset the ACL for the user to what we need
    if ($sddl -Like "*$user_sid*") {
        if ($sddl -Like "*$insertion_string*") {
            LogDebug "CreateFinalSDDL: ** Not inserting the new ACL for the account into the existing SDDL as it already exists there."
            return $final_sddl
        }
        else {
            # User/Group SID found in SDDL already but not identical, so we need to parse it from the DACL and reinsert it
            LogDebug "CreateFinalSDDL: User/group SID found in SDDL but it is not identical, so we will replace with ACL for SL1."
            $remove_existing_acl = $true
        }
    }

    # Split the existing SDDL string into a maximum of 2 strings, preserving the S:
    foreach ($sddl_part in ($sddl -split '(S:)', 2)) {
        if ($sddl_part -eq 'S:') {
            $found_sacl = $true
        }
        if ($found_sacl) {
            # Append remaining parts to SACL string
            $sacl += $sddl_part
        }
        else {
            # Append to DACL string
            $dacl += $sddl_part
        }
    }

    LogDebug "CreateFinalSDDL: DACL string after parsing on Discretionary/System = `"$dacl`""
    LogDebug "CreateFinalSDDL: SACL string after parsing on Discretionary/System = `"$sacl`""

    # Remove section with user/group SID if found earlier - not doing so results in access denied error
    if ($remove_existing_acl) {
        $found = $dacl -match "A;;\w+;;;$user_sid"
        if ($found) {
            if (($Matches[0] -ne $null) -and ($Matches[0].Length -gt 0)) {
                # Making sure we matched on expected string and that it starts with a left paren, then 'A' for Allow
                # since this is going to be a replaced string
                $replacement = $Matches[0]
                $replacement = $replacement.TrimStart('(')
                $replacement = $replacement.TrimEnd(')')
                LogDebug "CreateFinalSDDL: Replacing existing DACL substring `"$replacement`" with updated string of `"$insertion_string`""
                $output = $dacl -replace $replacement, $insertion_string
                LogDebug "CreateFinalSDDL: Final DACL `"$output`""

                # Since we replaced a substring in the dacl, just concatenate dacl and sacl
                $final_sddl = $output + $sacl
            }
        }
        else {
            # No need to replace anything - should not get into this block
            LogDebug "CreateFinalSDDL: ACL with user SID `"$user_sid`" not found in DACL portion of existing SDDL, so no replacement being made."
        }
    }
    else {
        $final_sddl = $dacl + '(' + $insertion_string + ')' + $sacl
    }

    LogDebug "CreateFinalSDDL: Exit and returning final SDDL `"$final_sddl`""
    return $final_sddl
}

# Script variables - values are passed in or later set through dialog entry
$script:major_ps_ver = 1
$script:set_wmi_inherit_obj = $false

$script:account = $null
$script:account_user = $null
$script:account_domain = $null
$script:domain_acct = $false  # helper for identifying local versus Active Directory domain account
$script:account_sid = $null


if ($silent -and !$set_timeout) {
    # If in silent mode, only enable setting the timeout if the set_timeout switch was specified
    $script:winrm_set_idle = $false
}

# User/silo_user flag is not required, but some aspects of the configuration cannot be performed, so those
# will be skipped when an account is not specified (even if run interactively)
if ($user) {
    $script:account = $user.Trim()
    if ($user -match "\\") {
        Log "Main: Domain user account specified for configuration: `"$script:account`""
        $script:domain_acct = $true
        $domain_account = $script:account.Split('\')
        $script:account_domain = $domain_account[0]
        $script:account_user = $domain_account[1]
    } else {
        Log "Main: Local user account specified for configuration: `"$script:account`""
        $script:account_domain = $null
        $script:account_user = $script:account
    }

    # Get the user account SID for setting security for this user
    # Future: allow AD group names to be specified instead of just users - ensure group SID can be used where user account settings are
    $script:account_sid = GetAccountSID $script:account $true
    if ($script:account_sid -eq $null) {
        Log "Main: Warning - unable to find SID for the specified user, so some security cannot be set!"
        Write-Host "Error - unable to retrieve the security ID for user `"$script:account`", so the script cannot continue!"
        exit
    } else {
        Log "Main: User SID retrieved is `"$script:account_sid`""
    }
}

$script:wmi_namespace_root = "root"  # top of WMI namespace tree necessary to have read/execute permissions on for monitoring
$script:computer_name = $Env:ComputerName.ToUpper()  # Hostname, in all caps


# Some permission bitmasks
$GENERIC_READ = 0x80000000
$GENERIC_WRITE = 0x40000000
$GENERIC_EXECUTE = 0x20000000
$GENERIC_ALL = 0x10000000

# String constants
$NOT_ADMIN = "You do not have Administrator rights for successful use of this utility. Please run this script as an Administrator."
$script:original_settings_path = ""
$script:original_settings_file = "silo_winrm_original_settings.log"

# Setup logging to a file location on the Windows computer
$logfile_name = "silo_winrm_config.log"   # Default logfile name if no override from command-line

# Retrieve current WinRM and other configuration values and save them to file
try {

    # Ensure user is running this utility as an Administrator
    $IsAdmin = IsRunByAdmin
    if ($IsAdmin -eq $false) {
        if ($silent -eq $false) {
            [System.Windows.Forms.MessageBox]::Show($NOT_ADMIN, "Error", $script:okButton)
        }
        Log "Main: Error - This script is not being run with Administrator privileges, so exiting."
        exit
    }

    # Get computer name
    $script:localhost_name = (Get-WmiObject Win32_ComputerSystem).Name
    Log "Main: Hostname is `"$script:localhost_name`""

    SetServicePermissions


    # Write error and warning summary to end of std output
    # and log file
    if ($script:error_summary  -ne $null) {
        Log "****************************************************************************`n`n"
        Log "List of errors and warnings encountered during execution: `n"
        Log "$($script:error_summary)`n`n"
        Log "****************************************************************************`n`n"
    }

    Log "Main: Configuration has completed. Exiting ....`r`n`r`n`r`n`r`n`r`n`r`n`r`n"

}
catch {
    Log "Main: Exception caught while executing - detail - $_ `r`n`r`n`r`n`r`n`r`n`r`n`r`n"
}


