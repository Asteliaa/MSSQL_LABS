# Lab 02 — Commands

## Create Test database in the default instance (mssql-default)

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/create_test_database.sql
```

## Create RZ_DB in the named instance (mssql-named)

```bash
cd docker

docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/create_rz_database.sql
```

## Create schemas and tables in Test and RZ_DB

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/create_schemas_and_tables.sql
```

> The script switches context between `Test` and `RZ_DB` using `USE` statements.

## Verify files, filegroups and tables in Test

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/verify_files_filegroups_and_tables.sql
```