USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'TestLogin1')
BEGIN
    CREATE LOGIN TestLogin1
    WITH PASSWORD = N'Strong_T3stLogin1!',
         CHECK_POLICY = OFF;
END;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER TestLogin1;
GO

ALTER LOGIN TestLogin1
WITH DEFAULT_DATABASE = Test;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'TestLogin2')
BEGIN
    CREATE LOGIN TestLogin2
    WITH PASSWORD = N'Strong_T3stLogin2!',
         CHECK_POLICY = OFF;
END;
GO

USE Test;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'TestUser1')
BEGIN
    CREATE USER TestUser1 FOR LOGIN TestLogin1;
END;
GO


IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'TestUser2')
BEGIN
    CREATE USER TestUser2 FOR LOGIN TestLogin2;
END;
GO