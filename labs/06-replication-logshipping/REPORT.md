# Lab 06 — Replication and Log Shipping

## Objectives

- Understand the main replication mechanisms in Microsoft SQL Server and how they can be used to distribute data across multiple servers.
- Design a solution for data exchange between three servers (orders, suppliers, stock quotes) and a client.
- Practically configure log shipping between two SQL Server instances in Docker using the `Test` database.
- Demonstrate that changes on the primary server are applied to the secondary server using log backups.[file:8][web:193][web:200]

## Original assignment

The original task described the following scenario:[file:8]

- You are a database administrator for the company **Company** using SQL Server 2012.
- The company has several servers:
  - Server 1 stores order data.
  - Server 2 stores supplier enterprise data.
  - Server 3 stores online stock quotes for enterprises.
  - A client receives daily data about active orders and sold shares.
- Tasks:
  1. Configure the main server to support replication and create a push subscription.
  2. Describe SQL Server mechanisms and tools that can be used to ensure data safety and exchange between the client and all servers.
  3. Configure log shipping between two server instances.

In this lab, replication and push subscriptions are considered conceptually, while log shipping is configured and demonstrated between two Docker-based SQL Server instances.

## Environment and setup

- Host OS: Ubuntu / Linux.
- Docker and `docker-compose`.
- Two SQL Server containers (Developer Edition):
  - `mssql-default` — primary instance.
  - `mssql-named` — secondary instance.
- Shared backup directory:
  - host: `docker/backups/`
  - container: `/var/opt/mssql/backups`.
- Database `Test` is used as the source for log shipping, created in previous labs.[web:171][web:160]

T‑SQL scripts for this lab are stored in:

```text
labs/06-replication-logshipping/scripts/
  init_primary_for_log_shipping.sql
  init_secondary_for_log_shipping.sql
  configure_primary_log_shipping.sql
  configure_secondary_log_shipping.sql
  demo_log_shipping_apply_changes.sql
```

All scripts are executed with `sqlcmd` inside the containers using the `SA` login.

## 1. Replication types and push subscription (theory)

### 1.1. Replication types

SQL Server supports several replication types with different use cases:[web:193][web:195][web:199]

- **Snapshot replication**:
  - Periodically creates a point‑in‑time snapshot of data on the Publisher and applies it to the Subscriber.
  - Suitable when data changes relatively infrequently or when the Subscriber can accept data that is refreshed at scheduled intervals.

- **Transactional replication**:
  - Starts with an initial snapshot and then continuously propagates changes from the transaction log to subscribers with low latency.
  - Ideal for high‑volume OLTP scenarios where subscribers need near real‑time data (for example, orders or stock quotes).[web:195]

- **Merge replication**:
  - Allows changes on both Publisher and Subscribers and then merges changes based on conflict resolution rules.
  - Used when branch offices work offline and later synchronize with the central server.[web:199]

Replication uses a set of **agents** (Snapshot Agent, Log Reader Agent, Distribution Agent, Merge Agent) to generate snapshots, read changes from the log, and deliver them to subscribers.[web:193][web:195]

### 1.2. Push subscription

A **push subscription** is a subscription in which the Distributor/Publisher is responsible for pushing changes to the Subscriber, rather than the Subscriber pulling changes.[web:193][web:195]

Configuration steps (in SSMS) typically include:[web:193][web:195]

1. Configure the Distributor on the Publisher server.
2. Create a publication (snapshot or transactional) on the Publisher.
3. Configure a **push subscription**:
   - select the Subscriber server and database;
   - configure distribution and synchronization schedule;
   - create and schedule the Distribution Agent, which runs at the Distributor and pushes changes to the Subscriber.

This model is appropriate when the Publisher has control over the delivery schedule and when Subscribers should not initiate synchronization on their own.

### 1.3. Applying replication to the Company scenario

For the scenario with three servers and a client:

- **Server 1 (orders) → Client**:
  - Transactional replication with push subscriptions to provide near real‑time order updates to the client.[web:195]
  - Alternatively, snapshot replication with daily refresh if real‑time is not required.

- **Server 2 (suppliers) → Client**:
  - Snapshot replication, as supplier reference data changes relatively infrequently.
  - Alternatively, ETL processes (e.g., SSIS) run nightly to refresh reference tables.

- **Server 3 (stock quotes) → Client**:
  - Transactional replication for continuous streaming of stock prices to the client.[web:195]
  - For less strict requirements, periodic ETL loads aggregating quotes at the end of the day.

- **Data safety and high availability**:
  - Regular full/differential/log backups and test restores.
  - Log shipping or Always On / mirroring for warm standby servers.
  - Monitoring of replication agents and backup jobs.[web:200]

In this lab, the multi‑server replication scenario is discussed conceptually, while log shipping is implemented between two instances as an example of data protection and offloading read workloads.

## 2. Log shipping concept and Docker simplification

Log shipping in SQL Server is a high‑availability feature that continually sends transaction log backups from a primary database to one or more secondary databases.[web:200]

Key components:[web:200]

- **Primary server**: 
  - Database is in `FULL` or `BULK_LOGGED` recovery model.
  - Periodic log backups are created and stored in a shared folder.
- **Secondary server(s)**:
  - Each secondary database is initialized from a full backup, restored with `NORECOVERY`.
  - Log backups are copied from the shared folder and restored in sequence.

In a full production configuration, SQL Server Agent jobs perform backup, copy and restore automatically on defined schedules.[web:192][web:196]

In this Docker‑based lab:

- Two instances (`mssql-default` and `mssql-named`) share the backup folder.
- Standard log shipping configuration procedures `sp_add_log_shipping_primary_database`, `sp_add_log_shipping_secondary_primary`, `sp_add_log_shipping_secondary_database` are executed to register log shipping metadata.
- Because SQL Server Agent is not fully used on the secondary, the actual backup and restore of log backups are demonstrated manually to show how changes flow from primary to secondary.[web:192][web:200]

## 3. Step 1 — Preparing Test for log shipping on primary

### 3.1. Script init_primary_for_log_shipping.sql

The script `init_primary_for_log_shipping.sql` sets up the `Test` database on the primary server (`mssql-default`) for log shipping:[cite:9]

- switches `Test` to the FULL recovery model;
- performs an initial log backup;
- performs a full backup to initialize the secondary.

```sql
USE master;
GO

ALTER DATABASE Test SET RECOVERY FULL;
GO

BACKUP LOG Test
TO DISK = N'/var/opt/mssql/backups/Test_log_init.trn'
WITH INIT;
GO

BACKUP DATABASE Test
TO DISK = N'/var/opt/mssql/backups/Test_full_for_logshipping.bak'
WITH INIT,
     NAME = N'Full backup for log shipping initialization';
GO
```

### 3.2. Execution and verification

The script was executed on `mssql-default`:

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/init_primary_for_log_shipping.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

The `sqlcmd` output showed successful `BACKUP LOG` and `BACKUP DATABASE` operations to the shared backup folder `/var/opt/mssql/backups` on the primary container.[web:192][web:196]

<p align="center">
  <img src="../screenshots/primary-backup-init.png" width="700" alt="Initial log and full backup for log shipping on primary">
  <br>
  <em>Figure 1 — Initial log and full backups of Test for log shipping initialization on the primary server.</em>
</p>

## 4. Step 2 — Initializing Test on secondary from full backup

### 4.1. Script init_secondary_for_log_shipping.sql

On the secondary server (`mssql-named`), the script `init_secondary_for_log_shipping.sql` performs:[cite:9]

- dropping any existing `Test` database;
- restoring `Test` from the shared full backup using new file locations and leaving it in the `RESTORING` state with `NORECOVERY`.

```sql
USE master;
GO

IF DB_ID(N'Test') IS NOT NULL
BEGIN
    ALTER DATABASE Test SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Test;
END;
GO

RESTORE DATABASE Test
FROM DISK = N'/var/opt/mssql/backups/Test_full_for_logshipping.bak'
WITH
    MOVE N'testdata_a' TO N'/var/opt/mssql/data/Test_logship_a.mdf',
    MOVE N'testdata_b' TO N'/var/opt/mssql/data/Test_logship_b.ndf',
    MOVE N'testlog'    TO N'/var/opt/mssql/data/Test_logship_log.ldf',
    NORECOVERY;
GO
```

### 4.2. Execution and verification

The script was executed on `mssql-named`:

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/init_secondary_for_log_shipping.sql | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Database state check:

```bash
echo "SELECT name, state_desc 
FROM sys.databases 
WHERE name = 'Test';" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

The output shows `Test` with `state_desc = RESTORING`, which is required for log shipping (the database is not yet accessible for user queries).[web:200]

<p align="center">
  <img src="../screenshots/secondary-test-restoring.png" width="700" alt="Database Test in RESTORING state on secondary">
  <br>
  <em>Figure 2 — Database Test restored in RESTORING state on the secondary server.</em>
</p>

## 5. Step 3 — Configuring log shipping on primary

### 5.1. Script configure_primary_log_shipping.sql

The script `configure_primary_log_shipping.sql` configures `Test` as a log shipping primary database on `mssql-default` using `sp_add_log_shipping_primary_database`:[cite:9][web:192]

```sql
USE master;
GO

DECLARE
    @LS_BackupJobId UNIQUEIDENTIFIER,
    @LS_PrimaryId   UNIQUEIDENTIFIER;

EXEC master.dbo.sp_add_log_shipping_primary_database
    @database = N'Test',
    @backup_directory = N'/var/opt/mssql/backups',
    @backup_share = N'/var/opt/mssql/backups',
    @backup_job_name = N'LSBackup_Test',
    @backup_retention_period = 4320,
    @backup_compression = 0,
    @backup_threshold = 60,
    @threshold_alert_enabled = 0,
    @history_retention_period = 5760,
    @backup_job_id = @LS_BackupJobId OUTPUT,
    @primary_id = @LS_PrimaryId OUTPUT,
    @overwrite = 1;
GO
```

This registers the primary database and creates metadata for a log backup job (`LSBackup_Test`) in `msdb`.[web:196][web:200]

### 5.2. Execution and verification

Script execution:

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/configure_primary_log_shipping.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Verification query:

```bash
echo "SELECT primary_database, backup_directory 
FROM msdb.dbo.log_shipping_primary_databases 
WHERE primary_database = 'Test';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

The result shows:

- `primary_database = Test`
- `backup_directory = /var/opt/mssql/backups`.

<p align="center">
  <img src="../screenshots/primary-logshipping-primary-databases.png" width="700" alt="log_shipping_primary_databases for Test">
  <br>
  <em>Figure 3 — Test registered as a log shipping primary database on mssql-default.</em>
</p>

This confirms that `Test` is configured as a log shipping primary database.

## 6. Step 4 — Configuring log shipping on secondary

### 6.1. Script configure_secondary_log_shipping.sql

On `mssql-named`, the script `configure_secondary_log_shipping.sql` performs two tasks:[cite:9][web:192]

1. Registers the primary server and database as a log shipping source using `sp_add_log_shipping_secondary_primary`.
2. Registers `Test` as a secondary database using `sp_add_log_shipping_secondary_database`.

```sql
USE master;
GO

DECLARE
    @LS_SecondaryId UNIQUEIDENTIFIER;

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.log_shipping_secondary
    WHERE primary_server = N'mssql-default'
      AND primary_database = N'Test'
)
BEGIN
    EXEC master.dbo.sp_add_log_shipping_secondary_primary
        @primary_server = N'mssql-default',
        @primary_database = N'Test',
        @backup_source_directory = N'/var/opt/mssql/backups',
        @backup_destination_directory = N'/var/opt/mssql/backups',
        @copy_job_name = N'LSCopy_Test',
        @restore_job_name = N'LSRestore_Test',
        @file_retention_period = 4320,
        @monitor_server = NULL,
        @monitor_server_security_mode = 1,
        @secondary_id = @LS_SecondaryId OUTPUT;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.log_shipping_secondary_databases
    WHERE secondary_database = N'Test'
)
BEGIN
    EXEC master.dbo.sp_add_log_shipping_secondary_database
        @secondary_database = N'Test',
        @primary_server = N'mssql-default',
        @primary_database = N'Test',
        @restore_delay = 0,
        @restore_mode = 0,
        @disconnect_users = 0,
        @restore_threshold = 60,
        @threshold_alert_enabled = 0,
        @history_retention_period = 5760;
END;
GO
```

In a full log shipping configuration, these procedures also create copy and restore jobs on the secondary. In the Docker lab, the focus is on configuration metadata rather than automated scheduling.

### 6.2. Execution and verification

Script execution:

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/configure_secondary_log_shipping.sql | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Agent‑related warnings may appear on the secondary, which is expected because SQL Server Agent is not actively used in this lab.

Verification queries:

```bash
echo "SELECT primary_server, primary_database
FROM msdb.dbo.log_shipping_secondary;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

```bash
echo "SELECT secondary_database, restore_mode, restore_delay
FROM msdb.dbo.log_shipping_secondary_databases
WHERE secondary_database = 'Test';" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

The results show:

- `primary_server = mssql-default`, `primary_database = Test` in `log_shipping_secondary`.
- `secondary_database = Test`, `restore_mode = 0`, `restore_delay = 0` in `log_shipping_secondary_databases`.[web:200]

<p align="center">
  <img src="../screenshots/secondary-logshipping-secondary.png" width="700" alt="log_shipping_secondary on secondary">
  <br>
  <em>Figure 4 — Primary/secondary relationship registered on mssql-named.</em>
</p>

<p align="center">
  <img src="../screenshots/secondary-logshipping-secondary-databases.png" width="700" alt="log_shipping_secondary_databases for Test">
  <br>
  <em>Figure 5 — Test registered as a log shipping secondary database on mssql-named.</em>
</p>

This confirms that log shipping is configured at the metadata level between the two instances.

## 7. Step 5 — Manual demonstration of log shipping (data movement)

Because SQL Server Agent is not running on the secondary in this Docker setup, the actual backup/copy/restore sequence was demonstrated manually:

1. Insert test data in `Test` on the primary.
2. Back up the transaction log on the primary.
3. Restore the log backup on the secondary.
4. Bring the secondary database online and verify that the data has been transferred.

### 7.1. Inserting test data in LogShipDemo on primary

On `mssql-default`, a test table `dbo.LogShipDemo` was created and a row inserted:[cite:9]

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

The result shows a single row with the test message and timestamp.

<p align="center">
  <img src="../screenshots/primary-logshipdemo-row.png" width="700" alt="LogShipDemo row on primary">
  <br>
  <em>Figure 6 — Test row inserted into dbo.LogShipDemo on the primary server.</em>
</p>

### 7.2. BACKUP LOG on primary

A log backup was taken on `mssql-default`:

```bash
echo "BACKUP LOG Test
TO DISK = N'/var/opt/mssql/backups/Test_log_manual_1.trn'
WITH INIT, NAME = N'Log backup for manual log shipping test';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

This produced a log backup file `Test_log_manual_1.trn` in the shared backups directory.[web:192][web:196]

### 7.3. RESTORE LOG on secondary

The log backup was applied on `mssql-named` while `Test` was still in the `RESTORING` state:

```bash
echo "RESTORE LOG Test
FROM DISK = N'/var/opt/mssql/backups/Test_log_manual_1.trn'
WITH NORECOVERY;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

The `sqlcmd` output reported that several pages from the log file were processed for the `Test` database.

### 7.4. Bringing Test online on secondary and verifying data

To make the database readable, `Test` was brought online with `WITH RECOVERY`:

```bash
echo "RESTORE DATABASE Test WITH RECOVERY;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Then the test table was queried:

```bash
echo "SELECT * FROM dbo.LogShipDemo;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C -d Test
```

The result shows the same row that was inserted on the primary, with matching `Info` and `CreatedAt` values.

<p align="center">
  <img src="../screenshots/secondary-logshipdemo-row.png" width="700" alt="LogShipDemo row on secondary">
  <br>
  <em>Figure 7 — Test row present in dbo.LogShipDemo on the secondary server after log restore.</em>
</p>

This confirms that log backups produced on the primary can be used to bring the secondary database up to date, which is the core mechanism of log shipping.[web:192][web:200]

## Conclusions

In this lab:

- The main replication types supported by SQL Server (snapshot, transactional, merge) and the concept of push subscriptions were reviewed, and their application to a multi‑server scenario (orders, suppliers, stock quotes, client) was discussed.[web:193][web:195][web:199]
- A conceptual architecture was proposed in which:
  - transactional replication and/or ETL processes keep the client database synchronized with Server 1 and Server 3;
  - snapshot replication or ETL is used for Server 2 reference data;
  - backup/restore and log shipping provide data safety and disaster recovery.
- Log shipping was configured between two Docker-based SQL Server instances (`mssql-default` as primary and `mssql-named` as secondary) using the standard procedures `sp_add_log_shipping_primary_database`, `sp_add_log_shipping_secondary_primary`, and `sp_add_log_shipping_secondary_database`.[web:192][web:196][web:200]
- A full backup of `Test` was used to initialize the secondary database, and the database was left in `RESTORING` state as required for log shipping.
- A manual test demonstrated that changes on the primary (`dbo.LogShipDemo` insertion) can be transferred to the secondary by performing a log backup on the primary and restoring the log on the secondary, confirming the data flow mechanism of log shipping.[web:192][web:200]
- Due to the Docker environment and limited use of SQL Server Agent on the secondary, the copy/restore steps were executed manually; however, the fundamental behaviour of log shipping, as described in SQL Server documentation, was reproduced.[web:192][web:200]

This lab shows how replication concepts and log shipping can be combined to design robust, multi‑server data architectures and how log shipping can be configured and tested in a containerized SQL Server environment.