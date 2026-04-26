USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'User1Login')
BEGIN
    CREATE LOGIN User1Login
    WITH PASSWORD = N'Strong_Us3r1!',
         CHECK_POLICY = OFF;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'User2Login')
BEGIN
    CREATE LOGIN User2Login
    WITH PASSWORD = N'Strong_Us3r2!',
         CHECK_POLICY = OFF;
END;
GO

USE Test;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'User1')
BEGIN
    CREATE USER User1 FOR LOGIN User1Login;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'User2')
BEGIN
    CREATE USER User2 FOR LOGIN User2Login;
END;
GO

ALTER ROLE Manager ADD MEMBER User1;
GO

ALTER ROLE Manager ADD MEMBER User2;
GO

DENY SELECT ON OBJECT::mgr.Orders TO User1;
GO

DENY SELECT ON OBJECT::mgr.Orders TO User2;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'NoSelectMgrOrders' AND type = 'R')
BEGIN
    CREATE ROLE NoSelectMgrOrders;
END;
GO

DENY SELECT ON OBJECT::mgr.Orders TO NoSelectMgrOrders;
GO

ALTER ROLE NoSelectMgrOrders ADD MEMBER User1;
GO

ALTER ROLE NoSelectMgrOrders ADD MEMBER User2;
GO