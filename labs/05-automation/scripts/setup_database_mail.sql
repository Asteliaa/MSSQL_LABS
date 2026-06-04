USE master;
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;
GO

USE msdb;
GO

IF NOT EXISTS (
    SELECT 1
FROM msdb.dbo.sysmail_account
WHERE name = N'Lab5MailAccount'
)
    EXEC sysmail_add_account_sp
        @account_name  = 'Lab5MailAccount',
        @description   = 'Учетная запись для ЛР5',
        @email_address = 'student@example.com',
        @display_name  = 'SQL Server Lab5',
        @mailserver_name = 'smtp.example.com';
GO

IF NOT EXISTS (
    SELECT 1
FROM msdb.dbo.sysmail_profile
WHERE name = N'Lab5MailProfile'
)
    EXEC sysmail_add_profile_sp
        @profile_name = 'Lab5MailProfile',
        @description  = 'Профиль для ЛР5';
GO

IF NOT EXISTS (
    SELECT 1
FROM msdb.dbo.sysmail_profileaccount pa
    JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id
    JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id
WHERE p.name = N'Lab5MailProfile'
    AND a.name = N'Lab5MailAccount'
)
    EXEC sysmail_add_profileaccount_sp
        @profile_name   = 'Lab5MailProfile',
        @account_name   = 'Lab5MailAccount',
        @sequence_number = 1;
GO