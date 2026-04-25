-- 08-manager-users-and-deny-select.sql
-- Пункт 4.2: пользователи User1, User2, роль Manager и запрет SELECT из mgr.Orders

USE master;
GO

-- Логин User1Login
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'User1Login')
BEGIN
    CREATE LOGIN User1Login
    WITH PASSWORD = N'Strong_Us3r1!',
         CHECK_POLICY = OFF;
END;
GO

-- Логин User2Login
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'User2Login')
BEGIN
    CREATE LOGIN User2Login
    WITH PASSWORD = N'Strong_Us3r2!',
         CHECK_POLICY = OFF;
END;
GO

USE Test;
GO

-- Пользователь User1 для User1Login
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'User1')
BEGIN
    CREATE USER User1 FOR LOGIN User1Login;
END;
GO

-- Пользователь User2 для User2Login
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'User2')
BEGIN
    CREATE USER User2 FOR LOGIN User2Login;
END;
GO

-- Добавление User1 и User2 в роль Manager
ALTER ROLE Manager ADD MEMBER User1;
GO

ALTER ROLE Manager ADD MEMBER User2;
GO

-- Способ 1: прямой запрет SELECT для конкретных пользователей
DENY SELECT ON OBJECT::mgr.Orders TO User1;
GO

DENY SELECT ON OBJECT::mgr.Orders TO User2;
GO

-- Способ 2 (альтернативный): через отдельную роль, если требуется
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