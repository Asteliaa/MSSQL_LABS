# Настройка окружения MSSQL Lab (Ubuntu + Docker)

Документ описывает единый, воспроизводимый способ подготовки окружения для лабораторных работ по администрированию Microsoft SQL Server. Исходные задания ориентированы на Hyper-V, Windows Server и SSMS, но в этом проекте они выполняются на Ubuntu через Docker и sqlcmd.

## Цель

Подготовить рабочее окружение, в котором можно линейно выполнять лабораторные работы, хранить команды и скрипты в Git и при необходимости быстро восстановить состояние контейнеров SQL Server.

## Что используется

- Ubuntu Linux.
- Docker Engine и Docker Compose Plugin.
- Git.
- Visual Studio Code.
- Два контейнера SQL Server 2022 Developer:
	- `mssql-default` на порту `1433`.
	- `mssql-named` на порту `1434`.

## Быстрая проверка prerequisites

```bash
docker --version
docker compose version
git --version
code --version
```

Если `docker` запускается только через `sudo`, добавь пользователя в группу `docker` и перезайди в сессию:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

## Подготовка проекта

Если репозиторий уже клонирован, просто открой его в VS Code. Если нет:

```bash
git clone https://github.com/USERNAME/mssql-lab.git
cd mssql-lab
code .
```

## Конфигурация Docker

В проекте используется простой `docker/docker-compose.yml` с двумя экземплярами SQL Server:

- `mssql-default` на `1433`.
- `mssql-named` на `1434`.

Для учебной работы этого достаточно и не требует дополнительной подготовки `.env`.

## Запуск окружения

```bash
cd docker
docker compose up -d
docker compose ps
```

Ожидаемый результат:

- запущены контейнеры `mssql-default` и `mssql-named`;
- порты проброшены как `1433->1433` и `1434->1433`.

## Проверка готовности SQL Server

Проверь, что серверы принимают подключения, выполнив простой запрос в каждом контейнере:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
	-S localhost -U SA -P "Strong_Passw0rd!" -C \
	-Q "SELECT @@SERVERNAME AS server_name, @@VERSION AS version_info;"

docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
	-S localhost -U SA -P "Strong_Passw0rd!" -C \
	-Q "SELECT @@SERVERNAME AS server_name, @@VERSION AS version_info;"
```

## Проверка каталога резервных копий

В проекте каталог `docker/backups/` смонтирован в оба контейнера по пути `/var/opt/mssql/backups`. Это нужно для лабораторных по backup/restore.

Проверка:

```bash
ls -la ./backups
docker exec -i mssql-default ls -la /var/opt/mssql/backups
```

## Базовые операции управления контейнерами

```bash
cd docker

# остановить только default экземпляр
docker compose stop mssql_default

# запустить снова
docker compose start mssql_default

# остановить все контейнеры
docker compose down

# поднять снова
docker compose up -d
```

## Типовые проблемы и диагностика

1. Ошибка логина `Login failed for user 'SA'`.
Проверь пароль в `docker/docker-compose.yml`, затем перезапусти контейнеры.

2. Порт `1433` или `1434` занят.
Измени проброс портов в `docker/docker-compose.yml` и снова запусти `docker compose up -d`.

3. Контейнер долго стартует после первого запуска.
Проверь логи:

```bash
docker logs mssql-default | tail -n 50
docker logs mssql-named | tail -n 50
```

4. Команда `docker exec ... sqlcmd` не найдена.
Убедись, что используешь путь `/opt/mssql-tools18/bin/sqlcmd` внутри контейнера.

## Definition of Done для окружения

Окружение считается готовым, если:

1. `docker compose ps` показывает оба контейнера в состоянии Up.
2. Запрос `SELECT @@VERSION` выполняется в `mssql-default` и `mssql-named`.
3. Каталог `/var/opt/mssql/backups` доступен внутри контейнеров.
4. Ты можешь остановить и снова запустить любой экземпляр через `docker compose stop/start`.

После этого можно переходить к лабораторным сценариям из `labs/`.