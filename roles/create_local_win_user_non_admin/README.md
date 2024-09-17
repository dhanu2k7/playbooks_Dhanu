# Create_no_admin_user and add to local group

## Synopsis

This playbook creates a user no admin in the local and grants them the necessary minimum rights on the servers to monitor them with ScienceLogic.

## Prerequesite

If you want to create ScienceLogic credential , these prereqesite must be respected :

* Ports 53 (DNS)
* 88 (Kerberos )
* ICMPv4
* SNMP
* winRM must be configure

## Variables

| Parameter                  | Type    | Comments                                                                                      |
|----------------------------|---------|-----------------------------------------------------------------------------------------------|
| username                   | string  | account username to create                                                                    |
| pwd                        | string  | password of user account                                                                      |
| create_local_no_admin_user | Boolean | true or false if you already have a user and just want to configure it                        |
| dest_path                  | string  | used to define the location where the PowerShell script for configuring WMI will be copied to |

## Results from execution

The RC 0 is not propagated to the Dashboard, only returned in standard variable returncode,
because the create_non_admin_user role is considered as building block.
Success of the job the for Dashboard has to be reported by the main playbook.
create_ad_win_user_non_admin role propagates to Dashboard only errors.
| Return Code Group | Return Code | Comments
|----------------|-----------------|--------
| misconfiguration | 3007 | Error while creating and adding user no admin to local group

## Procedure

The purpose of this role is to:

* Create a non administrator account
* Configuration of winrm permissions
* Add user to local group
* Create a new Https Listener
* Get winrm listenner config

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

1. **Name:** <org_code>_jobtemplate_create_non_admin_user
2. **Job Type:** run
3. **Inventory:** the inventory that include your server where you want to run the playbook
4. **Project:** <org_code>_project_SL1_automation
5. **Playbook:** create_non_admin_user.yml
6. **Credentials:** <Ansible_Tower_Credentials><Git_Credentials><Machine_Credentials>
7. **Verbosity:** specify the verbosity for your run
8. **Extravars:** modify defaults variables

## Known problems and limitations

If you encounter any issues related to the Ansible variable `ansible_user`, please follow the instructions below to resolve them.
In order to address any errors associated with the `ansible_user` variable, please make sure to add the following code snippet to the relevant role in tasks/main.yml:

```yaml
    - name: setfact
      set_fact:
        machine_user: "{{ ansible_user }}"
```

And the variable becom_user: "{{machine_user}} at the task level, like this :

```yaml

      become_user: "{{machine_user}}"
```

## Prerequisites

Standard Ansible prerequisites (Python/PowerShell on target machines)

## Examples

```yaml

---
- name: Socks connection
  hosts: localhost
  connection: local
  any_errors_fatal: true
  vars:
    acc_id: "{{ blueid_shortcode }}"
    transaction_id: "{{ tower_job_id }}"
  roles:
    - role: ansible-role-event-socks-tunnel
  tags:
    - socks

- hosts: all
  become: true
  become_method: runas
  become_user: "{{ ansible_user }}"

  roles:
    - role: create_local_win_user_non_admin
      vars:
        username: my_user
        pwd: my_password
        create_local_non_admin_user: "true" # or false if you already have a user and just want to configure it
        dest_path: "C:\\Users"
```

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
