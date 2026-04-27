#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

echo "== Lab 06 =="
compose_up

echo "-- Initialize log shipping primary --"
run_sql_file mssql-default /var/opt/mssql/scripts/06-replication-logshipping/scripts/init_primary_for_log_shipping.sql

echo "-- Initialize log shipping secondary --"
run_sql_file mssql-named /var/opt/mssql/scripts/06-replication-logshipping/scripts/init_secondary_for_log_shipping.sql

echo "-- Configure log shipping primary metadata --"
run_sql_file mssql-default /var/opt/mssql/scripts/06-replication-logshipping/scripts/configure_primary_log_shipping.sql

echo "-- Configure log shipping secondary metadata --"
run_sql_file mssql-named /var/opt/mssql/scripts/06-replication-logshipping/scripts/configure_secondary_log_shipping.sql

echo "-- Verify log shipping metadata --"
run_sql_query mssql-default "SELECT primary_database, backup_directory FROM msdb.dbo.log_shipping_primary_databases WHERE primary_database = 'Test';"
run_sql_query mssql-named "SELECT primary_server, primary_database FROM msdb.dbo.log_shipping_secondary;"
run_sql_query mssql-named "SELECT secondary_database, restore_mode, restore_delay FROM msdb.dbo.log_shipping_secondary_databases WHERE secondary_database = 'Test';"

echo "Lab 06 completed."