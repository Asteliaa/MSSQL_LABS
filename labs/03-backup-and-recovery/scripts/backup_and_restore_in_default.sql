USE master;
GO

BACKUP DATABASE master
TO DISK = '/var/opt/mssql/backups/master_full_1.bak'
WITH INIT, NAME = 'Full backup of master', STATS = 10;
GO

BACKUP DATABASE Test
TO DISK = '/var/opt/mssql/backups/Test_full_1.bak'
WITH INIT, NAME = 'Full backup of Test', STATS = 10;
GO

-- Переводим в single-user чтобы сбросить все соединения
ALTER DATABASE Test SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID('Test');
GO

RESTORE DATABASE Test
FROM DISK = '/var/opt/mssql/backups/Test_full_1.bak'
WITH REPLACE, STATS = 10;
GO

-- Возвращаем multi-user после восстановления
ALTER DATABASE Test SET MULTI_USER;
GO

SELECT name, state_desc
FROM sys.databases
WHERE name = 'Test';
GO