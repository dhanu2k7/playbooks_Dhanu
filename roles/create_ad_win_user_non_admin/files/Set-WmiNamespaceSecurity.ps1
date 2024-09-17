 [CmdletBinding()]
Param (
    [parameter(Mandatory=$false,Position=0)]
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
    } catch {
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


# IsRunByAdmin: Ensure the user executing the script has Administrator rights - this is not requiring the account used in the configuration
# to be in the Administrator group
Function IsRunByAdmin()
{
    $bAdmin = $false
    Log "IsRunByAdmin: Checking if user running this utility in an Administrator context ..."
    try {
        $bAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    } catch {
        Log "IsRunByAdmin: Exception caught while retrieving current user role - detail - $_"
    }

    if ($bAdmin -eq $false) {
        if ($silent) {
            Log "IsRunByAdmin: Error - this script is not being run by a member of the Administrator's group on this computer.  It must be run under an administrative account to be successful."
        } else {
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


Function CreateAclMask($permissions) {
    $ENABLE = 1
    $METHOD_EXECUTE = 2
    $FULL_WRITE_REP   = 4
    $PARTIAL_WRITE_REP = 8
    $WRITE_PROVIDER   = 0x10
    $REMOTE_ACCESS    = 0x20
    $RIGHT_SUBSCRIBE = 0x40
    $RIGHT_PUBLISH      = 0x80
    $READ_CONTROL = 0x20000
    $WRITE_DAC = 0x40000

    $RIGHT_FLAGS = $ENABLE, $METHOD_EXECUTE, $FULL_WRITE_REP, $PARTIAL_WRITE_REP, $WRITE_PROVIDER, `
        $REMOTE_ACCESS, $READ_CONTROL, $WRITE_DAC
    $RIGHT_STRINGS = "Enable","MethodExecute","FullWrite","PartialWrite", "ProviderWrite","RemoteAccess","ReadSecurity","WriteSecurity"
    $permissionTable = @{}
    for ($i = 0; $i -lt $RIGHT_FLAGS.Length; $i++) {
        $permissionTable.Add($RIGHT_STRINGS[$i].ToLower(), $RIGHT_FLAGS[$i])
    }
    $accessMask = 0
    foreach ($permission in $permissions) {
        if (-not $permissionTable.ContainsKey($permission.ToLower())) {
            throw "Invalid value for a permission: `"$permission`"`nValid permissions: $($permissionTable.Keys)"
        }
        $accessMask += $permissionTable[$permission.ToLower()]
    }
    $accessMask
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

# CollectCurrentConfig: take inventory of current configuration settings that will be modified by this utility, save them to file, and save them for use throughout script
Function CollectCurrentConfig()
{
    # Get OS and PowerShell info to save to the logging
    Log "CollectCurrentConfig: Getting PowerShell and Windows version info ..."
    try {
        $ps_ver_string = $PSVersionTable.PSVersion.ToString()
        $script:major_ps_ver = $PSVersionTable.PSVersion.Major
        Log "CollectCurrentConfig: PowerShell version - $ps_ver_string"
   } catch {
       # Assuming that verison 1.x of PowerShell is installed, as the lack of presence of $PSVersionTable should be
       # the only reason an exception should be thrown using that cmdlet, as it was introduced in v2.0
       Log "CollectCurrentConfig: Error occurred while fetching version of PowerShell - detail - $_"
       $script:major_ps_ver = 1
   }

   try {
        $os_ver = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName).ProductName
        Log "CollectCurrentConfig: Windows information - $os_ver"
    } catch {
        Log "CollectCurrentConfig: Error occurred while fetching version of operating system - detail - $_"

    }


}  # end CollectCurrentConfig

# AddWinRMRights - give read/execute rights for WinRM to the user account specified
# Equivalent of running winrm configsddl default
Function AddWinRMRights()
{
    Log "AddWinRMRights: Enter"
    $bSuccess = $false

    try {
        # Get SID of user in object form
        Log "AddWinRMRights: Getting SID object for user account ..."
        $acct_sid = GetAccountSID $script:account $false

        # Account access needs to be added to WinRM root sddl
        $sddl = (Get-Item -Path WSMan:\Localhost\Service\RootSDDL).Value
        Log "AddWinRMRights: SDDL for root of WinRM retrieved = `"$sddl`""

        # Convert the SDDL string to a SecurityDescriptor object
        Log "AddWinRMRights: Instantiate new security descriptor object for SDDL retrieved ..."
        $sd = New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList $false, $false, $sddl

        # Update the DACL on the SecurityDescriptor object for this account and its permission
        Log "AddWinRMRights: Adding new DACL for this user account to the existing security descriptor"
        $sd.DiscretionaryAcl.AddAccess([System.Security.AccessControl.AccessControlType]::Allow,
                                                               $acct_sid,
                                                              ($GENERIC_READ -bor $GENERIC_EXECUTE),
                                                              [System.Security.AccessControl.InheritanceFlags]::None,
                                                              [System.Security.AccessControl.PropagationFlags]::None)

        # Get the SDDL string from the changed SecurityDescriptor object
        $new_sddl = $sd.GetSddlForm([System.Security.AccessControl.AccessControlSections]::All)

        # Apply the new SDDL to the WinRM listener
        Log "AddWinRMRights: Setting the SDDL with the updated rights for the SL1 user"
        Set-Item -Path WSMan:\localhost\Service\RootSDDL -Value $new_sddl -Force | Out-Null
        $bSuccess = $true
    } catch {
        Log "AddWinRMRights: Exception caught while setting updated SDDL for SL1 user account - detail - $_"
    }

    Log "AddWinRMRights: Exit"
}

# SetWMIPermissions
Function SetWMIPermissions()
{
    Log "SetWMIPermissions: Enter"
    $inherit = $true
    $localhost = "."
    $try_alternate = $false
    $permissions = @("Enable","RemoteAccess","MethodExecute")

    # Specify the namespace to set permissions
    $invoke_params = @{Namespace=$script:wmi_namespace_root;Path="__SystemSecurity=@"}

    try {
        # If user account to be configured is already in Administrators group, this step is not necessary.
        if (IsAccountInAdminGroup($script:account) -eq $true) {
            Log "SetWMIPermissions: User `"$user`" is already in the local Administrators group, so no need to add this user."
            return $true
        }

        Log "SetWMIPermissions: Calling Invoke-WmiMethod -Name GetSecurityDescriptor with parameters: "
        foreach($invokeparam in $invoke_params.keys) {
            Log "SetWMIPermissions:     `"$($invokeparam)`" => `"$($invoke_params.$invokeparam)`""
        }

        $output = Invoke-WmiMethod $invoke_params -Name GetSecurityDescriptor
        if ($error.count -gt 0) {
            $error_string = $error[0].ToString()
            Log "SetWMIPermissions: After Invoke-WmiMethod for GetSecurityDescriptor(), most recent error => $error_string"
        }
        $error.clear()

        if (($output -eq $null)) {
            Log "SetWMIPermissions: GetSecurityDescriptor() did not return the user SID, so trying alternate method of retrieving SID."
            $try_alternate = $true
        } else {
            $rc = $output.ReturnValue
            Log "SetWMIPermissions: GetSecurityDescriptor() returned ret value $rc"
            if ($rc -ne 0) {
                Log "SetWMIPermissions: GetSecurityDescriptor() call failed, returning $($output.ReturnValue), so trying alternate method of retrieving SID."
                $try_alternate = $true
            }
        }
    } catch {
        Log "SetWMIPermissions: Exception caught while retrieving SID for WMI namespace `"$script:wmi_namespace_root`" - detail - $_"
        $try_alternate = $true
    }

    $security_descriptor = $null
    if ($try_alternate -eq $true) {
        # In some envs, invoke-wmimethod does not behave well, so use this alternative to get the descriptor for this namespace
        Log "SetWMIPermissions: Using an alternate means to find the SID of the `"$script:wmi_namespace_root`" namespace"
        $binarySD = @($null)
        $result = $(Get-WMIObject -Namespace "root" -Class __SystemSecurity).PsBase.InvokeMethod("GetSD", $binarySD)
        $converter = New-Object system.management.ManagementClass Win32_SecurityDescriptorHelper
        $sddl_output = $converter.BinarySDToSDDL($binarySD[0])
        Log "SetWMIPermissions: Alternate method found SID of this namespace as `"$($sddl_output.SDDL)`""
        $security_descriptor = ($converter.BinarySDToWin32SD($binarySD[0])).Descriptor
        if ($result -ne 0) {
            Log "SetWMIPermissions: Error - the attempt to convert the byte format security descriptor to a Win32 instance failed with rc = $result"
        } else {
            Log "SetWMIPermissions: Converted byte-format security descriptor to Win32 instance successfully."
        }

    } else {
        # We appear to have gotten the descriptor - assign it for use
        $security_descriptor = $output.Descriptor
    }

    Log "SetWMIPermissions: Looking at user account `"$script:account`" in relation to computer `"$script:localhost_name`""
    if ($script:account.Contains('\')) {
        $domainaccount = $script:account.Split('\')
        $domain = $domainaccount[0]
        if (($domain -eq ".") -or ($domain -eq "BUILTIN")) {
            $domain = $script:localhost_name
        }
        $accountname = $domainaccount[1]
    } elseif ($script:account.Contains('@')) {
        $domainaccount = $script:account.Split('@')
        $domain = $domainaccount[1].Split('.')[0]
        $accountname = $domainaccount[0]
    } else {
        $domain = $script:localhost_name
        $accountname = $script:account
    }

    Log "SetWMIPermissions: Looking for account with domain `"$domain`" and user `"$accountname`" in Win32_Account"
    $win32account = $null
    $getparams = @{Class="Win32_Account";Filter="Domain='$domain' and Name='$accountname'"}
    $win32account = Get-WmiObject @getparams
    if ($win32account -eq $null) {
        Log "SetWMIPermissions: Warning - Windows account specified was *not* found in a lookup in the Win32_Account WMI class, so we will use SID collected already to set in trustee object"
    }

    # Add permissions to WMI security for the user account  specified
    $OBJECT_INHERIT_ACE_FLAG = 0x1
    $CONTAINER_INHERIT_ACE_FLAG = 0x2
    $accessMask = CreateAclMask($permissions)
    Log "SetWMIPermissions: Creating Win32_ACE instance ..."
    $ace = (New-Object System.Management.ManagementClass("win32_Ace")).CreateInstance()
    $ace.AccessMask = $accessMask
    if ($inherit -eq $true) {
        # Failures occur on some OS versions when object inherit flag was used, and it is not typically
        # necessary for setting inheritance of permissions on namespaces
        if ($script:set_wmi_inherit_obj -eq $true) {
            $ace.AceFlags = $OBJECT_INHERIT_ACE_FLAG + $CONTAINER_INHERIT_ACE_FLAG
        } else {
            $ace.AceFlags = $CONTAINER_INHERIT_ACE_FLAG
        }
    } else {
        $ace.AceFlags = 0
    }

    $trustee = (New-Object System.Management.ManagementClass("win32_Trustee")).CreateInstance()
    if ($win32account -eq $null) {
        Log "SetWMIPermissions: Using SID collector at start of script execution."
        $trustee.SidString = $script:account_sid
    } else {
        $trustee.SidString = $win32account.Sid
    }
    $ace.Trustee = $trustee
    $ACCESS_ALLOWED_ACE_TYPE = 0x0
    $ACCESS_DENIED_ACE_TYPE = 0x1
    $ace.AceType = $ACCESS_ALLOWED_ACE_TYPE
    $security_descriptor.DACL += $ace.psobject.immediateBaseObject
    try {
        $setparams = @{Name="SetSecurityDescriptor";ArgumentList = $security_descriptor.psobject.immediateBaseObject} + $invoke_params
        Log "SetWMIPermissions: Calling SetSecurityDescriptor() to commit WMI permission changes for the account."
        $output = Invoke-WmiMethod @setparams -ErrorAction SilentlyContinue
        if ($error.count -gt 0) {
            $error_string = $error[0].ToString()
            Log "SetWMIPermissions: After Invoke-WmiMethod for SetSecurityDescriptor, most recent error => $error_string"
        }
        $error.clear()

        if (($output -eq $null)) {
            Log "SetWMIPermissions: SetSecurityDescriptor() call failed, returning a NULL object."
        } else {
            $rc = $output.ReturnValue
            Log "SetWMIPermissions: SetSecurityDescriptor() returned ret value $rc"
            if ($rc -ne 0) {
                Log "SetWMIPermissions: SetSecurityDescriptor() call failed, returning $($output.ReturnValue), so WMI permissions were not setup properly!"
                $try_alternate = $true
            }
        }
    } catch {
        Log "SetWMIPermissions: Error - Exception caught while setting security descriptor for user on the WMI namespace `"$script:wmi_namespace_root`" - detail - $_"
        $try_alternate = $true
    }

    Log "SetWMIPermissions: Exit"
    return $true
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
    $ret_code = $false

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

    # Retrieve current configuration settings to save
    Log "Main: Retrieving current security settings to save for reversion, if necessary"
    $ret_code = CollectCurrentConfig

    # Ensure PowerShell version desired, from command-line or by default, is installed and exit if it is not
    Log "Main: Checking Windows PowerShell version present against version $ps_version (ps_version command-line argument or default value of 1)"
    $script:major_ps_ver = $script:major_ps_ver / 1   # Ensure this is an integer before using in comparison - PS ensures this after division
    if ($script:major_ps_ver -ge $ps_version) {
        Log "Main: Windows PowerShell is version $script:major_ps_ver, and only $ps_version is requested as the minimum for configuration, so continuing."
    } else {
        Log "Main: Error - Windows PowerShell is version $script:major_ps_ver, less than the required version of $ps_version, so exiting!"
        Write-Host "Error - Windows PowerShell is version $script:major_ps_ver, less than the required version of $ps_version, so exiting!"
        exit
    }
    AddWinRMRights
    SetWMIPermissions

    # Write error and warning summary to end of std output
    # and log file
    if ($script:error_summary  -ne $null) {
        Log "****************************************************************************`n`n"
        Log "List of errors and warnings encountered during execution: `n"
        Log "$($script:error_summary)`n`n"
        Log "****************************************************************************`n`n"
    }

    Log "Main: Configuration has completed. Exiting ....`r`n`r`n`r`n`r`n`r`n`r`n`r`n"

} catch {
    Log "Main: Exception caught while executing - detail - $_ `r`n`r`n`r`n`r`n`r`n`r`n`r`n"
}


