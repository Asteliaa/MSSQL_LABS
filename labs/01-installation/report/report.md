# Lab 01 — Installation

## Цель
Развернуть два экземпляра SQL Server в Docker и подключиться к ним.

## Содержимое
- `report/` — оформленный отчёт
- `commands/` — журнал команд
- `scripts/` — SQL-скрипты
- `screenshots/` — скриншоты

## 0 Адаптация под Docker

Поскольку лабораторная раобта выполняется в среде Docker, то ее элементы будут иметь следующий вид:
- VM1 → твоя хост‑машина + docker-compose.yml.
- Экземпляр по умолчанию → контейнер №1, порт 1433.
- Именованный экземпляр → контейнер №2, другой порт (например, 1434).
- Управление старт/стоп → docker compose up/stop вместо сервис‑панели, а подключение – через SSMS 127.0.0.1,порт

## 1. Структура лабораторной

Работаем в labs/01-installation/:
- commands/01-docker-setup.md — команды Docker/compose.
- commands/02-ssms-connections.md — как подключалась, какие строки серверов.
- commands/03-sql-checks.sql — запросы проверки версии и баз.
- report/report.md — оформленный отчёт.

## 2. VM1

### 2.1 docker-compose.yml

Создадим файл docker-compose.yml

``` bash
version: '3.8'

services:
  mssql_default:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: mssql-default
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Strong_Passw0rd!
      - MSSQL_PID=Developer
    ports:
      - "1433:1433"
    volumes:
      - mssql-default-data:/var/opt/mssql
    restart: unless-stopped

  mssql_named:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: mssql-named
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Strong_Passw0rd!
      - MSSQL_PID=Developer
    ports:
      - "1434:1433"
    volumes:
      - mssql-named-data:/var/opt/mssql
    restart: unless-stopped

volumes:
  mssql-default-data:
  mssql-named-data:
```

Где: (расписать по компонентам)


![Компьютер](screenshots/create_containers.png "Cоздание контейнеров")