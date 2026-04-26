USE Test;
GO

SELECT
    name AS FileName,
    physical_name AS PhysicalName,
    type_desc AS FileType,
    size * 8 / 1024 AS SizeMB,
    max_size,
    growth
FROM sys.database_files;
GO

SELECT
    name AS FilegroupName,
    type_desc,
    is_default
FROM sys.filegroups;
GO

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;
GO