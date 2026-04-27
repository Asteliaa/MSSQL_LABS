# MSSQL Administration Labs

This repository contains hands-on labs for Microsoft SQL Server administration.
The environment is built around Ubuntu, Docker, and `sqlcmd` so the labs can be run locally
without a dedicated database server or SSMS in the default workflow.

## What Is Included

- A Docker environment with two SQL Server 2022 instances.
- Labs 01-07 with commands, SQL scripts, reports, and screenshots

## Quick Start

```bash
cd docker
docker compose up -d
docker compose ps
```

Check the main instance connection:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "SELECT @@VERSION AS version_info;"
```

If the containers are already running, you can go straight to the required lab and use the
commands from the corresponding `labXX_commands.md` file.

## SQL Server Instances

- `mssql-default` - primary instance, exposed on port `1433`.
- `mssql-named` - second instance, exposed on port `1434`.

Both containers mount the `labs/` directory as `/var/opt/mssql/scripts`, and
`docker/backups/` as `/var/opt/mssql/backups`

## Running the Labs

Each lab has its own command file inside the lab folder:

- `labs/01-installation/lab01_commands.md`
- `labs/02-databases-and-files/lab02_commands.md`
- `labs/03-backup-and-recovery/lab03_commands.md`
- `labs/04-security/lab04_commands.md`
- `labs/05-automation/lab05_commands.md`
- `labs/06-replication-logshipping/lab06_commands.md`
- `labs/07-monitoring/07_commands.md`

The same folders also contain the SQL scripts, reports, and screenshots.

## Lab Summary

- 01 Installation - start the containers, check version info, and inspect basic metadata.
- 02 Databases and Files - create databases, files, filegroups, schemas, and tables.
- 03 Backup and Recovery - full restore, database copy, and transaction log work.
- 04 Security - logins, users, roles, and access restrictions.
- 05 Automation - SQL Server Agent, jobs, alerts, and Database Mail.
- 06 Replication - log shipping preparation and data transfer demonstration.
- 07 Monitoring - Extended Events, DMVs, execution plans, and index impact.

## Environment Requirements

- Docker Engine and Docker Compose.
- Access to Linux containers.
- Enough memory and CPU resources to run two SQL Server 2022 instances at the same time.

## Recommended Workflow

1. Start the containers.
2. Verify connections to `mssql-default` and `mssql-named`.
3. Complete the labs in order.
4. Compare your results with the reports and screenshots under `labs/`.