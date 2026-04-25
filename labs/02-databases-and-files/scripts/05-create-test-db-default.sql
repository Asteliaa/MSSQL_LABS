USE master;
GO

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
GO

ALTER DATABASE Test
ADD FILEGROUP TestFileGroup;
GO

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