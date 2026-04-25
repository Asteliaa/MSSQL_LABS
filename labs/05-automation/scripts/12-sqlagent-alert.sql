USE msdb;
GO

--------------------------------------------------
-- 1. Задание, которое будет выполняться при Alert
--------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_OnSeverity16')
BEGIN
    EXEC sp_add_job
        @job_name = N'Job_OnSeverity16',
        @enabled = 1,
        @description = N'Задание, запускаемое Alert''ом при ошибке (message_id = 50000)';
END;
GO

-- Шаг: записать событие в JobLog
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobsteps
    WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'Job_OnSeverity16')
      AND step_name = N'Log error 50000 event'
)
BEGIN
    EXEC sp_add_jobstep
        @job_name = N'Job_OnSeverity16',
        @step_name = N'Log error 50000 event',
        @subsystem = N'TSQL',
        @database_name = N'Test',
        @command = N'
            INSERT INTO dbo.JobLog (JobName, RunDateTime, DatabaseName, SizeMB)
            VALUES (''Job_OnSeverity16'', SYSDATETIME(), ''Test'', 0.0);
        ',
        @on_success_action = 1,
        @on_fail_action = 2;
END;
GO

-- Привязка job к серверу (если нужно)
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobservers s
    JOIN msdb.dbo.sysjobs j ON s.job_id = j.job_id
    WHERE j.name = N'Job_OnSeverity16'
)
BEGIN
    EXEC sp_add_jobserver
        @job_name = N'Job_OnSeverity16',
        @server_name = N'(LOCAL)';
END;
GO

--------------------------------------------------
-- 2. Alert на message_id = 50000 в базе Test
--    с запуском Job_OnSeverity16
--------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysalerts WHERE name = N'Alert_Error50000_Test')
BEGIN
    EXEC sp_add_alert
        @name                       = N'Alert_Error50000_Test',
        @message_id                 = 50000,      -- стандартный msg_id для RAISERROR('text',...)
        @severity                   = 0,          -- 0, если используем message_id
        @enabled                    = 1,
        @delay_between_responses    = 0,
        @include_event_description_in = 1,
        @database_name              = N'Test',
        @job_name                   = N'Job_OnSeverity16';
END;
GO