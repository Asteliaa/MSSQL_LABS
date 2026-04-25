-- 06-roles-and-permissions.sql
-- Создание пользовательских ролей и настройка прав

USE Test;
GO

-- Роль Manager
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Manager' AND type = 'R')
BEGIN
    CREATE ROLE Manager;
END;
GO

-- Роль Employee
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Employee' AND type = 'R')
BEGIN
    CREATE ROLE Employee;
END;
GO

-- Назначение ролей пользователям TestUser1 и TestUser2
ALTER ROLE Manager ADD MEMBER TestUser1;
GO

ALTER ROLE Employee ADD MEMBER TestUser2;
GO

-- Запрет для роли Employee изменять пользователя guest
DENY ALTER ON USER::guest TO Employee;
GO

-- Дополнительная роль NoUpdate с запретом обновлять таблицы
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'NoUpdate' AND type = 'R')
BEGIN
    CREATE ROLE NoUpdate;
END;
GO

DENY UPDATE TO NoUpdate;
GO