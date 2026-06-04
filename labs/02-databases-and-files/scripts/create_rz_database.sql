USE master;
GO

IF DB_ID(N'RZ_DB') IS NULL
BEGIN
    CREATE DATABASE RZ_DB
    ON PRIMARY
    (
        NAME = N'rzdata',
        FILENAME = N'/var/opt/mssql/data/rzdata.mdf',
        SIZE = 4MB,
        FILEGROWTH = 2MB
    )
    LOG ON
    (
        NAME = N'rzlog',
        FILENAME = N'/var/opt/mssql/data/rzlog.ldf',
        SIZE = 2MB,
        FILEGROWTH = 2MB
    );
END;
GO