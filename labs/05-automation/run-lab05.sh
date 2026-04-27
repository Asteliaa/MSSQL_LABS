#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

echo "== Lab 05 =="
compose_up

echo "-- Create basic agent jobs --"
run_sql_file mssql-default /var/opt/mssql/scripts/05-automation/scripts/create_agent_jobs_basic.sql

echo "-- Create alert for error 50000 --"
run_sql_file mssql-default /var/opt/mssql/scripts/05-automation/scripts/create_alert_for_error_50000.sql

echo "-- Configure Database Mail --"
run_sql_file mssql-default /var/opt/mssql/scripts/05-automation/scripts/setup_database_mail.sql

echo "-- Create full backup job for Test --"
run_sql_file mssql-default /var/opt/mssql/scripts/05-automation/scripts/create_full_backup_job_for_test.sql

echo "-- Verify jobs and mail profile --"
run_sql_query mssql-default "USE msdb; SELECT name FROM dbo.sysjobs WHERE name IN ('Job_LogDatabaseSize','Job_InsertHeartbeat','Job_Backup_Test','Job_FullBackup_Test');"
run_sql_query mssql-default "USE msdb; SELECT name FROM sysmail_profile WHERE name = 'Lab5MailProfile';"

echo "Lab 05 completed."