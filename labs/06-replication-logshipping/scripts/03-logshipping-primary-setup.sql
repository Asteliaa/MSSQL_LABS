-- 03-logshipping-primary-setup.sql
-- Настройка log shipping на первичном сервере для базы Test

USE master;
GO

DECLARE
    @LS_BackupJobId UNIQUEIDENTIFIER,
    @LS_PrimaryId   UNIQUEIDENTIFIER;

EXEC master.dbo.sp_add_log_shipping_primary_database
    @database = N'Test',
    @backup_directory = N'/var/opt/mssql/backups',   -- локальный путь в контейнере
    @backup_share = N'/var/opt/mssql/backups',       -- "сетевая" шара, в Docker тот же путь
    @backup_job_name = N'LSBackup_Test',
    @backup_retention_period = 4320,   -- 3 дня (минуты)
    @backup_compression = 0,
    @backup_threshold = 60,            -- ожидание между backup'ами
    @threshold_alert_enabled = 0,
    @history_retention_period = 5760,
    @backup_job_id = @LS_BackupJobId OUTPUT,
    @primary_id = @LS_PrimaryId OUTPUT,
    @overwrite = 1;
GO

-- Проверка (можно запустить отдельно):
-- SELECT primary_database, backup_directory 
-- FROM msdb.dbo.log_shipping_primary_databases 
-- WHERE primary_database = 'Test';
GO