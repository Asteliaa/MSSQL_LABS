# Lab 07 — Monitoring and Index Optimization

## Objectives

- Monitor SQL Server activity using Extended Events and dynamic management views (DMVs).
- Analyse the behaviour of a SQL Server instance using tracing and query plans.
- Create and compare execution plans for a query against a large table, with and without indexes.
- Demonstrate the performance impact of a nonclustered index and a columnstore index on a large table.[file:9][web:205][web:204]

## Environment and database

- SQL Server runs in the `mssql-default` Docker container.
- The lab uses a user database `ProjectDB` instead of AdventureWorks2012.
- A large table `ProjectDB.dbo.OrderDetails` is created and populated with 60,000 rows to simulate a workload.[cite:10]
- All scripts are executed via `sqlcmd` inside the container, with optional graphical plan viewing in SSMS.

The main scripts are stored in `labs/07-monitoring-and-indexing/scripts/`:

- `create_long_queries_xevent_session.sql`
- `monitor_requests_and_waits.sql`
- `prepare_orderdetails_data.sql`
- `compare_plan_without_and_with_indexes.sql`.

## 1. Extended Events session for monitoring long queries

### 1.1. Creating and starting the TrackLongQueries session

To implement tracing and monitoring of long‑running queries, an Extended Events session `TrackLongQueries` was created:[cite:10][web:201][web:205]

```sql
USE master;
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'TrackLongQueries')
    DROP EVENT SESSION [TrackLongQueries] ON SERVER;
GO

CREATE EVENT SESSION [TrackLongQueries] ON SERVER 
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.sql_text, sqlserver.database_name)
    WHERE ([duration] >= 1000000))
ADD TARGET package0.event_file(SET filename=N'/var/opt/mssql/log/long_queries.xel');
GO

ALTER EVENT SESSION [TrackLongQueries] ON SERVER STATE = START;
GO

SELECT name, is_running 
FROM sys.dm_xe_sessions
WHERE name = 'TrackLongQueries';
GO
```

This session captures `sql_batch_completed` events with duration ≥ 1 second, logging the SQL text and database name to an `.xel` event file in the container.[web:201][web:205]

The script was executed via `sqlcmd` inside `mssql-default`.  
The final query confirmed that the session was running (`is_running = 1`).

<p align="center">
  <img src="../screenshots/xevent-session-running.png" width="700" alt="Extended Events session TrackLongQueries running">
  <br>
  <em>Figure 1 — Extended Events session TrackLongQueries is active on the server.</em>
</p>

In a full SSMS environment, this `.xel` file can be opened using the Extended Events viewer, effectively serving the role of a trace based on a template for long‑running queries.[web:201][web:209]

## 2. Monitoring active requests and waits using DMVs

### 2.1. Script monitor_requests_and_waits.sql

The script `monitor_requests_and_waits.sql` collects information about active requests, their text and execution plans, as well as overall wait statistics:[cite:10][web:210][web:206]

```sql
USE master;
GO

SELECT 
    r.session_id, r.status, r.start_time, r.total_elapsed_time,
    st.text AS QueryText,
    qp.query_plan
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp;
GO

SELECT TOP 10
    wait_type, 
    wait_time_ms / 1000.0 AS WaitSec,
    waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK')
ORDER BY wait_time_ms DESC;
GO

USE [ProjectDB];
GO

SELECT 
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID('ProjectDB'), NULL, NULL, NULL, 'DETAILED')
WHERE avg_fragmentation_in_percent > 10;
GO
```

The script was executed with:

```bash
cd ~/Projects/mssql-lab

cat labs/07-monitoring-and-indexing/scripts/monitor_requests_and_waits.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

### 2.2. Results

- The first query lists currently executing requests, their status and elapsed time, along with the SQL text and XML execution plans returned by `sys.dm_exec_query_plan`.[web:210][web:206]
- The second query shows the top 10 wait types, helping to identify where the instance spends most waiting time.
- The final query reports fragmented indexes in `ProjectDB`, which can be used to plan index maintenance.

<p align="center">
  <img src="../screenshots/dm_exec_requests_plan.png" width="700" alt="Active requests with query plans">
  <br>
  <em>Figure 2 — Active requests and their plans from sys.dm_exec_requests and sys.dm_exec_query_plan.</em>
</p>

<p align="center">
  <img src="../screenshots/dm_os_wait_stats.png" width="700" alt="Top waits from sys.dm_os_wait_stats">
  <br>
  <em>Figure 3 — Top wait types and times on the instance, indicating resource usage patterns.</em>
</p>

Together with the Extended Events session, this satisfies the assignment’s requirement to use a system monitor and tracing to analyse server activity.[web:205][web:210]

## 3. Preparing a large table OrderDetails in ProjectDB

### 3.1. Script prepare_orderdetails_data.sql

To emulate a table with more than 50,000 rows, the script `prepare_orderdetails_data.sql` creates and populates `ProjectDB.dbo.OrderDetails`:[cite:10]

```sql
USE [ProjectDB];
GO

IF OBJECT_ID('dbo.OrderDetails', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderDetails
    (
        OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
        OrderID       INT NOT NULL,
        ProductID     INT NOT NULL,
        Quantity      INT NOT NULL,
        PriceAtOrder  DECIMAL(10,2) NOT NULL
    );
END;
GO

SET NOCOUNT ON;
DECLARE @i INT = 1;
WHILE @i <= 60000
BEGIN
    INSERT INTO dbo.OrderDetails (OrderID, ProductID, Quantity, PriceAtOrder)
    VALUES (1, (@i % 100) + 1, (@i % 10) + 1, 100.00);
    SET @i = @i + 1;
END;
GO
```

The script was executed via `sqlcmd`, and a check confirmed that the table contains 60,000 rows:

```sql
SELECT COUNT(*) AS RowCount FROM ProjectDB.dbo.OrderDetails;
```

This table is used in subsequent steps to evaluate query performance and execution plans before and after indexing.[web:203]

## 4. Execution plan for query without additional indexes

The following aggregation query was chosen:

```sql
SELECT ProductID, SUM(Quantity) AS TotalQty 
FROM dbo.OrderDetails 
GROUP BY ProductID;
```

In SSMS, the **Show Actual Execution Plan** feature was enabled and the query run against `ProjectDB`.  
As an alternative, a textual plan was obtained using `SET SHOWPLAN_TEXT`:[web:207]

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

The execution plan showed a scan over `OrderDetails` (clustered index scan on the primary key or table scan, depending on schema), indicating that no covering index supports the `ProductID`/`Quantity` aggregation.

<p align="center">
  <img src="../screenshots/orderdetails-showplan-before.png" width="700" alt="Execution plan before indexes">
  <br>
  <em>Figure 4 — Execution plan for the aggregation query on OrderDetails before indexes are created (scan-based plan).</em>
</p>

This plan serves as the baseline for comparison.

## 5. Creating nonclustered and columnstore indexes

### 5.1. Script compare_plan_without_and_with_indexes.sql

To improve performance and demonstrate index impact, the script `compare_plan_without_and_with_indexes.sql` was executed:[cite:10][web:204][web:208]

```sql
USE [ProjectDB];
GO

-- Nonclustered index on Quantity
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = N'IX_OrderDetails_Quantity' AND object_id = OBJECT_ID('dbo.OrderDetails')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_OrderDetails_Quantity 
    ON dbo.OrderDetails(Quantity);
END;
GO

-- Columnstore index on key columns
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = N'IX_OrderDetails_ColumnStore' AND object_id = OBJECT_ID('dbo.OrderDetails')
)
BEGIN
    CREATE COLUMNSTORE INDEX IX_OrderDetails_ColumnStore 
    ON dbo.OrderDetails (ProductID, Quantity, PriceAtOrder);
END;
GO

-- Show execution plan after indexes
SET SHOWPLAN_TEXT ON;
GO

SELECT ProductID, SUM(Quantity) AS TotalQty 
FROM dbo.OrderDetails 
GROUP BY ProductID;
GO

SET SHOWPLAN_TEXT OFF;
GO

-- Measure execution time
SET STATISTICS TIME ON;
GO

SELECT ProductID, SUM(Quantity) AS TotalQty 
FROM dbo.OrderDetails 
GROUP BY ProductID;
GO

SET STATISTICS TIME OFF;
GO
```

The nonclustered index provides a more efficient access path for queries filtered or grouped by `Quantity`, while the columnstore index is optimized for analytic workloads on large tables, especially aggregations over many rows.[web:204][web:208]

### 5.2. Execution plan and performance after indexes

After creating the indexes, the aggregation query was run again with an execution plan and `STATISTICS TIME` enabled. The plan now uses the columnstore index (`IX_OrderDetails_ColumnStore`) to perform the aggregation much more efficiently.

<p align="center">
  <img src="../screenshots/orderdetails-showplan-after.png" width="700" alt="Execution plan after indexes">
  <br>
  <em>Figure 5 — Execution plan for the aggregation query on OrderDetails after nonclustered and columnstore indexes are created.</em>
</p>

The output of `SET STATISTICS TIME` was captured before and after indexing. After indexing, both CPU time and elapsed time for the aggregation query decreased, demonstrating the performance benefits of appropriate indexing on a large table.[web:203][web:204]

<p align="center">
  <img src="../screenshots/statistics-time-before-after.png" width="700" alt="STATISTICS TIME output before and after indexing">
  <br>
  <em>Figure 6 — Query CPU and elapsed time comparison before and after index creation.</em>
</p>

## Conclusions

In Lab 07:

- An Extended Events session `TrackLongQueries` was created and started, capturing long‑running batches into an event file and verified via `sys.dm_xe_sessions`, serving as a trace mechanism based on a long‑query template.[web:201][web:205]
- Dynamic management views `sys.dm_exec_requests`, `sys.dm_exec_query_plan`, and `sys.dm_os_wait_stats` were used to monitor active requests, inspect query plans, and review server wait statistics, effectively acting as a system monitor for SQL Server activity.[web:206][web:210]
- A synthetic large table `ProjectDB.dbo.OrderDetails` with 60,000 rows was created to emulate a high‑volume workload.
- An aggregation query on `OrderDetails` was executed without additional indexes, and its execution plan (scan‑based) was captured as a baseline.
- A nonclustered index and a columnstore index were created on `OrderDetails`, and the same query was executed again. The new execution plan used the indexes, and `STATISTICS TIME` showed improved CPU and elapsed times, confirming the performance benefits of indexing on large tables.[web:203][web:204][web:208]
- Overall, the lab demonstrated how monitoring tools (Extended Events, DMVs) and indexing techniques can be combined to analyse and optimize query performance in SQL Server.