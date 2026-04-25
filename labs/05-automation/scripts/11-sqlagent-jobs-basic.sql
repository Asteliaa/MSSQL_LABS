USE Test;
GO

IF OBJECT_ID('dbo.JobLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.JobLog
    (
        Id           INT IDENTITY(1,1) PRIMARY KEY,
        JobName      SYSNAME,
        RunDateTime  DATETIME2 NOT NULL,
        DatabaseName SYSNAME,
        SizeMB       DECIMAL(18,2) NOT NULL
    );
END;
GO

IF OBJECT_ID('dbo.Heartbeat', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Heartbeat
    (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        RunDateTime DATETIME2 NOT NULL
    );
END;
GO

USE msdb;
GO

-- Job 1: логирует размер базы Test каждую минуту
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_LogDatabaseSize')
BEGIN
    EXEC sp_add_job
        @job_name = N'Job_LogDatabaseSize',
        @enabled = 1,
        @description = N'Логирование размера базы Test в таблицу JobLog';
END;
GO

EXEC sp_add_jobstep
    @job_name = N'Job_LogDatabaseSize',
    @step_name = N'Log size of Test',
    @subsystem = N'TSQL',
    @database_name = N'Test',
    @command = N'
        INSERT INTO dbo.JobLog (JobName, RunDateTime, DatabaseName, SizeMB)
        SELECT
            ''Job_LogDatabaseSize'',
            SYSDATETIME(),
            DB_NAME(database_id),
            size * 8.0 / 1024
        FROM sys.master_files
        WHERE database_id = DB_ID(''Test'')
          AND type = 0;
    ',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

EXEC sp_add_jobschedule
    @job_name = N'Job_LogDatabaseSize',
    @name = N'Every1Minute',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 4,
    @freq_subday_interval = 1,
    @active_start_time = 000000;
GO

EXEC sp_add_jobserver
    @job_name = N'Job_LogDatabaseSize',
    @server_name = N'(LOCAL)';
GO

-- Job 2: heartbeat каждые 2 минуты
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_InsertHeartbeat')
BEGIN
    EXEC sp_add_job
        @job_name = N'Job_InsertHeartbeat',
        @enabled = 1,
        @description = N'Запись пульса в таблицу Heartbeat';
END;
GO

EXEC sp_add_jobstep
    @job_name = N'Job_InsertHeartbeat',
    @step_name = N'Insert heartbeat row',
    @subsystem = N'TSQL',
    @database_name = N'Test',
    @command = N'
        INSERT INTO dbo.Heartbeat (RunDateTime)
        VALUES (SYSDATETIME());
    ',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

EXEC sp_add_jobschedule
    @job_name = N'Job_InsertHeartbeat',
    @name = N'Every2Minutes',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 4,
    @freq_subday_interval = 2,
    @active_start_time = 000000;
GO

EXEC sp_add_jobserver
    @job_name = N'Job_InsertHeartbeat',
    @server_name = N'(LOCAL)';
GO