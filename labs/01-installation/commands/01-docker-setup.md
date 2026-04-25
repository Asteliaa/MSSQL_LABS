## Поднимаем два контейнера SQL Server
## mssql-default  -> экземпляр по умолчанию
## mssql-named    -> второй экземпляр
## Порты: 1433 и 1434 соответственно
## Проверяем, что контейнеры запущены
## Просматриваем начальные строки логов контейнеров

```bash
cd docker

docker compose up -d
docker compose ps

docker logs mssql-default | head
docker logs mssql-named  | head
s
cd ..

```