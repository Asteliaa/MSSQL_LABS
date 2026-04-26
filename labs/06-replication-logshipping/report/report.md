# Лабораторная работа №6  
**Тема:** Репликация и доставка журналов (Log Shipping) в Microsoft SQL Server 2012

## Цель работы

Изучить механизмы репликации и доставки журналов в Microsoft SQL Server, рассмотреть варианты сохранности и обмена данными между несколькими серверами, а также practically настроить доставку журналов (log shipping) между двумя экземплярами SQL Server в среде Docker.[file:365][web:479][web:483]

## Оборудование и программное обеспечение

- ОС: Ubuntu / Linux (WSL).  
- Docker и docker-compose.  
- Два контейнера с Microsoft SQL Server 2022 (Developer Edition):  
  - `mssql-default` — основной сервер (primary).  
  - `mssql-named` — дополнительный сервер (secondary).  
- Общий каталог резервных копий, примонтированный к обоим контейнерам: `./backups` → `/var/opt/mssql/backups`.  
- Утилита `sqlcmd` в контейнерах (`/opt/mssql-tools18/bin/sqlcmd`).  
- База данных `Test`, подготовленная в предыдущих лабораторных работах.[web:483][web:482]

---

## Теоретическая часть

### 1. Типы репликации и push‑подписка

SQL Server поддерживает несколько типов репликации, которые применяются в разных сценариях:[web:479][web:487][web:525]

- **Снимковая репликация (Snapshot):**  
  Периодически создаётся полный снимок данных на издателе (Publisher) и переносится на подписчика (Subscriber). Подходит для данных, которые изменяются редко, либо когда подписчику достаточно периодически обновляемой копии.[web:479][web:519]

- **Транзакционная репликация (Transactional):**  
  Использует начальный снимок и затем передаёт изменения из журнала транзакций практически в режиме реального времени. Обеспечивает консистентность и малую задержку для OLTP‑нагрузки (например, заказы, курсы акций).[web:479][web:529]

- **Репликация объединения (Merge):**  
  Позволяет изменять данные как на издателе, так и на подписчиках, а затем объединять изменения. Используется при автономной работе филиалов с последующей синхронизацией.[web:480][web:521]

Для доставки изменений используется набор «агентов репликации» (Snapshot Agent, Log Reader Agent, Distribution Agent и др.), которые выполняют копирование снимков, чтение журнала и распространение изменений.[web:519][web:522]

**Push‑подписка (принудительная подписка)** — это тип подписки, при которой инициатором доставки данных является издатель/распространитель (Publisher/Distributor), а не подписчик. Настройка push‑подписки выполняется на стороне издателя, и Distribution Agent запускается на Distributor и «толкает» изменения к подписчику.[web:466][web:523]

#### Настройка push‑подписки (общая схема по SSMS)

Для репликации между, например, Server1 (заказы) и Client, настройка push‑подписки включает следующие шаги:[web:468][web:466][web:523]

1. **Настройка Distributor:**
   - В SSMS на Server1 открыть узел **Replication** → «Configure Distribution».  
   - Выбрать сервер в роли Distributor, настроить базу distribution и каталог снимков.[web:468]

2. **Создание публикации (Publication):**
   - В SSMS: **Replication → Local Publications → New Publication**.  
   - Выбрать базу данных (например, база заказов).  
   - Выбрать тип репликации (Transactional для постоянной синхронизации).[web:468][web:529]  
   - Выбрать статьи (таблицы и объекты) для репликации.  
   - Указать параметры инициализации (первичный снимок).

3. **Создание push‑подписки:**
   - В SSMS: правый клик по публикации → **New Subscriptions**.  
   - На странице выбора типа подписки указать push‑подписку.  
   - Выбрать подписчика (Client), указать подключение к его экземпляру SQL Server.  
   - Настроить расписание синхронизации (непрерывно или по расписанию, например, каждые 24 часа).[web:466][web:523]  
   - Сохранить настройки — будет автоматически создан Distribution Agent, который будет отправлять изменения на подписчика.

Получившаяся схема обеспечивает автоматическую доставку изменений с Server1 на Client, без участия клиента, что соответствует понятию «принудительная подписка».[web:465][web:466]

---

### 2. Сценарий Server1 / Server2 / Server3 / Client

По условию:[file:365][web:472][web:525]

- **Server1** — база данных о заказах (частые изменения, транзакционная нагрузка).  
- **Server2** — база данных о предприятиях‑поставщиках (справочные данные, изменяются реже).  
- **Server3** — база с онлайн‑данными о курсах акций предприятий.  
- **Client** — получает данные об актуальных заказах и проданных акциях каждые сутки.

Возможные механизмы сохранности и обмена данными:

- **Server1 → Client (заказы):**
  - Транзакционная репликация с push‑подпиской (почти реальное время).[web:529][web:522]  
  - Альтернатива при меньшей частоте — snapshot репликация раз в сутки.

- **Server2 → Client (справочники поставщиков):**
  - Снимковая репликация (Snapshot) раз в сутки или при изменении.[web:479][web:519]  
  - Возможен ETL‑процесс (SSIS) для nightly‑обновлений.

- **Server3 → Client (курсы акций):**
  - Транзакционная репликация для минимальной задержки обновлений.[web:529][web:487]  
  - При меньших требованиях к онлайн‑режиму — периодическая загрузка (ETL) и агрегация.

- **Сохранность данных и отказоустойчивость:**
  - Регулярные full/diff/log backup’ы и проверка восстановления.  
  - Log shipping (настроенный в данной ЛР) как механизм горячего резерва и offload‑нагрузки чтения.[web:483][web:528]  
  - При необходимости — Always On Availability Groups / Mirroring (теоретически, без реализации в Docker).[web:472]

Таким образом, для учебного примера в отчёте можно обосновать, что:

- для оперативных данных (заказы, акции) подходят транзакционная репликация и log shipping;  
- для справочников — snapshot или ETL;  
- для резервирования — backup/restore и log shipping.

---

## Практическая часть: настройка log shipping между двумя экземплярами

В практической части ЛР6 была настроена доставка журналов между двумя контейнерами:

- **Primary:** `mssql-default`, база `Test`.  
- **Secondary:** `mssql-named`, база `Test` (реплика в режиме log shipping).  
- Общий каталог для backup’ов: `/var/opt/mssql/backups` (общий volume `./backups`).[web:483][web:482]

### 3. Подготовка структуры и окружения

На хосте создана структура для ЛР6:

```bash
cd ~/Projects/mssql-lab

mkdir -p labs/06-replication-logshipping/scripts
mkdir -p labs/06-replication-logshipping/report
mkdir -p labs/06-replication-logshipping/screenshots
```

В `docker-compose.yml` уже были определены два сервиса:

- `mssql-default` — основной SQL Server (порт 1433).  
- `mssql-named` — второй экземпляр SQL Server (порт 1434 на хосте → 1433 в контейнере).  

Оба контейнера подключены к общему каталогу `./backups`.[web:483][web:486]

---

### 4. Шаг 1. Подготовка базы Test на primary (mssql-default)

**Цель:** перевести базу `Test` в FULL recovery и создать полную резервную копию для инициализации secondary.[web:475][web:485]

#### 4.1. Скрипт 01-primary-init.sql

Файл `labs/06-replication-logshipping/scripts/01-primary-init.sql`:

```sql
-- 01-primary-init.sql
-- Подготовка базы Test к log shipping на первичном сервере

USE master;
GO

-- Переводим базу в FULL recovery model
ALTER DATABASE Test SET RECOVERY FULL;
GO

-- Гарантируем, что все изменения записаны в журнал
BACKUP LOG Test TO DISK = N'/var/opt/mssql/backups/Test_log_init.trn' WITH INIT;
GO

-- Полный резервный backup базы Test для инициализации secondary
BACKUP DATABASE Test
TO DISK = N'/var/opt/mssql/backups/Test_full_for_logshipping.bak'
WITH INIT, NAME = N'Full backup for log shipping initialization';
GO
```

#### 4.2. Выполнение на mssql-default

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/01-primary-init.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

В выводе `sqlcmd` зафиксирован успешный `BACKUP LOG` и `BACKUP DATABASE` с указанием количества страниц.[web:482][web:485]

*(Скриншот: вывод BACKUP на primary.)*

---

### 5. Шаг 2. Инициализация базы Test на secondary (mssql-named)

**Цель:** восстановить базу `Test` из полного backup’а в состояние `RESTORING`.[web:471][web:483]

#### 5.1. Определение логических имён файлов

Перед восстановлением использовалась команда `RESTORE FILELISTONLY` для определения логических имён файлов в backup’е (например, `testdata_a`, `testdata_b`, `testlog`).[web:491][web:498]

#### 5.2. Скрипт 02-secondary-init.sql

Файл `labs/06-replication-logshipping/scripts/02-secondary-init.sql`:

```sql
-- 02-secondary-init.sql
-- Инициализация базы Test на вторичном сервере для log shipping

USE master;
GO

-- Если база Test уже существует на secondary, удаляем её
IF DB_ID(N'Test') IS NOT NULL
BEGIN
    ALTER DATABASE Test SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Test;
END;
GO

-- Восстанавливаем полную копию из /var/opt/mssql/backups
RESTORE DATABASE Test
FROM DISK = N'/var/opt/mssql/backups/Test_full_for_logshipping.bak'
WITH
    MOVE N'testdata_a' TO N'/var/opt/mssql/data/Test_logship_a.mdf',
    MOVE N'testdata_b' TO N'/var/opt/mssql/data/Test_logship_b.ndf',
    MOVE N'testlog'    TO N'/var/opt/mssql/data/Test_logship_log.ldf',
    NORECOVERY;
GO
```

(Имена `testdata_a`, `testdata_b`, `testlog` соответствуют логическим именам файлов в backup’е.)

#### 5.3. Выполнение на mssql-named

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/02-secondary-init.sql | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

После выполнения:

```bash
echo "SELECT name, state_desc FROM sys.databases WHERE name = 'Test';" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Результат:

- `Test` — `RESTORING`, что соответствует требованиям log shipping.[web:471][web:483]

*(Скриншот: состояние базы Test = RESTORING на secondary.)*

---

### 6. Шаг 3. Настройка log shipping на primary (mssql-default)

**Цель:** зарегистрировать базу `Test` как primary database для log shipping и создать задание backup’а журнала.[web:475][web:490]

#### 6.1. Скрипт 03-logshipping-primary-setup.sql

Файл `labs/06-replication-logshipping/scripts/03-logshipping-primary-setup.sql`:

```sql
-- 03-logshipping-primary-setup.sql
-- Настройка log shipping на первичном сервере для базы Test

USE master;
GO

DECLARE
    @LS_BackupJobId UNIQUEIDENTIFIER,
    @LS_PrimaryId   UNIQUEIDENTIFIER;

EXEC master.dbo.sp_add_log_shipping_primary_database
    @database = N'Test',
    @backup_directory = N'/var/opt/mssql/backups',
    @backup_share = N'/var/opt/mssql/backups',
    @backup_job_name = N'LSBackup_Test',
    @backup_retention_period = 4320,
    @backup_compression = 0,
    @backup_threshold = 60,
    @threshold_alert_enabled = 0,
    @history_retention_period = 5760,
    @backup_job_id = @LS_BackupJobId OUTPUT,
    @primary_id = @LS_PrimaryId OUTPUT,
    @overwrite = 1;
GO
```

#### 6.2. Выполнение на mssql-default

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/03-logshipping-primary-setup.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

#### 6.3. Проверка

```bash
echo "SELECT primary_database, backup_directory 
FROM msdb.dbo.log_shipping_primary_databases 
WHERE primary_database = 'Test';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Вывод содержит строку:

- `primary_database = Test`  
- `backup_directory = /var/opt/mssql/backups`.[web:512]

*(Скриншот: вывод `log_shipping_primary_databases`.)*

---

### 7. Шаг 4. Настройка log shipping на secondary (mssql-named)

**Цель:** зарегистрировать primary‑сервер на secondary и описать базу `Test` как secondary database для log shipping.[web:471][web:485]

#### 7.1. Скрипт 04-logshipping-secondary-setup.sql

Файл `labs/06-replication-logshipping/scripts/04-logshipping-secondary-setup.sql`:

```sql
-- 04-logshipping-secondary-setup.sql
-- Настройка log shipping на вторичном сервере для базы Test

USE master;
GO

DECLARE
    @LS_SecondaryId UNIQUEIDENTIFIER;

--------------------------------------------------
-- 1. Регистрация primary-сервера на secondary
--------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.log_shipping_secondary
    WHERE primary_server = N'mssql-default'
      AND primary_database = N'Test'
)
BEGIN
    EXEC master.dbo.sp_add_log_shipping_secondary_primary
        @primary_server = N'mssql-default',
        @primary_database = N'Test',
        @backup_source_directory = N'/var/opt/mssql/backups',
        @backup_destination_directory = N'/var/opt/mssql/backups',
        @copy_job_name = N'LSCopy_Test',
        @restore_job_name = N'LSRestore_Test',
        @file_retention_period = 4320,
        @monitor_server = NULL,
        @monitor_server_security_mode = 1,
        @secondary_id = @LS_SecondaryId OUTPUT;
END;
GO

--------------------------------------------------
-- 2. Регистрация базы Test как secondary
--------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.log_shipping_secondary_databases
    WHERE secondary_database = N'Test'
)
BEGIN
    EXEC master.dbo.sp_add_log_shipping_secondary_database
        @secondary_database = N'Test',
        @primary_server = N'mssql-default',
        @primary_database = N'Test',
        @restore_delay = 0,
        @restore_mode = 0,          -- 0 = NORECOVERY, 1 = STANDBY
        @disconnect_users = 0,
        @restore_threshold = 60,
        @threshold_alert_enabled = 0,
        @history_retention_period = 5760;
END;
GO
```

#### 7.2. Выполнение на mssql-named

```bash
cd ~/Projects/mssql-lab

cat labs/06-replication-logshipping/scripts/04-logshipping-secondary-setup.sql | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

В выводе были предупреждения `SQLServerAgent is not currently running`, что означает отсутствие автоматического запуска job’ов на secondary (это ожидаемо в Docker), но сами записи log shipping были созданы.[web:483]

#### 7.3. Проверка конфигурации на secondary

Просмотр связки primary–secondary:

```bash
echo "SELECT primary_server, primary_database
FROM msdb.dbo.log_shipping_secondary;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Результат:

- `primary_server = MSSQL-DEFAULT`  
- `primary_database = Test`.

Просмотр настроек базы `Test`:

```bash
echo "SELECT secondary_database, restore_mode, restore_delay
FROM msdb.dbo.log_shipping_secondary_databases
WHERE secondary_database = 'Test';" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

Результат:

- `secondary_database = Test`, `restore_mode = 0`, `restore_delay = 0`.[web:504][web:515]

*(Скриншоты: вывод обеих команд.)*

---

### 8. Шаг 5. Практическая демонстрация доставки журнала

Поскольку SQL Server Agent на secondary не запущен автоматически, демонстрация log shipping была выполнена в ручном режиме:  
BACKUP LOG на primary → RESTORE LOG на secondary → проверка данных.[web:483][web:482]

#### 8.1. Создание тестовой таблицы и записи на primary

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test << 'EOF'
IF OBJECT_ID('dbo.LogShipDemo', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.LogShipDemo
    (
        Id        INT IDENTITY(1,1) PRIMARY KEY,
        Info      NVARCHAR(100),
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO

INSERT INTO dbo.LogShipDemo(Info) 
VALUES (N'Первая запись для проверки log shipping');
GO
EOF
```

Проверка на primary:

```bash
echo "SELECT * FROM dbo.LogShipDemo;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test
```

*(Скриншот: одна запись в LogShipDemo на primary.)*

#### 8.2. Резервное копирование журнала на primary

```bash
echo "BACKUP LOG Test
TO DISK = N'/var/opt/mssql/backups/Test_log_manual_1.trn'
WITH INIT, NAME = N'Log backup for manual log shipping test';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Создан файл `Test_log_manual_1.trn` в общей папке `/var/opt/mssql/backups`.[web:482][web:485]

#### 8.3. Восстановление журнала на secondary

```bash
echo "RESTORE LOG Test
FROM DISK = N'/var/opt/mssql/backups/Test_log_manual_1.trn'
WITH NORECOVERY;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

В выводе видно, что для базы `Test` обработано 18 страниц файла `testlog`.[web:482]

#### 8.4. Завершение восстановления базы на secondary

Чтобы иметь возможность читать данные, база `Test` на secondary была переведена из RESTORING в ONLINE:

```bash
echo "RESTORE DATABASE Test WITH RECOVERY;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C
```

#### 8.5. Проверка данных на secondary

После завершения восстановления:

```bash
echo "SELECT * FROM dbo.LogShipDemo;" | \
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost,1433 -U SA -P "Strong_Passw0rd!" -C -d Test
```

Результат:

- в таблице `LogShipDemo` на secondary присутствует запись  
  `Первая запись для проверки log shipping` с тем же временем создания, что и на primary.

Это подтверждает, что изменения, выполненные в базе `Test` на primary, были зафиксированы в журнале транзакций, сохранены в файл backup журнала и успешно применены на secondary при помощи `RESTORE LOG`.[web:482][web:483][web:485]

*(Скриншот: SELECT из LogShipDemo на secondary.)*

---

## Выводы

В ходе лабораторной работы №6 были получены следующие результаты:

1. Изучены основные **типы репликации** SQL Server (snapshot, transactional, merge), их особенности и области применения, а также понятие push‑подписки и общая схема её настройки через мастера SSMS.[web:479][web:525][web:466]  
2. Рассмотрен сценарий с тремя серверами (заказы, поставщики, курсы акций) и клиентом, обоснован выбор механизмов: транзакционная и снимковая репликация, ETL‑процессы, log shipping и резервное копирование для обеспечения сохранности и актуальности данных.[web:472][web:487]  
3. В среде Docker настроен **log shipping** между двумя экземплярами SQL Server (`mssql-default` и `mssql-named`): выполнена инициализация базы `Test` на secondary, зарегистрированы primary и secondary базы в системных таблицах `msdb` с помощью стандартных процедур `sp_add_log_shipping_primary_database`, `sp_add_log_shipping_secondary_primary`, `sp_add_log_shipping_secondary_database`.[web:483][web:490][web:511]  
4. Практически продемонстрировано, что изменения на primary‑сервере доставляются на secondary посредством backup’а журнала и операции `RESTORE LOG`, что было подтверждено совпадающими данными в таблице `dbo.LogShipDemo` на обоих серверах.[web:482][web:485]  
5. Отмечено, что в Docker SQL Server Agent на вторичном сервере не запускался автоматически, поэтому процесс log shipping был продемонстрирован в ручном режиме, что, тем не менее, полностью отражает механизм доставки журналов, описанный в лекционном материале и документации.[web:483][web:524]

Полученные знания и навыки позволяют использовать механизмы репликации и log shipping для построения отказоустойчивых и масштабируемых решений на базе Microsoft SQL Server.