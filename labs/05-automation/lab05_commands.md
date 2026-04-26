# Lab 05 — Commands

> All commands are executed from the `docker/` directory in the project.
> Lab 05 scripts are mounted into the container as:
> `/var/opt/mssql/scripts/05-automation/scripts/`.

## 1. Check that SQL Server Agent is running and list jobs

```bash
cd docker

docker ps | grep mssql-default
```

List existing jobs in `msdb`:

```bash
echo "SELECT name FROM msdb.dbo.sysjobs;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

## 2. Create two basic jobs and their tables

Run the script `create_agent_jobs_basic.sql` to create tables `JobLog`, `Heartbeat` in `Test` and jobs `Job_LogDatabaseSize` and `Job_InsertHeartbeat` in `msdb`:

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/05-automation/scripts/create_agent_jobs_basic.sql
```

After a few minutes, verify that the jobs are running and logging data:

```bash
echo "SELECT TOP (10) * FROM dbo.JobLog ORDER BY Id DESC;
SELECT TOP (10) * FROM dbo.Heartbeat ORDER BY Id DESC;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test
```

## 3. Create Alert for error 50000 and its job

Run the script `create_alert_for_error_50000.sql` to create job `Job_OnSeverity16` and Alert `Alert_Error50000_Test`:

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/05-automation/scripts/create_alert_for_error_50000.sql
```

Optionally, test the job manually:

```bash
echo "EXEC msdb.dbo.sp_start_job N'Job_OnSeverity16';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Check that `JobLog` contains a row for `Job_OnSeverity16`:

```bash
echo "SELECT TOP (5) * 
FROM dbo.JobLog 
WHERE JobName = 'Job_OnSeverity16' 
ORDER BY Id DESC;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test
```

### 3.1. Generate error to trigger the Alert

Open an interactive `sqlcmd` session in database `Test`:

```bash
cd docker

docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test
```

Inside `sqlcmd`:

```sql
RAISERROR('Lab severity 16 error', 16, 1);
GO
EXIT
```

```bash
echo "SELECT TOP (5) * 
FROM dbo.JobLog 
WHERE JobName = 'Job_OnSeverity16' 
ORDER BY Id DESC;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test
```

## 4. Configure Database Mail (account + profile)

Run the script `setup_database_mail.sql`:

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/05-automation/scripts/setup_database_mail.sql
```

```bash
echo "SELECT name FROM msdb.dbo.sysmail_profile;
SELECT name FROM msdb.dbo.sysmail_account;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d msdb
```

## 5. Create full backup job for Test (maintenance-like plan)

Run the script `create_full_backup_job_for_test.sql` to create job `Job_FullBackup_Test`:

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/05-automation/scripts/create_full_backup_job_for_test.sql
```

### 5.1. Start the backup job manually

To test the job without waiting for the schedule:

```bash
echo "EXEC msdb.dbo.sp_start_job N'Job_FullBackup_Test';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

```bash
docker exec -it mssql-default ls -l /var/opt/mssql/backups/Test_full_maintenance.bak
```