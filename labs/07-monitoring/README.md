# Lab 07 — Monitoring and Index Optimization

## Topic

Monitoring SQL Server activity using dynamic management views (DMVs) and Extended Events, analysing query execution plans, and comparing performance with and without indexes on a large table.

## Original task (short)

Using the training database (in this lab adapted to `ProjectDB` instead of AdventureWorks):

1. Start the system monitor and demonstrate monitoring SQL Server activity for several processes.
2. Analyse server instance activity using tracing.
   - Create a trace using a template.
   - Analyse results while tracing.
   - Save results to a table.
3. Execute a query against a table containing more than 50,000 rows and display the graphical execution plan in SSMS.
4. Create a nonclustered index and a columnstore index for that table.
5. Execute the same query against the modified table and display the execution plan.
6. Compare query performance without indexes and with indexes.[file:9]

## Docker adaptation

- SQL Server runs in the `mssql-default` Docker container.
- Instead of AdventureWorks2012, the lab uses a user database `ProjectDB` with a synthetic table `dbo.OrderDetails` containing 60,000 rows.
- Tracing is implemented using **Extended Events** (session `TrackLongQueries`) instead of SQL Profiler.
- Monitoring of activity uses DMVs (`sys.dm_exec_requests`, `sys.dm_exec_query_plan`, `sys.dm_os_wait_stats`).
- Execution plans are obtained with `SET SHOWPLAN_TEXT` and, optionally, with graphical plans in SSMS.

## Folder structure

```text
labs/07-monitoring-and-indexing/
  README.md
  REPORT.md
  lab07_commands.md
  scripts/
  screenshots/
```