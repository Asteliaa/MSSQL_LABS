## Подключение к экземпляру mssql-named

```bash
docker exec -it mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```