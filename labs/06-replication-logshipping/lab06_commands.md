# Lab 06 — Commands 

Primary server: `mssql-default`  
Secondary server: `mssql-named`

## 1. Check containers and shared backup folder

```bash
cd docker

docker ps | grep mssql-
```

```bash
docker exec -it mssql-default ls -ld /var/opt/mssql/backups
docker exec -it mssql-named   ls -ld /var/opt/mssql/backups
```

## 2. Step 1 — Prepare Test on primary (FULL + initial backup)

Run `init_primary_for_log_shipping.sql` on `mssql-default`:

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/init_primary_for_log_shipping.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

This script:

- sets `Test` to `FULL` recovery model;
- creates an initial log backup:
  - `/var/opt/mssql/backups/Test_log_init.trn`;
- creates a full backup for log shipping initialization:
  - `/var/opt/mssql/backups/Test_full_for_logshipping.bak`.

Take a screenshot of the `sqlcmd` output showing both backup operations.

## 3. Step 2 — Initialize Test on secondary from full backup

Run `init_secondary_for_log_shipping.sql` on `mssql-named`:

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/init_secondary_for_log_shipping.sql | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Check that the database is in `RESTORING` state:

```bash
echo "SELECT name, state_desc 
FROM sys.databases 
WHERE name = 'Test';" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Expected: `Test` with `state_desc = RESTORING`.

Screenshot: `secondary-test-restoring.png`.

## 4. Step 3 — Configure log shipping on primary

Run `configure_primary_log_shipping.sql` on `mssql-default`:

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/configure_primary_log_shipping.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Verify that `Test` is registered as a log shipping primary database:

```bash
echo "SELECT primary_database, backup_directory 
FROM msdb.dbo.log_shipping_primary_databases 
WHERE primary_database = 'Test';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Expected: a row with `primary_database = Test`, `backup_directory = /var/opt/mssql/backups`.

Screenshot: `primary-logshipping-primary-databases.png`.

## 5. Step 4 — Configure log shipping on secondary

Run `configure_secondary_log_shipping.sql` on `mssql-named`:

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/configure_secondary_log_shipping.sql | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

There may be warnings about SQL Server Agent not running; this is expected in Docker for this lab.

Verify the primary/secondary relationship:

```bash
echo "SELECT primary_server, primary_database
FROM msdb.dbo.log_shipping_secondary;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Expected: `primary_server = mssql-default`, `primary_database = Test`.

Verify the secondary database configuration:

```bash
echo "SELECT secondary_database, restore_mode, restore_delay
FROM msdb.dbo.log_shipping_secondary_databases
WHERE secondary_database = 'Test';" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Expected: `secondary_database = Test`, `restore_mode = 0`, `restore_delay = 0`.

Screenshots: `secondary-logshipping-secondary.png`, `secondary-logshipping-secondary-databases.png`.

## 6. Step 5 — Manual demonstration of log shipping

Because SQL Server Agent is not running on the secondary in Docker, log shipping is demonstrated manually: BACKUP LOG on primary → RESTORE LOG on secondary → data check.

### 6.1. Insert test data on primary

Run a small script on `mssql-default` to create and populate `Test.dbo.LogShipDemo`:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test << 'EOF'
IF OBJECT_ID('dbo.LogShipDemo', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.LogShipDemo
    (
        Id        INT IDENTITY(1,1) PRIMARY KEY,
        Info      NVARCHAR(100),
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO

INSERT INTO dbo.LogShipDemo(Info)
VALUES (N'Первая запись для проверки log shipping');
GO

SELECT * FROM dbo.LogShipDemo;
GO
EOF
```

Screenshot: `primary-logshipdemo-row.png` — shows the inserted row on the primary.

### 6.2. BACKUP LOG on primary

```bash
echo "BACKUP LOG Test
TO DISK = N'/var/opt/mssql/backups/Test_log_manual_1.trn'
WITH INIT, NAME = N'Log backup for manual log shipping test';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

This writes `Test_log_manual_1.trn` to the shared backups folder.

### 6.3. RESTORE LOG on secondary

Apply the log backup to the secondary database (still in RESTORING):

```bash
echo "RESTORE LOG Test
FROM DISK = N'/var/opt/mssql/backups/Test_log_manual_1.trn'
WITH NORECOVERY;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

### 6.4. Bring Test online on secondary (for reading)

```bash
echo "RESTORE DATABASE Test WITH RECOVERY;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

### 6.5. Verify data on secondary

```bash
echo "SELECT * FROM dbo.LogShipDemo;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C -d Test
```

Expected: the same row inserted on the primary appears on the secondary.

Screenshot: `secondary-logshipdemo-row.png`.

This manual sequence demonstrates that changes on the primary can be delivered to the secondary via log backups, which is the core idea of log shipping.[web:192][web:200]