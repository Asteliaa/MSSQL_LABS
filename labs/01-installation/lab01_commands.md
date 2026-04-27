# Lab 01 — Commands

## Start both SQL Server containers

```bash
cd docker

docker compose up -d
docker compose ps

docker logs mssql-default | head
docker logs mssql-named  | head

cd ..
```

## Connect to default instance (mssql-default)

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

## Connect to named instance (mssql-named)

```bash
docker exec -it mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

## Stop and start default instance

```bash
cd docker

docker compose stop mssql_default
docker compose ps

docker compose start mssql_default
docker compose ps

cd ..
```