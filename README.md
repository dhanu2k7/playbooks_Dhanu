# ansible_collection_sl1_automation

## Synopsis

The purpose of this asset is to automate a process which requires to call a combination of ansible roles, in order to automate SL1 configuration steps.

## Variables

Please check the corresponding sub READMEs for each role

* This collection comprises of roles that enable you to create and configure the Windows Server user account.
* It also offers you a choice to configure Windows Remote Management.
* Within your SL1 appliance , you can  install vmware-tools via apt for ubuntu or tar package for centos, configure the NTP server on Linux OS and synchronize NTP client with chrony.

## Results from execution

Please check the corresponding sub READMEs for each role.

## Procedure

Please check the corresponding sub READMEs for each role.
The automation include diffferent os (centos/Redhat)
For ansible tower:

* Create project
* Create inventory
* Specify Credentials
* Create Job template

| Roles | Description
|----------|-------------
| [add_user_mysql](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/add_device_on_group/README.md) | Add user to MySQL server and give the user the privileges SELECT and EXECUTE for all databases in the server |
| [add_user_postgresql](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/add_user_postgresql/README.md) |  Add user to postgresql server and give the user the privileges SELECT and EXECUTE on a specified database |
| [add_user_mssql](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/add_user_mssql/README.md) |  Add user to mssql server and give the user the privileges SELECT and EXECUTE on a specified database |
| [config_secure_winrm](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/config_secure_winrm/README.md) | Configure Windows Remote Management |
| [create_config_ssh_user](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/create_config_ssh_user/README.md) | DEPRECATED in favor of manage_user. Create the user, group and add ssh key for sudo configuration |
| [create_non_admin_user](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/create_non_admin_user/README.md) | DEPRECATED in favor of manage_user. Create a non-administrator user and configure WMI Permissions |
| [identify_ps_version](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/identify_ps_version/README.md) | Identify the full version of PowerShell of the asset executed as hosts |
| [manage_user](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/manage_user/README.md) | Manage (create/remove) SL1 user |
| [remove_ssh_user](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/blob/main/roles/remove_ssh_user/README.md) | DEPRECATED in favor of manage_user. Remove user, group and visudo configuration |

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
6. **Update Revision On Launch:** Do not check it.
7. **SCM Branch:** main
8. All other fields can be left blank.

### Job Template Setup

Once your project is connected please create a new Job Template.
Fill out the new Job template with the information below.

1. **Name:** <org_code>_jobtemplate_playbook_name
2. **Job Type:** run
3. **Inventory:** the inventory that include your server where you want to run the playbook
4. **Project:** <org_code>_project_SL1_automation
5. **Playbook:** <playbook_name>.yml
6. **Credentials:** <Ansible_Tower_Credentials><Git_Credentials><Machine_Credentials><Client_Proxy_Credentials>
7. **Execution Environment** at least ansible_kyndryl_2.13
8. **Verbosity:** specify the verbosity for your run

## Known problems and limitations

No known problems or limitations.  

In case you have an error or problem of proxy please check your template credentials and be sure that the jumphost credential is already added.

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

* _Standard Ansible prerequisites (Python/PowerShell on target machines)_

## Examples

```yaml

---
- hosts: all
  roles:
    - role: set_and_launch_discovery
      vars:
        sl1_api_url: http://192.168.1.11
        sl1_api_login: em7admin
        sl1_api_password: em7admin
        new_ips: ['192.168.1.4-192.168.1.6','192.156.34.34','192.168.1.0/26','192.168.1.64/27','192.148.1.29-192.148.1.56']
        discovery_name: disco-linux

```

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
