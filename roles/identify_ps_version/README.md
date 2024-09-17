# identify_ps_version

## Synopsis

Ansible role to identify the version of PowerShell for windows assets, if it is a non-Windows asset it will be empty value.

## Variables

| Parameter   | Type  |Comments
|----------------|-----------------|--------

## Results from execution

If result 5030 so there is an error in the execution of the role.

| Return Code Group | Return Code | Comments
|----------------|-----------------|--------|
| framework_playbook | 5030 | Failed to identify the PS version

## Procedure

The purpose of this role is to:
if it is a Windows asset:

* execute 2 PowerShell commands to get the full version.
* select the adequat return to the PowerShell version.
* if both commands return a problem, the role give a comment in the version "unidentified PowerShell version".

if it is a non-Windows asset:

* psversion variable will be empty.

## Support

For any problem or error encountered using the playbook please open an issue in the issue section of this repository.

Team Support : <https://kyndryl.sharepoint.com/sites/KYNDRYLMARKETFRANCETRANSFORMATIONINNOVATIONTEAM/SitePages/FR-DEVOPS-TEAM.aspx>

Team Contact: FrenchDevOpsTeam@kyndryl.com

## Known problems and limitations

No known problems or limitations.  
In case you have a problem executing this role, please [Create New Issue](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/issues) in GitHub with the following basic information:

```yaml
Name:
Kyndryl e-mail:
Customer Account:
Office Hours with Timezone:
Role Name:
Problem Description:
(please include screenshots)
```

## Deployment

As mentionned in the Prerequisites:

* there is no dependencies in this ansible role, it is based on standard modules.

## Prerequisites

* _Standard Ansible prerequisites_

## Examples

```yaml
- hosts: servers
  become: true
  become_method: runas
  become_user: "{{ansible_user}}"
  roles:
    - role: identify_ps_version

```

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
