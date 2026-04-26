USE master;
GO

ALTER DATABASE Test SET RECOVERY FULL;
GO

BACKUP DATABASE Test
TO DISK = '/var/opt/mssql/backups/Test_full_for_log.bak'
WITH INIT,
     NAME = 'Full backup of Test for log scenario',
     STATS = 10;
GO

BACKUP LOG Test
TO DISK = '/var/opt/mssql/backups/Test_log_1.trn'
WITH INIT,
     NAME = 'Log backup of Test before delete',
     STATS = 10;
GO

USE Test;
GO

SELECT TOP (5) * FROM app.TABLE_1;
GO

DELETE TOP (5) FROM app.TABLE_1;
GO

SELECT COUNT(*) AS RowsAfterDelete
FROM app.TABLE_1;
GO

USE master;
GO

RESTORE DATABASE Test
FROM DISK = '/var/opt/mssql/backups/Test_full_for_log.bak'
WITH NORECOVERY,
     REPLACE,
     STATS = 10;
GO

RESTORE LOG Test
FROM DISK = '/var/opt/mssql/backups/Test_log_1.trn'
WITH RECOVERY,
     STATS = 10;
GO

USE Test;
GO

SELECT COUNT(*) AS RowsAfterRestore
FROM app.TABLE_1;
GO