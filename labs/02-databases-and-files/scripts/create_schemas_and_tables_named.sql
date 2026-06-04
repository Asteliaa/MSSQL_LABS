-- Schemas and tables for mssql-named (RZ_DB database)
-- Safe to run multiple times.

USE RZ_DB;
GO

IF SCHEMA_ID(N'rz') IS NULL
    EXEC(N'CREATE SCHEMA rz AUTHORIZATION dbo');
GO

IF OBJECT_ID(N'rz.MY_TABLE', N'U') IS NULL
BEGIN
    CREATE TABLE rz.MY_TABLE
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Data NVARCHAR(100) NOT NULL
    );
END;
GO