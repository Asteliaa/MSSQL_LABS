# Lab 05 — Automation of Administrative Tasks

## Topic

Automating administrative tasks in Microsoft SQL Server using SQL Server Agent jobs, alerts, Database Mail and maintenance-like backup jobs.

## Original task (short)

- Configure the SQL Server Agent service and use it to run jobs on different instances.
- Create two server jobs and run them on a schedule.
- Demonstrate creating an Alert for any event that starts a job.
- Implement the backup strategy proposed in Lab 03 using appropriate services.
- Install and configure Database Mail.
- Using the Maintenance Plan wizard (or equivalent), create a plan that performs a full backup of database `Test` on a schedule.

## Docker adaptation

- Default instance is implemented as the `mssql-default` container with SQL Server Agent enabled (`MSSQL_AGENT_ENABLED=true`).
- All administration is performed using the `sqlcmd` utility inside the container, instead of SSMS and graphical wizards.
- SQL Server Agent jobs and alerts are created by T‑SQL scripts stored in `labs/05-automation/scripts/` and mounted into the container as `/var/opt/mssql/scripts/05-automation/scripts/`.

## Folder structure

```text
labs/05-automation/
  README.md                       ← this file
  REPORT.md                       ← detailed lab report
  lab05_commands.md               ← Docker + sqlcmd commands
  scripts/
  screenshots/
```