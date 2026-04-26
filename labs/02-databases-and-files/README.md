# Lab 02 — Database and File Management

## Topic

Managing databases and files in Microsoft SQL Server: data files, filegroups, schemas and tables in a default and a named instance.

## Original task (short)

- Create database `Test` in the default instance with:
  - primary data file `testdata_a` (4 MB, autogrowth 2 MB, max 10 MB),
  - secondary data file `testdata_b.ndf` (5 MB, autogrowth 2 MB, unlimited size),
  - additional filegroup `TestFileGroup` containing `testdata_b`.
- In the named instance, create database `RZ_DB` (name includes initials).
- In `Test` and `RZ_DB`, create schemas and tables, including a table on a specific filegroup and a table in a schema that does not belong to the current user.

## Docker adaptation

- Default instance → container `mssql-default` (port 1433), database `Test`.
- Named instance → container `mssql-named` (port 1434), database `RZ_DB`.
- All actions are performed using T‑SQL scripts executed via `sqlcmd` inside Docker containers, instead of SSMS.

## Folder structure

```text
labs/02-databases-and-files/
  README.md                     ← this file
  REPORT.md                     ← detailed lab report
  lab02_commands.md             ← Docker + sqlcmd commands
  scripts/                      ← T‑SQL scripts for this lab
  screenshots/                  ← evidence (sqlcmd output, metadata)
```