USE msdb;
GO

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_FullBackup_Test')
BEGIN
    EXEC sp_add_job
        @job_name = N'Job_FullBackup_Test',
        @enabled = 1,
        @description = N'План обслуживания: полный бэкап базы Test по расписанию';
END;
GO

EXEC sp_add_jobstep
    @job_name = N'Job_FullBackup_Test',
    @step_name = N'Full backup Test',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'
        BACKUP DATABASE Test
        TO DISK = ''/var/opt/mssql/backups/Test_full_maintenance.bak''
        WITH INIT, NAME = ''Full backup of Test (Maintenance Plan)'';
    ',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

EXEC sp_add_jobschedule
    @job_name = N'Job_FullBackup_Test',
    @name = N'EveryDayAt01AM',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 010000;
GO

EXEC sp_add_jobserver
    @job_name = N'Job_FullBackup_Test',
    @server_name = N'(LOCAL)';
GO
