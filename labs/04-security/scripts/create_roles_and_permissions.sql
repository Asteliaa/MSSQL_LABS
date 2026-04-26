USE Test;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Manager' AND type = 'R')
BEGIN
    CREATE ROLE Manager;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Employee' AND type = 'R')
BEGIN
    CREATE ROLE Employee;
END;
GO

GO

ALTER ROLE Employee ADD MEMBER TestUser2;
GO

DENY ALTER ON USER::guest TO Employee;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'NoUpdate' AND type = 'R')
BEGIN
    CREATE ROLE NoUpdate;
END;
GO

DENY UPDATE TO NoUpdate;
GO