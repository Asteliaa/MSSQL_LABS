# Создание базы RZ_DB в mssql-named

```bash
cd docker

docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/06-create-rz-db-named.sql
```