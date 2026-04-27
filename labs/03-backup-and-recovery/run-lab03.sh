#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

echo "== Lab 03 =="
compose_up

echo "-- Check backups directory --"
run_container_bash mssql-default 'ls -ld /var/opt/mssql/backups && ls -1 /var/opt/mssql/backups || true'

echo "-- Backup and restore in default instance --"
run_sql_file mssql-default /var/opt/mssql/scripts/03-backup-and-recovery/scripts/backup_and_restore_in_default.sql

echo "-- Copy Test from default to named instance --"
run_sql_file mssql-default /var/opt/mssql/scripts/03-backup-and-recovery/scripts/copy_test_to_named_instance.sql
run_sql_file mssql-named /var/opt/mssql/scripts/03-backup-and-recovery/scripts/copy_test_to_named_instance.sql

echo "-- Log backup and point-in-time restore --"
run_sql_file mssql-default /var/opt/mssql/scripts/03-backup-and-recovery/scripts/log_backup.sql

echo "-- Snapshot and mirroring examples --"
run_sql_file mssql-default /var/opt/mssql/scripts/03-backup-and-recovery/scripts/snapshot_and_mirroring_examples.sql

echo "Lab 03 completed."