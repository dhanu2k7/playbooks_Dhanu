# Manage database user for ScienceLogic discovery

## Synopsis

This Ansible role provides tasks to create a database user and grant permissions for three different database types: MySQL, MSSQL, and PostgreSQL.

## Prerequesites

If you want to create ScienceLogic database users on different database, these prerequisites must be respected :

- For Linux:
    - PostgreSQL: python3-psycopg2
    - MySQL: python3-PyMySQL
- For Windows:
    - MSSQL: PowerShell module SqlServerDsc, PowerShellGet >= 1.6.0 and PackageManagement >= 1.1.7. PowerShell package provider needed - NuGet >= 2.8.5.201.

***Important***: Run the playbook as a super user for automatic installation of these packages. If super user execution is not possible, manually install the prerequisites and set sl1_db_prerequisites_auto_install to false in your extra variable.

- If you are running the playbook for Linux, you can add the tag 'socks' on AAP because the socks tunnel is only necessary for Windows, and it might generate an error otherwise.

- If you are executing the playbook for Mysql or Postgres the host that is running your playbook should mandatory be a Linux and should contains Python version 3.x

- For Mysql and Postgres, you can run the playbook either in the Linux host that contains the DB or ideally in another Linux such as JumpHost.

- If you are executing the playbook for MSSQL the host that is running your playbook should be a Windows.

- For Mysql there's nothing additional to configure. Just keep in mind that in some cases for security purpose the user root cannot be used to created the new users from another machine.

- For Postgres, you cannot create a SL1 user if the host that is executing the playbook is not whitelisted in the config files of postgres, you will need to add a line in the file (pg_hba.config) you can find the file in the installation repo of your postgres database, the line should be like the image below :

![image](https://media.github.kyndryl.net/user/29037/files/188ddc35-e6be-4384-94bb-cc6f6eb8198f)

Or you can specify the exact user and the exact database :

![image](https://media.github.kyndryl.net/user/29037/files/15b55dd4-f8a2-4631-8b7a-e47dc7856be1)

- For MSSQL, the user will be created on each of the databases that you will specify and also in the Master and the Msdb. Create a SQL login and database user that will be mapped and granted the necessary permissions for discovery on sl1.

- For MSSQL, your instance must be in Mixed authentication mode.

- Make sure to inspect the firewall if you encounter any connectivity issues with your database.

## Variables

Variable | Default value | Mandatory | Comments
---- | :-----: | :---: | -------------------------
sl1_database_name (string) | "" | Yes | Put the database name that you want to create the user inside it.
sl1_database_host (string) | "" | Yes | Put the server database IP where you database is installed.
sl1_database_instance_name | "" | Yes | Put the instance name , only for mssql.
sl1_database_login_user (string) | "" | Yes | Put the database username to use to create the user.
sl1_database_login_password (string) | "" | Yes | Put the database password to use to create the user.
sl1_database_username (string) | "" | Yes | Put the SL1 database user name to create inside the database.
sl1_database_password (string) | "" | No | Needed only when sl1_database_login_account_type="sql". Put the SL1 database user password to be created inside the database.
sl1_database_type (string) | "" | Yes | Put the database type that you use, choice are : mysql, postgresql, mssql.
sl1_database_server_port (string) | "" | Yes | Put the SL1 database port.
sl1_db_prerequisites_auto_install (boolean) | true | Yes | Automatic installation of prerequisites.
sl1_database_login_account_type (string) | "sql" | No | sql: Create a sql login type (need sl1_database_password). windows: Create a Windows login type.

## Results from execution

| Return Code Group | Return Code | Comments
|----------------|-----------------|--------
misconfiguration | 3005 | Failed to run the playbook due to some missing input parameters. Check you extra vars.
prerequisite | 3007 | Failed to execute playbook, prerequisites are missing for mysql. Check the python libraries needed (section 2 of the README)
prerequisite | 3008 | Failed to execute playbook, prerequisites are missing for postgres. Check the python libraries needed (section 2 of the README)
prerequisite | 3009 | Failed to execute playbook, configuration is missing. Check the pg_hba.conf file.
framework_playbook | 3010 | Failed to create mysql user. Check the logs.
framework_playbook | 3011 | Failed to grant permissions to mysql user. Check the logs.
prerequisite | 3013 | Failed to import powershell module.
framework_playbook | 3014 | Failed to create mssql user. Check the logs.
framework_playbook | 3015 | Failed to grant permissions to mssql user. Check the logs.
framework_playbook | 3020 | Failed to create postgres user. Check the logs.
framework_playbook | 3021 | Failed to grant permissions to postgres user. Check the logs.

## Procedure

The purpose of this role is to:

- Create a user in the specified database type.
- Grant permissions to the newly created user to be able to make the SL1 discovery.

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

1. **Name:** <org_code>_jobtemplate_create_sl1_db_users
2. **Job Type:** run
3. **Inventory:** The inventory that include your server where you want to run the playbook
4. **Project:** <org_code>_project_SL1_automation
5. **Playbook:** manage_database_user.yml
6. **Credentials:** <Ansible_Tower_Credentials><Machine_Credentials>
7. **Verbosity:** Specify the verbosity for your run
8. **Extravars:** Check the Variables section

Example for Extra vars:

```yaml
---
# example extra vars for manage_database_user
sl1_database_server_port: '1433'
sl1_database_instance_name: 'MSSQLSERVER'
sl1_database_username: sl1_db_user
sl1_database_password: P@ssword
sl1_database_type: mssql
sl1_db_prerequisites_auto_install: true
sl1_database_login_user: db_login
sl1_database_login_password: P@sswordlogin
sl1_database_host: 10.1.2.30
sl1_database_name: mssql2

```

## Known problems and limitations

No known problems or limitations.  
In case you have a problem executing this role, please [Create New Issue](https://github.kyndryl.net/Continuous-Engineering/ansible_collection_sl1_automation/issues)

## License

[Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
