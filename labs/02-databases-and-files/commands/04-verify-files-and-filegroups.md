# Проверка файлов, файловых групп и таблиц в базе Test

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/08-verify-files-and-filegroups.sql
```

