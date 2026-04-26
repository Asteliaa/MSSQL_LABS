# Lab 06 — Replication and Log Shipping

## Topic

Replication and log shipping in Microsoft SQL Server 2012: high‑level mechanisms for data availability across multiple servers and practical configuration of log shipping between two SQL Server instances in Docker.

## Original task (short)

- You are a database administrator for the company **Company**, using SQL Server 2012.
- Configure your main server to support replication and create a **push subscription**.
- Scenario:
  - Server 1 stores orders data.
  - Server 2 stores supplier enterprises.
  - Server 3 stores online stock prices for enterprises.
  - A client receives daily consolidated data about actual orders and sold shares.
- Describe SQL Server mechanisms and tools for data safety and data exchange between the client and all servers.
- Configure log shipping between two server instances.

## Docker adaptation

In this lab, the **replication scenario with three servers** is analysed conceptually, while the **practical part** focuses on configuring log shipping between two SQL Server instances running in Docker:

- `mssql-default` — primary server (contains database `Test`).
- `mssql-named` — secondary server (receives log‑shipped copy of `Test`).
- Both containers share a common backup folder:
  - host: `docker/backups/`
  - container: `/var/opt/mssql/backups`.

Replication types, push subscriptions and multi‑server scenarios are described in the report; log shipping is configured and demonstrated with T‑SQL and `sqlcmd` in Docker.

## Folder structure

```text
labs/06-replication-logshipping/
  README.md                         ← this file
  REPORT.md                         ← detailed lab report
  lab06_commands.md                 ← Docker + sqlcmd commands for this lab
  scripts/
  screenshots/
```