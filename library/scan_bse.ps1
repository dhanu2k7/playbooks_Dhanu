##!powershell
#Requires -Module Ansible.ModuleUtils.Legacy
$ErrorActionPreference = "Continue"
$params = Parse-Args $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "names" -default $false
$na = $names
$na
$names
foreach($nam in na)
{
powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass 'D:\Stock Market\$nam'

}