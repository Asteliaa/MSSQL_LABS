#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/common.sh"

echo "== Lab 04 =="
compose_up

echo "-- Create logins and users --"
run_sql_file mssql-default /var/opt/mssql/scripts/04-security/scripts/create_logins_and_users.sql

echo "-- Create roles and permissions --"
run_sql_file mssql-default /var/opt/mssql/scripts/04-security/scripts/create_roles_and_permissions.sql

echo "-- Create mgr schema and Orders table --"
run_sql_file mssql-default /var/opt/mssql/scripts/04-security/scripts/create_mgr_schema_and_orders_table.sql

echo "-- Create User1/User2 and deny SELECT --"
run_sql_file mssql-default /var/opt/mssql/scripts/04-security/scripts/create_manager_users_and_deny_select.sql

echo "-- Verify role membership and schema presence --"
run_sql_query mssql-default "USE Test; SELECT r.name AS RoleName, m.name AS MemberName FROM sys.database_role_members drm JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id WHERE r.name IN ('Manager','Employee','NoUpdate');"
run_sql_query mssql-default "USE Test; SELECT s.name AS SchemaName, t.name AS TableName FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'mgr';"

echo "-- Verify denied access for User1 and User2 --"
expect_sql_failure mssql-default "SELECT * FROM mgr.Orders;" -d Test -U User1Login -P Strong_Us3r1!
expect_sql_failure mssql-default "SELECT * FROM mgr.Orders;" -d Test -U User2Login -P Strong_Us3r2!

echo "Lab 04 completed."