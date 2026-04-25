# Лабораторная работа 1. Установка Microsoft SQL Server в Docker (Ubuntu)

## Цель работы

- Развернуть два экземпляра Microsoft SQL Server в контейнерах Docker.
- Освоить подключение к экземплярам через утилиту `sqlcmd`.
- Получить базовую информацию о версии сервера, свойствах экземпляра и системных базах данных.
- Научиться останавливать и запускать экземпляры SQL Server с помощью Docker.

## Постановка задания

Исходное задание лабораторной работы формулируется следующим образом:

- Создать виртуальную машину VM1 в Hyper-V.
- Конфигурация VM1: 1 CPU, 1024 MB RAM, 30 GB HDD, Windows Server 2012.
- Установить один экземпляр Microsoft SQL Server 2012 Database по умолчанию на VM1.
- Ознакомиться с основным интерфейсом для работы с SQL Server на основе утилиты Management Studio.
- Просмотреть основные свойства экземпляра сервера.
- Произвести остановку и запуск сервера.
- Установить второй (именованный) экземпляр сервера баз данных.
- Настроить второй экземпляр SQL Server для подключения через определённый порт.

## Адаптация задания под Docker

Так как лабораторная работа выполнялась полностью в терминале Ubuntu и в Docker, задание было адаптировано следующим образом:

- виртуальная машина VM1 заменена на хост-машину Ubuntu с Docker;
- экземпляр по умолчанию реализован как контейнер `mssql-default`, использующий порт `1433`;
- второй экземпляр реализован как контейнер `mssql-named`, использующий порт `1434` на хосте;
- вместо графической утилиты SQL Server Management Studio использована консольная утилита `sqlcmd`;
- остановка и запуск сервера выполнялись командами Docker.

## Подготовка конфигурации Docker

Для выполнения лабораторной работы был создан файл `docker/docker-compose.yml` со следующим содержимым:

```yaml
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

### Пояснение по компонентам

- `image` — образ SQL Server, на основе которого создаётся контейнер.
- `container_name` — имя контейнера, используемое для обращения через `docker exec`.
- `ACCEPT_EULA=Y` — подтверждение лицензионного соглашения.
- `SA_PASSWORD` — пароль администратора `sa`.
- `MSSQL_PID=Developer` — редакция Developer для учебной среды.
- `ports` — проброс портов контейнера на хост-машину.
- `volumes` — тома для хранения данных SQL Server.
- `restart: unless-stopped` — автоматический перезапуск контейнера, если он был остановлен не вручную.

## Запуск контейнеров

Контейнеры SQL Server запускались следующими командами:

```bash
cd docker
docker compose up -d
docker compose ps
docker logs mssql-default | head
docker logs mssql-named  | head
cd ..
```

После запуска оба контейнера должны находиться в состоянии `Up`.

![Запуск контейнеров SQL Server](../screenshots/docker compose up -d.png)

![Проверка состояния контейнеров](../screenshots/docker compose ps.png)

## Подключение к экземпляру по умолчанию

Для подключения к контейнеру `mssql-default` использовалась утилита `sqlcmd` из пакета `mssql-tools18`. Поскольку ODBC Driver 18 по умолчанию требует шифрование и проверку сертификата, в команде используется флаг `-C`, разрешающий доверять сертификату сервера.

Команда подключения:

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

После подключения выполнялся SQL-скрипт:

```sql
SELECT @@SERVERNAME AS ServerName, @@VERSION AS VersionInfo;
GO

SELECT name FROM sys.databases;
GO

SELECT
    SERVERPROPERTY('ServerName') AS ServerName,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('ProductLevel') AS ProductLevel;
GO

SELECT
    DB_NAME(database_id) AS DatabaseName,
    name AS LogicalName,
    physical_name
FROM sys.master_files
WHERE DB_NAME(database_id) = 'master';
GO
```

### Результаты проверки

В ходе выполнения запросов было установлено:

- сервер работает на Microsoft SQL Server 2022 Developer Edition;
- SQL Server развёрнут в Linux-контейнере на базе Ubuntu;
- системные базы данных `master`, `tempdb`, `model`, `msdb` присутствуют;
- у базы `master` определяются логическое имя и физический путь файлов.

## Работа в интерактивном режиме sqlcmd

В процессе лабораторной работы были отработаны следующие действия в `sqlcmd`:

- запуск подключения к экземпляру;
- выполнение SQL-команд;
- завершение блока команд оператором `GO`;
- просмотр результатов в текстовом виде;
- выход из интерактивного режима.

Таким образом, `sqlcmd` использовался как консольный аналог работы с SQL Server в среде без графического интерфейса.

## Остановка и запуск экземпляра по умолчанию

Для проверки управления сервером использовались следующие команды:

```bash
cd docker
docker compose stop mssql_default
docker compose ps
docker compose start mssql_default
docker compose ps
cd ..
```

После остановки контейнера попытка повторного подключения через `sqlcmd` становилась невозможной. После повторного запуска контейнера экземпляр снова был доступен для подключения.

## Подключение ко второму экземпляру

Для второго контейнера `mssql-named` использовалась аналогичная команда:

```bash
docker exec -it mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

После подключения выполнялся тот же SQL-скрипт проверки, что и для `mssql-default`. Это позволило убедиться, что второй экземпляр также развёрнут и доступен для работы.

## Выводы

В результате выполнения лабораторной работы были развёрнуты два экземпляра Microsoft SQL Server в Docker, соответствующие экземпляру по умолчанию и второму именованному экземпляру из исходного задания. Было выполнено подключение к каждому экземпляру через `sqlcmd`, проверена версия SQL Server, список системных баз данных и базовые свойства экземпляра.

Кроме того, были отработаны действия по остановке и повторному запуску контейнера с экземпляром по умолчанию. Таким образом, первая лабораторная работа была успешно адаптирована под среду Ubuntu + Docker и выполнена полностью в терминале.