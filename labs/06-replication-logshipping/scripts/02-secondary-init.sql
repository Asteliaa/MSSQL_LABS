-- 02-secondary-init.sql
-- Инициализация базы Test на вторичном сервере для log shipping

USE master;
GO

-- Если база Test уже существует на secondary, переводим в SINGLE_USER и удаляем
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
