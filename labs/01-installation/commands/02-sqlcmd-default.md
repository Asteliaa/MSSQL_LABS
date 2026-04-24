# Подключение к экземпляру по умолчанию (mssql-default)

```bash
docker exec -it mssql-default /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!"
```

Выполненные запросы:

```sql
:r /var/opt/mssql/03-sql-checks.sql
```