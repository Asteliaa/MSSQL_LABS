-- ============================================================
-- Mirroring endpoint (syntax demo only).
-- In Docker the partner TCP addresses are unreachable by design
-- ============================================================

IF NOT EXISTS (
    SELECT 1
FROM sys.endpoints
WHERE name = N'MirroringEndpoint'
)
BEGIN
    CREATE ENDPOINT MirroringEndpoint
        STATE = STARTED
        AS TCP (LISTENER_PORT = 5022)
        FOR DATABASE_MIRRORING (ROLE = ALL);
END;
GO

ALTER DATABASE Test SET RECOVERY FULL;
GO

-- NOTE: commands below demonstrate mirroring syntax only.
-- Real mirroring requires two servers reachable by network name.
-- In this Docker environment the addresses are intentionally unreachable.
ALTER DATABASE Test
SET PARTNER = 'TCP://principal-server:5022';
GO

ALTER DATABASE Test
SET PARTNER = 'TCP://mirror-server:5022';
GO

-- ============================================================
-- Database snapshot of Test (idempotent)
-- ============================================================

IF DB_ID(N'Test_Snapshot') IS NOT NULL
    DROP DATABASE Test_Snapshot;
GO

CREATE DATABASE Test_Snapshot
ON
(
    NAME = N'testdata_a',
    FILENAME = N'/var/opt/mssql/data/Test_Snapshot_a.ss'
),
(
    NAME = N'testdata_b',
    FILENAME = N'/var/opt/mssql/data/Test_Snapshot_b.ss'
)
AS SNAPSHOT OF Test;
GO

SELECT
    name,
    state_desc,
    DB_NAME(source_database_id) AS source_db
FROM sys.databases
WHERE source_database_id IS NOT NULL;
GO