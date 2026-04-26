USE master;
GO

BACKUP DATABASE Test
TO DISK = '/var/opt/mssql/backups/Test_full_for_named.bak'
WITH INIT,
     NAME = 'Full backup of Test for named instance',
     STATS = 10;
GO

RESTORE DATABASE Test_from_default
FROM DISK = '/var/opt/mssql/backups/Test_full_for_named.bak'
WITH MOVE 'testdata_a' TO '/var/opt/mssql/data/testdata_a_from_default.mdf',
     MOVE 'testlog'   TO '/var/opt/mssql/data/testlog_from_default.ldf',
     REPLACE,
     STATS = 10;
GO

SELECT name, state_desc
FROM sys.databases
WHERE name = 'Test_from_default';
GO