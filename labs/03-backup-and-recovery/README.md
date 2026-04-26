# Lab 03 — Backup and Recovery

## Topic

Disaster recovery, full/differential/log backups and database restore scenarios in Microsoft SQL Server using Docker and `sqlcmd`.

## Original task (short)

- Create a backup of the `master` database to removable media.
- Using the `Test` database from Lab 02:
  - create a full backup of `Test`;
  - corrupt the data file, attempt to bring `Test` online;
  - restore `Test` from the backup using `RESTORE`.
- Repeat backup and restore using another server instance as the source device.
- Provide an example of configuring database mirroring for any database.
- Provide an example of creating a database snapshot for `Test2` with Transact‑SQL.
- Simulate a logical error using a transaction log backup:
  - show any table, delete several rows,
  - restore the database to its original state using backup and log backup.
- Propose a backup strategy for a real‑estate company with 5 working days and describe the recovery process after a server failure on Wednesday morning.

## Docker adaptation

- Default instance → container `mssql-default` (system databases + user database `Test`).
- Named instance → container `mssql-named` (database `RZ_DB` and restored `Test_from_default`).
- Backup directory inside containers: `/var/opt/mssql/backups`, mapped to `docker/backups/` on the host.
- All operations are performed using `sqlcmd` inside containers and `docker exec` commands, without SSMS.

## Folder structure

```text
labs/03-backup-and-recovery/
  README.md                 ← this file
  REPORT.md                 ← detailed lab report
  lab03_commands.md         ← Docker + sqlcmd commands
  scripts/                  ← T‑SQL scripts for this lab
  screenshots/              ← backup/restore and log scenario evidence
```