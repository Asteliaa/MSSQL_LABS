USE master;
GO

RESTORE DATABASE Test
FROM DISK = '/var/opt/mssql/backups/Test_full_for_named.bak'
WITH MOVE 'testdata_a' TO '/var/opt/mssql/data/testdata_a.mdf',
     MOVE 'testdata_b' TO '/var/opt/mssql/data/testdata_b.ndf',
     MOVE 'testlog'    TO '/var/opt/mssql/data/testlog.ldf',
     REPLACE,
     STATS = 10;
GO

SELECT name, state_desc
FROM sys.databases
WHERE name = 'Test';
GO
