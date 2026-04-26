USE master;
GO

IF DB_ID(N'Test') IS NOT NULL
BEGIN
    ALTER DATABASE Test SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Test;
END;
GO

RESTORE DATABASE Test
FROM DISK = N'/var/opt/mssql/backups/Test_full_for_logshipping.bak'
WITH
    MOVE N'testdata_a' TO N'/var/opt/mssql/data/Test_logship_a.mdf',
    MOVE N'testdata_b' TO N'/var/opt/mssql/data/Test_logship_b.ndf',
    MOVE N'testlog'    TO N'/var/opt/mssql/data/Test_logship_log.ldf',
    NORECOVERY;
GO