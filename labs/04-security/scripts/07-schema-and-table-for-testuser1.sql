-- 07-schema-and-table-for-testuser1.sql
-- Пункт 4.1: новая схема и таблица в БД Test, принадлежащие TestUser1

USE Test;
GO

-- Создание схемы mgr с владельцем TestUser1
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'mgr')
BEGIN
    EXEC('CREATE SCHEMA mgr AUTHORIZATION TestUser1;');
END;
GO

-- Создание таблицы mgr.Orders
IF OBJECT_ID(N'mgr.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE mgr.Orders
    (
        OrderId   INT IDENTITY(1,1) PRIMARY KEY,
        OrderDate DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
        Amount    DECIMAL(10,2) NOT NULL
    );
END;
GO