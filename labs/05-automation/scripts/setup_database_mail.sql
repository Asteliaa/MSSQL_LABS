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

EXEC sysmail_add_account_sp
    @account_name = 'Lab5MailAccount',
    @description = 'Учетная запись для ЛР5',
    @email_address = 'student@example.com',
    @display_name = 'SQL Server Lab5',
    @mailserver_name = 'smtp.example.com';
GO

EXEC sysmail_add_profile_sp
    @profile_name = 'Lab5MailProfile',
    @description  = 'Профиль для ЛР5';
GO

EXEC sysmail_add_profileaccount_sp
    @profile_name = 'Lab5MailProfile',
    @account_name = 'Lab5MailAccount',
    @sequence_number = 1;
GO