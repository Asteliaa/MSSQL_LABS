# Lab 02 — Commands

## Create Test database in the default instance (mssql-default)

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/02-databases-and-files/scripts/create_test_database.sql
```

## Create RZ_DB in the named instance (mssql-named)

```bash
cd docker

docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/02-databases-and-files/scripts/create_rz_database.sql
```

## Create schemas and tables in Test and RZ_DB

Run the same script on both instances. The script is idempotent and executes only the part that matches the existing database on the current instance.

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/02-databases-and-files/scripts/create_schemas_and_tables.sql

docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/02-databases-and-files/scripts/create_schemas_and_tables.sql
```

> The script checks database existence and creates objects only for the current instance.

## Verify files, filegroups and tables in Test

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/02-databases-and-files/scripts/verify_files_filegroups_and_tables.sql
```