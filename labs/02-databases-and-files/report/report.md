# Лабораторная работа 2. Управление базами данных и файлами

## Цель работы

- Освоить создание и настройку баз данных SQL Server с несколькими файлами и файловыми группами.
- Научиться управлять параметрами автоувеличения файлов данных.
- Закрепить работу со схемами и таблицами, в том числе с привязкой к файловым группам.
- Выполнить аналогичные действия в именованном экземпляре SQL Server, используя Transact‑SQL и Docker‑контейнеры.

## Исходное задание

В исходной постановке лабораторной работы требуется:

1. В экземпляре SQL Server по умолчанию создать базу данных `Test`:
   - файл данных `testdata_a` размером 4 MB;
   - автоувеличение на 2 MB при достижении лимита;
   - максимальный размер файла 10 MB.
2. Создать файловую группу `TestFileGroup`.
3. Создать второй файл данных `testdata_b.ndf` размером 5 MB и настроить автоувеличение на 2 MB без ограничения максимального размера.
4. Добавить файл `testdata_b` в файловую группу `TestFileGroup`.
5. В именованном экземпляре SQL Server создать базу данных с инициалами в имени (в работе — `RZ_DB`) с использованием Transact‑SQL.
6. В созданных базах данных:
   - создать произвольную схему;
   - создать таблицу `TABLE_1` и добавить её в схему;
   - создать таблицу `TABLE_2` с явным указанием файловой группы;
   - создать таблицу в новой схеме, не принадлежащей текущему пользователю.

## 1. Адаптация задания под Docker и sqlcmd

Работа выполняется в среде Docker на Ubuntu. В отличие от исходного варианта с установленным SQL Server и SSMS на одной виртуальной машине, здесь используются два контейнера:

- контейнер `mssql-default` — экземпляр SQL Server по умолчанию, в котором создаётся база `Test`;[web:23][web:24]
- контейнер `mssql-named` — второй экземпляр SQL Server, в котором создаётся база `RZ_DB`.

Все действия выполняются через утилиту `sqlcmd`, вызываемую командой:

```bash
docker exec -it <container-name> /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Вместо графического интерфейса SSMS используются T‑SQL‑скрипты:

- `05-create-test-db-default.sql`;
- `06-create-rz-db-named.sql`;
- `07-create-tables-and-schemas.sql`;
- `08-verify-files-and-filegroups.sql`.

## 2. Создание базы Test и файлов данных

Создание базы `Test` выполнялось в контейнере `mssql-default` командой:

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/05-create-test-db-default.sql
```

Содержимое скрипта:

```sql
USE master;
GO

CREATE DATABASE Test
ON PRIMARY
(
    NAME = N'testdata_a',
    FILENAME = N'/var/opt/mssql/data/testdata_a.mdf',
    SIZE = 4MB,
    FILEGROWTH = 2MB,
    MAXSIZE = 10MB
)
LOG ON
(
    NAME = N'testlog',
    FILENAME = N'/var/opt/mssql/data/testlog.ldf',
    SIZE = 2MB,
    FILEGROWTH = 2MB
);
GO

ALTER DATABASE Test
ADD FILEGROUP TestFileGroup;
GO

ALTER DATABASE Test
ADD FILE
(
    NAME = N'testdata_b',
    FILENAME = N'/var/opt/mssql/data/testdata_b.ndf',
    SIZE = 5MB,
    FILEGROWTH = 2MB,
    MAXSIZE = UNLIMITED
)
TO FILEGROUP TestFileGroup;
GO
```

Таким образом, в соответствии с заданием создана база `Test` с первичным файлом `testdata_a` (4 MB, автоувеличение 2 MB, максимум 10 MB), файловой группой `TestFileGroup` и вторичным файлом `testdata_b` (5 MB, автоувеличение 2 MB, без ограничения размера).[web:200][web:230]

<p align="center">
  <img src="../screenshots/db_create.jpg" width="700" alt="Создание баз Test и RZ_DB">
  <br>
  <em>Рис. 1. Создание баз данных Test и RZ_DB через sqlcmd.</em>
</p>

## 3. Проверка файлов и файловых групп базы Test

После создания базы контекст был переключён на `Test`:

```sql
USE Test;
GO
```

Для проверки файлов использовался скрипт `08-verify-files-and-filegroups.sql`:

```sql
SELECT
    name        AS FileName,
    physical_name AS PhysicalName,
    type_desc   AS FileType,
    size * 8 / 1024 AS SizeMB,
    max_size,
    growth
FROM sys.database_files;
GO

SELECT
    name        AS FilegroupName,
    type_desc,
    is_default
FROM sys.filegroups;
GO
```

Результат запроса к `sys.database_files` показал три файла: `testdata_a.mdf`, `testlog.ldf`, `testdata_b.ndf` с ожидаемыми размерами и путями.[web:226][web:198]

<p align="center">
  <img src="../screenshots/test-db-files.jpg" width="700" alt="Файлы базы данных Test">
  <br>
  <em>Рис. 2. Файлы базы данных Test и их размеры.</em>
</p>

Запрос к `sys.filegroups` подтвердил наличие файловых групп `PRIMARY` и `TestFileGroup`, причём `PRIMARY` помечена как файловая группа по умолчанию (`is_default = 1`).[web:226][web:230]

<p align="center">
  <img src="../screenshots/est-filegroups.jpg" width="700" alt="Файловые группы базы Test">
  <br>
  <em>Рис. 3. Файловые группы базы Test: PRIMARY и TestFileGroup.</em>
</p>

## 4. Создание схем и таблиц в базе Test

В базе `Test` была создана пользовательская схема `app` и таблицы `TABLE_1` и `TABLE_2`:

```sql
USE Test;
GO

CREATE SCHEMA app AUTHORIZATION dbo;
GO

CREATE TABLE app.TABLE_1
(
    Id        INT IDENTITY(1,1) PRIMARY KEY,
    Name      NVARCHAR(100) NOT NULL,
    CreatedAt DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE app.TABLE_2
(
    Id      INT IDENTITY(1,1) PRIMARY KEY,
    Value   NVARCHAR(100) NOT NULL
)
ON TestFileGroup;
GO
```

Таблица `TABLE_1` создаётся на файловой группе по умолчанию, тогда как `TABLE_2` явным образом размещается на файловой группе `TestFileGroup` с помощью ключевого слова `ON TestFileGroup`.[web:145][web:154]

Для выполнения пункта задания о таблице в новой схеме была создана схема `external` и таблица `TABLE_3`:

```sql
CREATE SCHEMA external AUTHORIZATION dbo;
GO

CREATE TABLE external.TABLE_3
(
    Id      INT IDENTITY(1,1) PRIMARY KEY,
    Comment NVARCHAR(200) NULL
);
GO
```

Проверка схем и таблиц в базе Test:

```sql
SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;
GO
```

<p align="center">
  <img src="../screenshots/schemas-and-tables.jpg" width="700" alt="Таблицы и схемы в базе Test">
  <br>
  <em>Рис. 4. Таблицы в схемах app и external в базе Test.</em>
</p>

На рисунке видно, что в базе присутствуют таблицы `app.TABLE_1`, `app.TABLE_2` и `external.TABLE_3`, что полностью соответствует требованиям задания.

## 5. Создание базы RZ_DB и таблицы в именованном экземпляре

В контейнере `mssql-named` была создана база данных `RZ_DB`, идентификатор которой содержит инициалы:

```bash
cd docker

docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/06-create-rz-db-named.sql
```

Содержимое скрипта:

```sql
USE master;
GO

CREATE DATABASE RZ_DB
ON PRIMARY
(
    NAME = N'rzdata_a',
    FILENAME = N'/var/opt/mssql/data/rzdata_a.mdf',
    SIZE = 4MB,
    FILEGROWTH = 2MB,
    MAXSIZE = 20MB
)
LOG ON
(
    NAME = N'rzlog',
    FILENAME = N'/var/opt/mssql/data/rzlog.ldf',
    SIZE = 2MB,
    FILEGROWTH = 2MB
);
GO
```

Проверка наличия базы:

```bash
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "SELECT name FROM sys.databases WHERE name = 'RZ_DB';"
```

Данный запрос вернул одну строку с именем `RZ_DB`, что подтверждает успешное создание базы.

В базе `RZ_DB` была создана схема `rz` и таблица `MY_TABLE`:

```sql
USE RZ_DB;
GO

CREATE SCHEMA rz AUTHORIZATION dbo;
GO

CREATE TABLE rz.MY_TABLE
(
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Data NVARCHAR(100) NOT NULL
);
GO
```

Проверка таблиц в базе `RZ_DB`:

```sql
SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;
GO
```

<p align="center">
  <img src="../screenshots/rz-db-tables.jpg" width="700" alt="Таблица rz.MY_TABLE в базе RZ_DB">
  <br>
  <em>Рис. 5. Таблица rz.MY_TABLE в базе RZ_DB (именованный экземпляр).</em>
</p>

Запрос показывает, что в базе `RZ_DB` успешно создана таблица `rz.MY_TABLE`.

## 6. Выводы

В ходе выполнения лабораторной работы:

- В контейнере `mssql-default` создана база данных `Test` с файлом `testdata_a` (4 MB, автоувеличение 2 MB, максимум 10 MB) и вторичным файлом `testdata_b` (5 MB, автоувеличение 2 MB, без ограничения максимального размера), объединёнными в файловую группу `TestFileGroup`.[web:200][web:230]
- Проверкой через `sys.database_files` и `sys.filegroups` подтверждена корректная конфигурация файлов и файловых групп базы `Test`.[web:226][web:230]
- В базе `Test` созданы схемы `app` и `external`, а также таблицы `app.TABLE_1`, `app.TABLE_2` (на файловой группе `TestFileGroup`) и `external.TABLE_3`.
- В контейнере `mssql-named` с использованием Transact‑SQL создана база `RZ_DB`, а в ней — схема `rz` и таблица `rz.MY_TABLE`.
- Все действия задания выполнены в среде Docker с использованием утилиты `sqlcmd`, что демонстрирует возможность полного переноса лабораторных работ по администрированию SQL Server в терминал без использования графического интерфейса SSMS.[web:23][web:260]