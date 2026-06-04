-- Schemas and tables for mssql-default (Test database)
-- Safe to run multiple times.

USE Test;
GO

IF SCHEMA_ID(N'app') IS NULL
    EXEC(N'CREATE SCHEMA app AUTHORIZATION dbo');
GO

IF SCHEMA_ID(N'mgr') IS NULL
    EXEC(N'CREATE SCHEMA mgr AUTHORIZATION dbo');
GO

IF SCHEMA_ID(N'[external]') IS NULL
    EXEC(N'CREATE SCHEMA [external] AUTHORIZATION dbo');
GO

IF OBJECT_ID(N'app.TABLE_1', N'U') IS NULL
BEGIN
    CREATE TABLE app.TABLE_1
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO

IF OBJECT_ID(N'app.TABLE_2', N'U') IS NULL
BEGIN
    CREATE TABLE app.TABLE_2
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Value NVARCHAR(100) NOT NULL
    ) ON TestFileGroup;
END;
GO

IF OBJECT_ID(N'[external].TABLE_3', N'U') IS NULL
BEGIN
    CREATE TABLE [external].TABLE_3
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Comment NVARCHAR(200) NULL
    );
END;
GO