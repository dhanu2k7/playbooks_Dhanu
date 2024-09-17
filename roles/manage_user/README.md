# Manage SL1 user, groups and permissions

## Synopsis

This role manages (ie. creates and removes) SL1 user, adds it to relevant groups and sets permissions as needed by ScienceLogic monitoring solution.
It works on windows,linux and unix where sudo is supported.
<!-- [//]: # Inventories can mix windows, linux and unix hosts as long as you provide relevant informations.
[//]: # However, this requires the association of custom credentials and inventory groups. -->

## Variables

*IMPORTANT NOTE:* In some scenarios, responsabilities can be shared between the customer and our company. For example, the customer can delegate active directory management and keep management of servers, and vice-versa.  
SL1 needs an account, needs this account to be part of groups and needs some wmi/powershell permissions.  
Put together, this means that the creation of the user might have to be separated from the other actions.  

For this purpose, 2 variables were created:

* sl1_manage_user: to manage user existence.
* sl1_manage_permissions: to manage groups membership and permissions.

Of course, this only makes sense when actions can be separated, ie when using an ldap server or an active directory.  
Otherwise, sl1_manage_permissions is simply and silently ignored. For example, when user is local, groups and permissions will be set when sl1_manage_user is true, independently of sl1_manage_permissions

The variables are prefixed with "sl1_", following ansible best practices, to avoid collision that could occur if other roles are added to a playbook.

| Parameter                        | Type    | default value | Comments                                                                       |
|----------------------------------|---------|---------------|--------------------------------------------------------------------------------|
| sl1_account_name                 | string  |sl1 | name of the account to manage                                                |
| sl1_account_password             | string  || password of the account to manage                                                             |
| sl1_account_location             | string  |ad|  where the account resides.</br>**ad**: active directory   </br>**local**: on monitored machines |
| sl1_account_state                | string  |present|When absent, removes the user account if it exists. </br>When present, creates or updates the user account.  |
| sl1_account_admin                | boolean |false|To set the account as admin.</br>**You don't want to do that.** |
| sl1_account_path                 | string  |omitted| For activ directory, Organizational unit where the account should exist in. |
| sl1_permissions_location         | string  |local| Where the groups membership and permissions should be defined.</br>**ad**: active directory</br>**local**: on monitored machines.</br></br>NOTE: This is **only** taken into account when sl1_account_location is **ad**.|
| sl1_manage_user                  | boolean |true | If the user presence should be managed by the playbook. If false, sl1_account_state has no effect.  |
| sl1_manage_permissions           | boolean |true | if the permissions and groups membership of sl1 user should be managed by the playbook.</br></br>NOTE: This is **only** taken into account when sl1_account_location is **ad**|
| sl1_password_lock                | boolean |true | If the account should be locked </br></br>NOTE: Only on UNIX/Linux|
| sl1_visudo_template              | string  |/etc/sudoers.d/154_SCIENCELOGICL_RMIS_GLB | name of the sudo file containing the few rules needed</br></br>NOTE: Only on UNIX/Linux|
| sl1_account_update_password      | boolean |true| If the password should be updated when the playbook is re-run.</br></br>NOTE: Only on UNIX/Linux |
| sl1_account_expires              | float   |-1| Expiry time for the user in epoch. Expiry time can be removed by specifying a negative value.</br></br>NOTE: Only on UNIX/Linux|
| sl1_account_password_expires_max | string  |omitted| days before the password expires</br></br>NOTE: Only on UNIX/Linux |
| sl1_public_key                   | string  || Public key that should be added to user SL1 </br></br>NOTE: Only on UNIX/Linux |

## Results from execution

The RC 0 is not propagated to the Dashboard, only returned in standard variable returncode because the role is considered a building block.  
Success of the job the for Dashboard has to be reported by the main playbook.  
The role only propagates errors to Dashboard.  
| Return Code Group | Return Code | Comments
|----------------|-----------------|--------
| misconfiguration | 3004 | Error while creating user and groups |
| misconfiguration | 3005 | Error while creating sudo rules |
| misconfiguration | 3008 | Could not find a server to manage user or groups in Activ Directory |

## Procedure

The purpose of this role is to:

* Manage an account dedicated to SL1 usage.</br>On windows, it can be a normal user or an admin.
* Ensure the account is in the right groups and has needed permissions, on windows.
* Create appropriate sudo rules, on linux/UNIX.

## Support

For any problem or error encountered using the playbook, please open an issue in the issue section of this repository.

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
6. check **Update Revision On Launch:**
7. **SCM Branch:** main
8. All other fields can be left blank.

### Create a credential on windows

Creating an ID for Windows is specific and therefore worth mentioning here because when connecting to windows, the account does not get its full rights and **does need** to become itself.
For linux/UNIX, there is nothing particular.

1. **Name:** sl1_user (for example)
2. **Organization:** <org_code>
3. **Credential Type:** Machine
4. **Username:** the admin account to connect as
5. **Password:** Password of the admin account
6. **Privilege escalation method:** runas
7. **Privilege escalation username:** the same as "Username"
8. All other fields can be left blank.

### Job Template Setup

Once your project is connected please create a new Job Template.
Fill out the new Job template with the information below.

1. **Name:** <org_code>_jobtemplate_manage_user
2. **Job Type:** run
3. **Inventory:** the inventory that includes the server you want the playbook to act on
4. **Project:** <org_code>_project_SL1_automation
5. **Playbook:** manage_user.yml
6. **Credentials:** <Ansible_Tower_Credentials><Git_Credentials><Machine_Credentials>
7. **Verbosity:** specify the verbosity for your run
8. **Extravars:** modify defaults variables

## Known problems and limitations

1. Adding user to groups in Active Directory is not supported yet.
2. LDAP management is not supported yet.
3. Only english installation are supported for the time being.

## Examples

### playbook

```yaml
---
- name: Socks connection
  hosts: localhost
  connection: local
  become: false
  any_errors_fatal: true
  vars:
    acc_id: "{{ blueid_shortcode }}"
    transaction_id: "{{ tower_job_id }}"
  roles:
    - ansible-role-event-socks-tunnel
  tags:
    - socks

- name: Manage sl1 monitoring user
  hosts: all
  become: false
  gather_facts: true
  roles:
    - manage_user
```

This playbook is available as manage_user.yml.

### To create an active directory user in a specific organizational unit

You would provide those extra vars

```yaml
sl1_account_name: sl1_user
sl1_account_password: s1_password
sl1_account_path: ou=monitoring,dc=domain,dc=local
```

### To create an AD user without managing groups

You would provide those extra vars:

```yaml
sl1_account_name: sl1_user
sl1_account_password: s1_password
sl1_manage_permissions: false
```

### To manage groups and permissions only (user must already exists)

You would provide those extra vars:

```yaml
sl1_account_name: sl1_user
sl1_account_password: s1_password
sl1_manage_user: false
```

### To create unix user

You would provide those extra vars:

```yaml
sl1_account_name: sl1_user
sl1_account_password: s1_password
sl1_public_key: ssh-rsa .... xxx@yyy
```

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
