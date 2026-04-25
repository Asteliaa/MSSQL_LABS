## Остановка и запуск экземпляра mssql-default

```bash
cd docker

# Останавливаем контейнер с экземпляром по умолчанию
docker compose stop mssql_default
docker compose ps

# Запускаем контейнер снова
docker compose start mssql_default
docker compose ps

cd ..
```