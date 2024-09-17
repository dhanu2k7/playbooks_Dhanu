# Create_config_ssh_user

## Synopsis

This role will help you creating the user and group and add ssh key also for sudo configuration

## Variables

| Parameter  | Type | Comments |
|----------------|-----------------|--------
group_name | string  | the group name of ssh user
user_name | string | choose the username
user_password | string | password of ssh user
pwd_lock | Boolean | Lock the password (usermod -L, usermod -U, pw lock).Implementation differs by platform. This option does not always mean the user cannot login using other methods.This option does not disable the user, only lock the password.This must be set to False in order to unlock a currently locked password. The absence of this parameter will not unlock a password.
pwd_expire_max | integer | Maximum number of days between password change.
public_key| string | the ssh public key to be added in the server
visudo_config | string | the path of the visudo configuration example : /etc/sudoers.d/myvisudo_config_file

## Results from execution

The RC 0 is not propagated to the Dashboard, only returned in standard variable returncode,
because the create_config_ssh_user role is considered as building block.
Success of the job the for Dashboard has to be reported by the main playbook.
create_config_ssh_user role propagates to Dashboard only errors.

| Return Code Group | Return Code | Comments
|----------------|-----------------|--------
| misconfiguration | 3004 | Error while creating user or group, missing sudo privileges
| misconfiguration | 3005 | Error while creating visudo configuration from jinja template

## Procedure

The purpose of this role is to:

* Create group and ssh user
* Set up multiple authorized keys
* Change permission at ssh folder
* Create visudo config: a jinja file is available in templates

## Support

For any problem or error encountered using the playbook please open an issue in the issue section of this repository.

Team Support : <https://kyndryl.sharepoint.com/sites/KYNDRYLMARKETFRANCETRANSFORMATIONINNOVATIONTEAM/SitePages/FR-DEVOPS-TEAM.aspx>

Team Contact: FrenchDevOpsTeam@kyndryl.com

## Deployment

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

1. **Name:** <org_code>_jobtemplate_create_config_ssh_user
2. **Job Type:** run
3. **Inventory:** the inventory that include your server where you want to run the playbook
4. **Project:** <org_code>_project_SL1_automation
5. **Playbook:** create_config_ssh_user.yml
6. **Credentials:** <Ansible_Tower_Credentials><Git_Credentials><Machine_Credentials>
7. **Verbosity:** specify the verbosity for your run
8. **Extravars:** described bellow

```yaml

  group_name: "user_group"
  user_name: "user_username"
  pwd_lock: "yes"
  pwd_expire_max: -1
  visudo_config: "/etc/sudoers.d/154_SCIENCELOGICL_RMIS_GLB"

```

Add survey for the job template for create config ssh user:

```yaml
user_password ### Password of user, use the password type when you want to setup this variable in the survey
public_key ### the public key to be inserted in the authorized_keys in the format "ssh-rsa encryptedkey email", use the password type when you want to setup this variable in the survey

```

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

- hosts: servers
  become: yes
  roles:
    - role: create_config_ssh_user
      vars:
        group_name: sl1_group
        user_name: sl1_user
        user_password: P@ssword
        pwd_lock: "yes"
        pwd_expire_max: -1
        ssh_key_filename: sl1_key.pem
        visudo_config: /etc/sudoers.d/154_SCIENCELOGICL_RMIS_GLB

```

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
