USE master;
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'TrackLongQueries')
    DROP EVENT SESSION [TrackLongQueries] ON SERVER;
GO

CREATE EVENT SESSION [TrackLongQueries] ON SERVER 
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.sql_text, sqlserver.database_name)
    WHERE ([duration] >= 1000000))  -- ~1 сек и больше (в микросекундах)
ADD TARGET package0.event_file(SET filename=N'/var/opt/mssql/log/long_queries.xel');
GO

ALTER EVENT SESSION [TrackLongQueries] ON SERVER STATE = START;
GO

SELECT name, is_running 
FROM sys.dm_xe_sessions
WHERE name = 'TrackLongQueries';
GO