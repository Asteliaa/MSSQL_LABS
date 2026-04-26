USE master;
GO

BACKUP DATABASE master
TO DISK = '/var/opt/mssql/backups/master_full_1.bak'
WITH INIT,
     NAME = 'Full backup of master',
     STATS = 10;
GO

BACKUP DATABASE Test
TO DISK = '/var/opt/mssql/backups/Test_full_1.bak'
WITH INIT,
     NAME = 'Full backup of Test',
     STATS = 10;
GO

ALTER DATABASE Test
SET OFFLINE WITH ROLLBACK IMMEDIATE;
GO

SELECT
    name,
    physical_name
FROM sys.master_files
WHERE database_id = DB_ID('Test');
GO

ALTER DATABASE Test SET ONLINE;
GO

RESTORE DATABASE Test
FROM DISK = '/var/opt/mssql/backups/Test_full_1.bak'
WITH REPLACE,
     STATS = 10;
GO

SELECT name, state_desc
FROM sys.databases
WHERE name = 'Test';
GO