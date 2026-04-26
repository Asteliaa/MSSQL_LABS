-- 01-primary-init.sql
-- Подготовка базы Test к log shipping на первичном сервере

USE master;
GO

-- Переводим базу в FULL recovery model
ALTER DATABASE Test SET RECOVERY FULL;
GO

-- Гарантируем, что все изменения записаны в журнал
BACKUP LOG Test TO DISK = N'/var/opt/mssql/backups/Test_log_init.trn' WITH INIT;
GO

-- Полный резервный backup базы Test (будет использован для инициализации secondary)
BACKUP DATABASE Test
TO DISK = N'/var/opt/mssql/backups/Test_full_for_logshipping.bak'
WITH INIT, NAME = N'Full backup for log shipping initialization';
GO
