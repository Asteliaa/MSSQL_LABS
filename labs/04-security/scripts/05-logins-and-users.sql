-- 05-logins-and-users.sql
-- Создание логинов и пользователей для ЛР4

USE master;
GO

-- Логин TestLogin1 с SQL Server Authentication
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'TestLogin1')
BEGIN
    CREATE LOGIN TestLogin1
    WITH PASSWORD = N'Strong_T3stLogin1!',
         CHECK_POLICY = OFF;
END;
GO

-- Назначение TestLogin1 в серверную роль sysadmin
ALTER SERVER ROLE sysadmin ADD MEMBER TestLogin1;
GO

-- Установка базы Test как базы по умолчанию для TestLogin1
ALTER LOGIN TestLogin1
WITH DEFAULT_DATABASE = Test;
GO

-- Логин TestLogin2
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'TestLogin2')
BEGIN
    CREATE LOGIN TestLogin2
    WITH PASSWORD = N'Strong_T3stLogin2!',
         CHECK_POLICY = OFF;
END;
GO

-- Пользователи в базе Test
USE Test;
GO

-- Пользователь TestUser1 для логина TestLogin1
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'TestUser1')
BEGIN
    CREATE USER TestUser1 FOR LOGIN TestLogin1;
END;
GO

-- Пользователь TestUser2 для логина TestLogin2
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'TestUser2')
BEGIN
    CREATE USER TestUser2 FOR LOGIN TestLogin2;
END;
GO