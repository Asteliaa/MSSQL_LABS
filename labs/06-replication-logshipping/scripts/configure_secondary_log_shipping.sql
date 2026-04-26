USE master;
GO

DECLARE
    @LS_SecondaryId UNIQUEIDENTIFIER;

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.log_shipping_secondary
    WHERE primary_server = N'mssql-default'
      AND primary_database = N'Test'
)
BEGIN
    EXEC master.dbo.sp_add_log_shipping_secondary_primary
        @primary_server = N'mssql-default',                -- имя контейнера primary
        @primary_database = N'Test',
        @backup_source_directory = N'/var/opt/mssql/backups',
        @backup_destination_directory = N'/var/opt/mssql/backups',
        @copy_job_name = N'LSCopy_Test',
        @restore_job_name = N'LSRestore_Test',
        @file_retention_period = 4320,
        @monitor_server = NULL,
        @monitor_server_security_mode = 1,
        @secondary_id = @LS_SecondaryId OUTPUT;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.log_shipping_secondary_databases
    WHERE secondary_database = N'Test'
)
BEGIN
    EXEC master.dbo.sp_add_log_shipping_secondary_database
        @secondary_database = N'Test',
        @primary_server = N'mssql-default',
        @primary_database = N'Test',
        @restore_delay = 0,
        @restore_mode = 0,         
        @disconnect_users = 0,
        @restore_threshold = 60,
        @threshold_alert_enabled = 0,
        @history_retention_period = 5760;
END;
GO