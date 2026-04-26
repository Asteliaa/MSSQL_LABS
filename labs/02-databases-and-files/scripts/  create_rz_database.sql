USE master;
GO

CREATE DATABASE RZ_DB
ON PRIMARY
(
    NAME = N'rzdata_a',
    FILENAME = N'/var/opt/mssql/data/rzdata_a.mdf',
    SIZE = 4MB,
    FILEGROWTH = 2MB,
    MAXSIZE = 20MB
)
LOG ON
(
    NAME = N'rzlog',
    FILENAME = N'/var/opt/mssql/data/rzlog.ldf',
    SIZE = 2MB,
    FILEGROWTH = 2MB
);
GO