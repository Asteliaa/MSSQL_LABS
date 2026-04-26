-- Lab 01 — Check SQL Server metadata
-- Run in sqlcmd against a given instance

SELECT @@SERVERNAME AS ServerName,
       @@VERSION    AS VersionInfo;
GO

SELECT name
FROM sys.databases;
GO

SELECT
    SERVERPROPERTY('ServerName')     AS ServerName,
    SERVERPROPERTY('Edition')        AS Edition,
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('ProductLevel')   AS ProductLevel;
GO

SELECT
    DB_NAME(database_id) AS DatabaseName,
    name                 AS LogicalName,
    physical_name        AS PhysicalPath
FROM sys.master_files
WHERE DB_NAME(database_id) = 'master';
GO