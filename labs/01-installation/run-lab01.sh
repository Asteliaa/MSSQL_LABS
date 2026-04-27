#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

echo "== Lab 01 =="
compose_up
compose_ps

echo "-- Container logs --"
docker logs --tail 20 mssql-default
docker logs --tail 20 mssql-named

echo "-- Metadata checks --"
run_sql_file mssql-default /var/opt/mssql/scripts/01-installation/scripts/check_server_metadata.sql
run_sql_file mssql-named /var/opt/mssql/scripts/01-installation/scripts/check_server_metadata.sql

echo "-- Stop and start default instance --"
compose_stop mssql_default
compose_ps
compose_start mssql_default
compose_ps

echo "Lab 01 completed."