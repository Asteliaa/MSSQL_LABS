USE master;
GO

IF DB_ID(N'Test') IS NULL
BEGIN
    CREATE DATABASE Test
    ON PRIMARY
    (
        NAME = N'testdata_a',
        FILENAME = N'/var/opt/mssql/data/testdata_a.mdf',
        SIZE = 4MB,
        FILEGROWTH = 2MB,
        MAXSIZE = 10MB
    )
    LOG ON
    (
        NAME = N'testlog',
        FILENAME = N'/var/opt/mssql/data/testlog.ldf',
        SIZE = 2MB,
        FILEGROWTH = 2MB
    );
END;
GO

-- Переключаемся в Test чтобы sys.filegroups видела её объекты
USE Test;
GO

IF NOT EXISTS (
    SELECT 1
FROM sys.filegroups
WHERE name = N'TestFileGroup'
)
    ALTER DATABASE Test
    ADD FILEGROUP TestFileGroup;
GO

IF NOT EXISTS (
    SELECT 1
FROM sys.master_files
WHERE name = N'testdata_b'
)
    ALTER DATABASE Test
    ADD FILE
    (
        NAME = N'testdata_b',
        FILENAME = N'/var/opt/mssql/data/testdata_b.ndf',
        SIZE = 5MB,
        FILEGROWTH = 2MB,
        MAXSIZE = UNLIMITED
    )
    TO FILEGROUP TestFileGroup;
GO