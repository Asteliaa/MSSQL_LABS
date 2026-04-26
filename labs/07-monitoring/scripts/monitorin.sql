USE [master];
GO

SELECT 
    r.session_id, r.status, r.start_time, r.total_elapsed_time,
    st.text AS QueryText,
    qp.query_plan
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp;

SELECT TOP 10
    wait_type, 
    wait_time_ms / 1000.0 AS WaitSec,
    waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK')
ORDER BY wait_time_ms DESC;

USE [ProjectDB];
GO

SELECT 
    OBJECT_NAME(object_id) AS TableName,
    index_id,
    avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID('ProjectDB'), NULL, NULL, NULL, 'DETAILED')
WHERE avg_fragmentation_in_percent > 10;
GO