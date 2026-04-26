# Lab 04 — Security Management

## Topic

Managing security in Microsoft SQL Server: logins, database users, roles and permissions in a Docker‑based environment.

## Original task (short)

- Create database `Test` for the exercises.
- Switch the server authentication mode to Mixed (Windows + SQL Server Authentication).
- Create SQL login `TestLogin1`, set a password, add it to fixed server role `sysadmin`, and set `Test` as its default database.
- Create SQL login `TestLogin2` and database users `TestUser1` and `TestUser2` in `Test`, mapped to logins `TestLogin1` and `TestLogin2`.
- In database `Test`:
  - create database roles `Manager` and `Employee`,
  - assign `Manager` to `TestUser1`, `Employee` to `TestUser2`,
  - deny `Employee` the ability to alter the `guest` user,
  - create another role and deny it the ability to update tables.
- Task 4.1: create a table in a new schema in `Test` owned by `TestUser1` (Transact‑SQL).
- Task 4.2: create users `User1` and `User2` in `Test`, add them to role `Manager`, and by several methods (including T‑SQL) deny them selecting data from the table created in Task 4.1.

## Docker adaptation

- Default instance is implemented as the `mssql-default` container, which hosts the `Test` database created in previous labs.
- Server authentication mode in the SQL Server Docker image is already configured as Mixed, so SQL Server logins such as `TestLogin1` and `TestLogin2` can be used.
- All administration tasks are performed via the `sqlcmd` utility inside the container instead of SSMS.
- Database scripts are stored in the project under `labs/04-security/scripts/` and mounted into the container as `/var/opt/mssql/scripts/04-security/scripts/`.

## Folder structure

```text
labs/04-security/
  README.md                         ← this file
  REPORT.md                         ← detailed lab report
  lab04_commands.md                 ← Docker + sqlcmd commands for this lab
  scripts/                          ← T‑SQL scripts
  screenshots/                      ← evidence (sqlcmd output, role membership, permission errors)
```