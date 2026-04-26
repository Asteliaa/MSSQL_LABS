# Lab 01 — SQL Server Installation in Docker

## Topic

Installing two SQL Server instances in Docker on Ubuntu and connecting with `sqlcmd`.

## Original task (short)

- Deploy a default SQL Server instance.
- Deploy a second (named) instance.
- Check instance properties.
- Stop and start the database engine.

## Docker adaptation

- Two instances are implemented as containers:
  - `mssql-default` → default instance on port 1433.
  - `mssql-named` → second instance on port 1434.
- Administration is done via `sqlcmd` inside containers.
- Engine stop/start is done via `docker compose stop/start` for `mssql_default`.

## Folder structure

```text
labs/01-installation/
  README.md          ← this file
  REPORT.md          ← detailed lab report
  scripts/           ← T‑SQL scripts for checks
  screenshots/       ← evidence (docker, sqlcmd output)
```