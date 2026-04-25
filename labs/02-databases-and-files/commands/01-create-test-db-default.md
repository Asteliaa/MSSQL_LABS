## Создание базы Test в экземпляре по умолчанию (mssql-default)

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/05-create-test-db-default.sql
```