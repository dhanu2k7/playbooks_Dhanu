# config_secure_winrm

## Synopsis

This role configures the use of Windows Remote Management (WinRM) to ensure it's secured over HTTPS. It achieves this by performing the following tasks:

- Generating an SSL certificate for secure communications.
- Authorizing secure connections to enhance data integrity during remote sessions.
- Adjusting various WinRM settings to enhance its security posture.
- Opening port 5986 on the firewall, corresponding to WinRM over HTTPS.

## Variables

| Parameter   | Type | Default |Comments
|----------------|-----------------|--------|--------
| winrm_create_certificate | Boolean | true | Put "true" if you want to generate self-signed cert.
| winrm_allow_remote_access_value | Boolean | true | Enable Remote acces
| winrm_allow_remote_shell_access_value | Boolean | true | Enable remote shell acces
| winrm_certificate_service_value | Boolean | true | Enable Certificate-Authentication on the Server - service auth
| winrm_certificate_client_value | Boolean | true | Enable Certificate-Authentication on the Server - client auth
| winrm_max_connections_value | string | 300 | Set the max Winrm request at one time
| winrm_idle_timeout_value | string | 7200000 | To reduce the IdleTimeout and have Windows shut down idle WinRM processes after a shorter time period
| winrm_path_certificate_key_in_localhost | string | /tmp/certificate.key | The path where the certificate key is stored on the local host.
| winrm_path_certificate_in_localhost | string | /tmp/certificate.crt | The path where the certificate is stored on the local host.
| winrm_path_certificate_in_windows_server | string | C:\certificate.crt | The path where the certificate is stored on the Windows server.

## Results from execution

The return code RC 0 is not propagated to the Dashboard; it's only returned in the standard variable returncode. The success of the job for the Dashboard has to be reported by the main playbook. This role only propagates errors to the Dashboard.
| Return Code Group | Return Code | Comments
|----------------|-----------------|--------|
| misconfiguration | 3001 | the Self-signed Certificate cannot be created, check if there an existing self-signed certificate before create another
| misconfiguration | 3002 | one or more than parameter of configuration of winrm is invalid
| misconfiguration | 3003 | Failed to configure the firewall for WinRM

## Procedure

This role is specifically tailored for configuring and securing Windows Remote Management (WinRM). When executed, the role goes through the following processes:

Generate a Self-signed Certificate:

- Creates a private key (RSA, 4096 bits).
- Produces a simple self-signed certificate.
- Copies the certificate to the Windows machine.
- Imports the certificate on the Windows machine.
- Deletes the certificate files from the local machine.

Configure WinRM Settings:

- Sets the allowance for remote access.
- Enables remote shell access.
- Configures Certificate Authentication both for service and client-side.
- Adjusts the maximum number of WinRM requests that can be processed simultaneously.
- Modifies the IdleTimeout for WinRM processes.
- Adjust Firewall Settings:

Opens a firewall rule specifically for secure WinRM on port 5986.
For ensuring encrypted communications over WinRM, the service will utilize port "HTTPS = 5986"

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

1. **Name:** <org_code>_jobtemplate_config_secure_winrm
2. **Job Type:** run
3. **Inventory:** the inventory that include your server where you want to run the playbook
4. **Project:** <org_code>_project_SL1_automation
5. **Playbook:** config_secure_winrm.yml
6. **Credentials:** <Ansible_Tower_Credentials><Git_Credentials><Machine_Credentials>
7. **Verbosity:** specify the verbosity for your run
8. **Extravars:** modify defaults variables

## Known problems and limitations

```yaml

In case you have a problem executing this role, please [Create New Issue](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/issues) in GitHub with the following basic information:



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

  roles:
    - role: config_secure_winrm

```

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
