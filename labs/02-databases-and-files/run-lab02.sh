#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

echo "== Lab 02 =="
compose_up

echo "-- Create Test database on mssql-default --"
run_sql_file mssql-default /var/opt/mssql/scripts/02-databases-and-files/scripts/create_test_database.sql

echo "-- Create RZ_DB on mssql-named --"
run_sql_file mssql-named /var/opt/mssql/scripts/02-databases-and-files/scripts/create_rz_database.sql

echo "-- Create schemas and tables on both instances --"
run_sql_file mssql-default /var/opt/mssql/scripts/02-databases-and-files/scripts/create_schemas_and_tables.sql
run_sql_file mssql-named /var/opt/mssql/scripts/02-databases-and-files/scripts/create_schemas_and_tables.sql

echo "-- Verify files, filegroups and tables --"
run_sql_file mssql-default /var/opt/mssql/scripts/02-databases-and-files/scripts/verify_files_filegroups_and_tables.sql
run_sql_file mssql-named /var/opt/mssql/scripts/02-databases-and-files/scripts/verify_files_filegroups_and_tables.sql

echo "Lab 02 completed."