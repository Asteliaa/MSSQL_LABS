-- It creates objects only in databases that exist on the current server.

IF DB_ID(N'Test') IS NOT NULL
BEGIN
    EXEC (N'USE Test;
    IF SCHEMA_ID(N''app'') IS NULL
        EXEC(N''''CREATE SCHEMA app AUTHORIZATION dbo;'''');

    IF OBJECT_ID(N''app.TABLE_1'', N''U'') IS NULL
    BEGIN
        CREATE TABLE app.TABLE_1
        (
            Id        INT IDENTITY(1,1) PRIMARY KEY,
            Name      NVARCHAR(100) NOT NULL,
            CreatedAt DATETIME2     NOT NULL DEFAULT SYSDATETIME()
        );
    END;

    IF OBJECT_ID(N''app.TABLE_2'', N''U'') IS NULL
    BEGIN
        CREATE TABLE app.TABLE_2
        (
            Id    INT IDENTITY(1,1) PRIMARY KEY,
            Value NVARCHAR(100) NOT NULL
        )
        ON TestFileGroup;
    END;

    IF SCHEMA_ID(N''external'') IS NULL
        EXEC(N''''CREATE SCHEMA external AUTHORIZATION dbo;'''');

    IF OBJECT_ID(N''external.TABLE_3'', N''U'') IS NULL
    BEGIN
        CREATE TABLE external.TABLE_3
        (
            Id      INT IDENTITY(1,1) PRIMARY KEY,
            Comment NVARCHAR(200) NULL
        );
    END;');
END;
GO

IF DB_ID(N'RZ_DB') IS NOT NULL
BEGIN
    EXEC (N'USE RZ_DB;
    IF SCHEMA_ID(N''rz'') IS NULL
        EXEC(N''''CREATE SCHEMA rz AUTHORIZATION dbo;'''');

    IF OBJECT_ID(N''rz.MY_TABLE'', N''U'') IS NULL
    BEGIN
        CREATE TABLE rz.MY_TABLE
        (
            Id   INT IDENTITY(1,1) PRIMARY KEY,
            Data NVARCHAR(100) NOT NULL
        );
    END;');
END;
GO