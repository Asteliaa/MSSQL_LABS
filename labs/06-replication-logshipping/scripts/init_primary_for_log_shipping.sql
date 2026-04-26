USE master;
GO

ALTER DATABASE Test SET RECOVERY FULL;
GO

BACKUP LOG Test
TO DISK = N'/var/opt/mssql/backups/Test_log_init.trn'
WITH INIT;
GO

BACKUP DATABASE Test
TO DISK = N'/var/opt/mssql/backups/Test_full_for_logshipping.bak'
WITH INIT,
     NAME = N'Full backup for log shipping initialization';
GO