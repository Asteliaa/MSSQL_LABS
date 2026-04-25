# Создание схем и таблиц в базах Test и RZ_DB

```bash
cd docker

# Часть, относящаяся к базе Test
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/07-create-tables-and-schemas.sql
```

При выполнении скрипта будут обработаны как база `Test`, так и `RZ_DB` (внутри есть `USE Test;` и `USE RZ_DB;`).