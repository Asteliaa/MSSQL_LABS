USE master;
GO

DECLARE
    @LS_BackupJobId UNIQUEIDENTIFIER,
    @LS_PrimaryId   UNIQUEIDENTIFIER;

EXEC master.dbo.sp_add_log_shipping_primary_database
    @database = N'Test',
    @backup_directory = N'/var/opt/mssql/backups',
    @backup_share = N'/var/opt/mssql/backups',
    @backup_job_name = N'LSBackup_Test',
    @backup_retention_period = 4320,  -- 3 дня (в минутах)
    @backup_compression = 0,
    @backup_threshold = 60,
    @threshold_alert_enabled = 0,
    @history_retention_period = 5760,
    @backup_job_id = @LS_BackupJobId OUTPUT,
    @primary_id = @LS_PrimaryId OUTPUT,
    @overwrite = 1;
GO