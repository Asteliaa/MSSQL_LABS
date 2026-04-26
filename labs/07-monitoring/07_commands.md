# Lab 07 — Commands (Docker + sqlcmd)

SQL Server instance: `mssql-default`.

## 1. Create and start Extended Events session TrackLongQueries

Run the script `create_long_queries_xevent_session.sql`:

```bash
cd ~/Projects/mssql-lab

cat labs/07-monitoring-and-indexing/scripts/create_long_queries_xevent_session.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

The script:

- drops existing session `TrackLongQueries` (if any);
- creates an Extended Events session tracking `sql_batch_completed` events with duration ≥ 1 second;
- writes to `/var/opt/mssql/log/long_queries.xel`;
- starts the session and queries `sys.dm_xe_sessions` to confirm it is running.

Screenshot: `xevent-session-running.png` — output of `SELECT name, is_running FROM sys.dm_xe_sessions WHERE name = 'TrackLongQueries';`.

## 2. Monitor active requests, waits and index fragmentation

Run the script `monitor_requests_and_waits.sql`:

```bash
cd ~/Projects/mssql-lab

cat labs/07-monitoring-and-indexing/scripts/monitor_requests_and_waits.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

The script:

- queries `sys.dm_exec_requests` with `sys.dm_exec_sql_text` and `sys.dm_exec_query_plan`;
- queries top 10 waits from `sys.dm_os_wait_stats`;
- shows index fragmentation in `ProjectDB` using `sys.dm_db_index_physical_stats`.

Screenshots:

- `dm_exec_requests_plan.png` — sample output of active requests and query plan XML.
- `dm_os_wait_stats.png` — top wait types.

## 3. Prepare table OrderDetails in ProjectDB with > 50,000 rows

Run `prepare_orderdetails_data.sql`:

```bash
cd ~/Projects/mssql-lab

cat labs/07-monitoring-and-indexing/scripts/prepare_orderdetails_data.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

The script:

- creates `ProjectDB.dbo.OrderDetails` if it does not exist;
- inserts 60,000 rows into the table.

Optional check:

```bash
echo "SELECT COUNT(*) AS RowCount FROM ProjectDB.dbo.OrderDetails;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

## 4. Execution plan for query without additional indexes

In SSMS (or via `sqlcmd` using SHOWPLAN), run:

```sql
USE [ProjectDB];
GO

SET SHOWPLAN_TEXT ON;
GO

SELECT ProductID, SUM(Quantity) AS TotalQty 
FROM dbo.OrderDetails 
GROUP BY ProductID;
GO

SET SHOWPLAN_TEXT OFF;
GO
```

Screenshot: `orderdetails-showplan-before.png` — execution plan (graphical in SSMS or textual SHOWPLAN output) showing a scan of `OrderDetails`.

## 5. Create nonclustered and columnstore indexes and rerun the query

Run `compare_plan_without_and_with_indexes.sql`:

```bash
cd ~/Projects/mssql-lab

cat labs/07-monitoring-and-indexing/scripts/compare_plan_without_and_with_indexes.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

The script:

- creates nonclustered index `IX_OrderDetails_Quantity` on `(Quantity)` if not present;
- creates columnstore index `IX_OrderDetails_ColumnStore` on `(ProductID, Quantity, PriceAtOrder)` if not present;
- shows the execution plan for `SELECT ProductID, SUM(Quantity) ... GROUP BY ProductID;` with `SET SHOWPLAN_TEXT ON`;
- measures execution time for the same query using `SET STATISTICS TIME ON`.

Screenshots:

- `orderdetails-showplan-after.png` — execution plan after indexes.
- `statistics-time-before-after.png` — execution time (CPU and elapsed) before and after indexes (you can capture “before” separately and combine in one image for comparison).