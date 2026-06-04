USE msdb;
GO

IF NOT EXISTS (SELECT 1
FROM msdb.dbo.sysjobs
WHERE name = N'Job_FullBackup_Test')
    EXEC sp_add_job
        @job_name    = N'Job_FullBackup_Test',
        @enabled     = 1,
        @description = N'План обслуживания: полный бэкап базы Test по расписанию';
GO

IF NOT EXISTS (
    SELECT 1
FROM msdb.dbo.sysjobsteps s
    JOIN msdb.dbo.sysjobs j ON s.job_id = j.job_id
WHERE j.name = N'Job_FullBackup_Test'
    AND s.step_name = N'Full backup Test'
)
    EXEC sp_add_jobstep
        @job_name          = N'Job_FullBackup_Test',
        @step_name         = N'Full backup Test',
        @subsystem         = N'TSQL',
        @database_name     = N'master',
        @command           = N'
            BACKUP DATABASE Test
            TO DISK = ''/var/opt/mssql/backups/Test_full_maintenance.bak''
            WITH INIT, NAME = ''Full backup of Test (Maintenance Plan)'';
        ',
        @on_success_action = 1,
        @on_fail_action    = 2;
GO

IF NOT EXISTS (
    SELECT 1
FROM msdb.dbo.sysjobschedules s
    JOIN msdb.dbo.sysjobs j ON s.job_id = j.job_id
WHERE j.name = N'Job_FullBackup_Test'
)
    EXEC sp_add_jobschedule
        @job_name          = N'Job_FullBackup_Test',
        @name              = N'EveryDayAt01AM',
        @freq_type         = 4,
        @freq_interval     = 1,
        @active_start_time = 010000;
GO

IF NOT EXISTS (
    SELECT 1
FROM msdb.dbo.sysjobservers s
    JOIN msdb.dbo.sysjobs j ON s.job_id = j.job_id
WHERE j.name = N'Job_FullBackup_Test'
)
    EXEC sp_add_jobserver
        @job_name    = N'Job_FullBackup_Test',
        @server_name = N'(LOCAL)';
GO  