# Create_ad_win_user_admin

## Synopsis

This Ansible playbook creates a user in Active Directory and adds the user to the AD "Domains Admin" group. It also sets the user's language to en-US.

## Prerequisite

If you want to create ScienceLogic credential , these prereqesite must be respected :

* Ports 53 (DNS) , 88 (Kerberos ), 5985 (winRM HTTP), 5986 (winRM HTTPS) must be open
* Listener HTTP and HTTPS in winRM must be open
* winRM must be configure

## Variables

| Parameter        | Type | Comments
|----------------|-----------------|--------
| ad_group_name | string | The name of the AD Administrators group.
| username | string | Name of the user to create, remove or modify.
| create_ad_user | Boolean | true or false if you already have a user and just want to configure it
| pwd | string | Optionally set the user’s password to this (plain text) value. To enable an account - enabled - a password must already be configured on the account, or you must provide a password here.

## Results from execution

The RC 0 is not propagated to the Dashboard, only returned in standard variable returncode, because the CONFIG_WINRM role is considered as building block. Success of the job the for Dashboard has to be reported by the main playbook. CONFIG_WINRM role propagates to Dashboard only errors.
| Return Code Group | Return Code | Comments
|----------------|-----------------|--------|
| misconfiguration | 3007 | Error while creating and adding user to domain admin group

## Support

For any problem or error encountered using the playbook please open an issue in the issue section of this repository.

Team Support : <https://kyndryl.sharepoint.com/sites/KYNDRYLMARKETFRANCETRANSFORMATIONINNOVATIONTEAM/SitePages/FR-DEVOPS-TEAM.aspx>

Team Contact: FrenchDevOpsTeam@kyndryl.com

### Project Setup

Create a new project in your Ansible Tower.
Fill out the new project template with the information below.

1. **Name:** <org_code>_project_SL1_automation
2. **Organization:** <org_code>
3. **SCM Type:** Git
4. **SCM URL:** <https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation.git>
5. **SCM Credential:** <Github_Token_Credentials>
6. **Update Revision On Launch:** check it
7. **SCM Branch:** main
8. All other fields can be left blank.

### Job Template Setup

Once your project is connected please create a new Job Template.
Fill out the new Job template with the information below.

1. **Name:** <org_code>_jobtemplate_create_win_credentials
2. **Job Type:** run
3. **Inventory:** the inventory that include your server where you want to run the playbook
4. **Project:** <org_code>_project_SL1_automation
5. **Playbook:** create_win_credentials.yml
6. **Credentials:** <Ansible_Tower_Credentials><Git_Credentials><Machine_Credentials>
7. **Verbosity:** specify the verbosity for your run
8. **Extravars:** modify defaults variables

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

## Prerequisites

Standard Ansible prerequisites (Python/PowerShell on target machines)

## Examples

```yaml

- hosts: all
  become: true
  become_method: runas
  become_user: "{{ansible_user}}"
  roles:
    - role: create_ad_win_user_admin
      vars:
        ad_grp_name: aActive Directory Domain Admins group
        username: sl1_user
        pwd: password
        create_ad_user: "true"

```

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
