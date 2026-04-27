#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

echo "== Lab 07 =="
compose_up

echo "-- Prepare OrderDetails data --"
run_sql_file mssql-default /var/opt/mssql/scripts/07-monitoring/scripts/prepare_orderdetails_data.sql

echo "-- Start TrackLongQueries Extended Events session --"
run_sql_file mssql-default /var/opt/mssql/scripts/07-monitoring/scripts/create_long_queries_xevent_session.sql

echo "-- Monitor active requests and waits --"
run_sql_file mssql-default /var/opt/mssql/scripts/07-monitoring/scripts/monitor_requests_and_waits.sql

echo "-- Compare execution plan before and after indexes --"
run_sql_file mssql-default /var/opt/mssql/scripts/07-monitoring/scripts/compare_plan_without_and_with_indexes.sql

echo "Lab 07 completed."