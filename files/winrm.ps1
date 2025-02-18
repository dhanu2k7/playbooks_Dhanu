$user = "dhanu"
$Certname = "$env:computername"
$Cert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $Certname
$pw = ConvertTo-SecureString -String "Pazzword" -Force -AsPlainText
$thumbprint = $Cert.Thumbprint
WinRM e winrm/config/listener
#winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname="$Certname"; CertificateThumbprint=$thumbprint}'
New-Item WSMan:\localhost\Listener -Address * -Transport HTTPS -HostName $Certname -CertificateThumbPrint $thumbprint
$port=5986
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=$port
net localgroup "Remote Management Users" /add $user
net localgroup "Event Log Readers" /add $user
Restart-Service WinRM
Restart-Service Winmgmt -Force

#Adding the below script should replace "winrm configSDDL default"
$GENERIC_READ = 0x80000000
$GENERIC_WRITE = 0x40000000
$GENERIC_EXECUTE = 0x20000000
$GENERIC_ALL = 0x10000000

# get SID of user/group to add

$user_sid = (New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $user).Translate([System.Security.Principal.SecurityIdentifier])

# get the existing SDDL of the WinRM listener
$sddl = (Get-Item -Path WSMan:\localhost\Service\RootSDDL).Value

# convert the SDDL string to a SecurityDescriptor object
$sd = New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList $false, $false, $sddl

# apply a new DACL to the SecurityDescriptor object
$sd.DiscretionaryAcl.AddAccess(
[System.Security.AccessControl.AccessControlType]::Allow,
$user_sid,
($GENERIC_READ -bor $GENERIC_EXECUTE),
[System.Security.AccessControl.InheritanceFlags]::None,
[System.Security.AccessControl.PropagationFlags]::None
)

# get the SDDL string from the changed SecurityDescriptor object
$new_sddl = $sd.GetSddlForm([System.Security.AccessControl.AccessControlSections]::All)

# apply the new SDDL to the WinRM listener
Set-Item -Path WSMan:\localhost\Service\RootSDDL -Value $new_sddl -Force```