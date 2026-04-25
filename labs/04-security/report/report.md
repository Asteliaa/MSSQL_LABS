# Лабораторная работа 4. Управление безопасностью

## Цель работы

- Освоить управление безопасностью в Microsoft SQL Server на уровне логинов, пользователей и ролей.
- Научиться создавать логины с аутентификацией SQL Server и связывать их с пользователями базы данных.
- Практически применить пользовательские роли, ограничения и запреты доступа к объектам.
- Закрепить работу с Transact‑SQL и утилитой `sqlcmd` в Docker‑среде.

## 1. Стенд и исходные данные

Работа выполнялась в Docker‑среде на основе контейнера `mssql-default`, содержащего базу данных `Test`, созданную в предыдущих лабораторных работах.[web:23] Подключение выполнялось через утилиту `sqlcmd` под логином `SA`:

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Режим проверки подлинности сервера в Docker‑образе SQL Server настроен как смешанный (Windows + SQL Server Authentication), что позволяет использовать логины SQL Server (`TestLogin1`, `TestLogin2`).[web:286][web:292]

Для выполнения задания были подготовлены T‑SQL‑скрипты в каталоге `labs/04-security-management/scripts/`:

- `05-logins-and-users.sql`
- `06-roles-and-permissions.sql`
- `07-schema-and-table-for-testuser1.sql`
- `08-manager-users-and-deny-select.sql`

Они запускались через `sqlcmd` внутри контейнера.

## 2. Логины TestLogin1, TestLogin2 и пользователи TestUser1, TestUser2

### 2.1. Создание логина TestLogin1 и добавление в роль sysadmin

Скрипт `05-logins-and-users.sql` (фрагмент ниже) создаёт логин `TestLogin1` с аутентификацией SQL Server, отключённой проверкой сложности пароля и добавляет его в серверную роль `sysadmin`, а также устанавливает базу `Test` как базу по умолчанию:[web:284][web:287][web:291]

```sql
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'TestLogin1')
BEGIN
    CREATE LOGIN TestLogin1
    WITH PASSWORD = N'Strong_T3stLogin1!',
         CHECK_POLICY = OFF;
END;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER TestLogin1;
GO

ALTER LOGIN TestLogin1
WITH DEFAULT_DATABASE = Test;
GO
```

Скрипт запускался командой:

```bash
cd ~/Projects/mssql-lab/docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/05-logins-and-users.sql
```

После выполнения в `sys.server_principals` появился логин `TestLogin1`, а в `sys.server_role_members` появилась запись о его членстве в роли `sysadmin`.[web:285]

<p align="center">
  <img src="../screenshots/lab4-testlogin1-sysadmin.png" width="700" alt="Создание TestLogin1 и назначение в sysadmin">
  <br>
  <em>Рис. 1. Логин TestLogin1 создан и добавлен в роль sysadmin.</em>
</p>

### 2.2. Логин TestLogin2 и пользователи базы Test

В этом же скрипте создан логин `TestLogin2` и пользователи `TestUser1`, `TestUser2` в базе `Test`:[web:284][web:292]

```sql
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'TestLogin2')
BEGIN
    CREATE LOGIN TestLogin2
    WITH PASSWORD = N'Strong_T3stLogin2!',
         CHECK_POLICY = OFF;
END;
GO

USE Test;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'TestUser1')
BEGIN
    CREATE USER TestUser1 FOR LOGIN TestLogin1;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'TestUser2')
BEGIN
    CREATE USER TestUser2 FOR LOGIN TestLogin2;
END;
GO
```

Проверка:

```sql
USE Test;
GO

SELECT name, type_desc
FROM sys.database_principals
WHERE name IN ('TestUser1','TestUser2');
GO
```

<p align="center">
  <img src="../screenshots/lab4-testusers-created.png" width="700" alt="Созданные пользователи TestUser1 и TestUser2">
  <br>
  <em>Рис. 2. Пользователи TestUser1 и TestUser2 в базе Test.</em>
</p>

## 3. Пользовательские роли Manager, Employee и NoUpdate

### 3.1. Создание ролей и назначение пользователям

В скрипте `06-roles-and-permissions.sql` были созданы роли `Manager`, `Employee`, `NoUpdate` и выполнено назначение ролей пользователям:[web:288][web:292]

```sql
USE Test;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Manager' AND type = 'R')
BEGIN
    CREATE ROLE Manager;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Employee' AND type = 'R')
BEGIN
    CREATE ROLE Employee;
END;
GO

ALTER ROLE Manager ADD MEMBER TestUser1;
GO

ALTER ROLE Employee ADD MEMBER TestUser2;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'NoUpdate' AND type = 'R')
BEGIN
    CREATE ROLE NoUpdate;
END;
GO

DENY UPDATE TO NoUpdate;
GO
```

Запуск:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/06-roles-and-permissions.sql
```

Проверка состава ролей:

```sql
USE Test;
GO

SELECT
    r.name AS RoleName,
    m.name AS MemberName
FROM sys.database_role_members drm
JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
WHERE r.name IN ('Manager','Employee','NoUpdate');
GO
```

### 3.2. Запрет изменения пользователя guest для Employee

Там же реализован запрет `ALTER` для пользователя `guest` для роли `Employee`:[web:288]

```sql
DENY ALTER ON USER::guest TO Employee;
GO
```

<p align="center">
  <img src="../screenshots/lab4-roles-and-deny-guest.png" width="700" alt="Роли и запрет изменения guest">
  <br>
  <em>Рис. 3. Роли Manager, Employee и запрет на изменение пользователя guest.</em>
</p>

## 4. Новая схема и таблица для TestUser1 (п.4.1)

Скрипт `07-schema-and-table-for-testuser1.sql` создаёт схему `mgr` с владельцем `TestUser1` и таблицу `mgr.Orders`:[web:292]

```sql
USE Test;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'mgr')
BEGIN
    EXEC('CREATE SCHEMA mgr AUTHORIZATION TestUser1;');
END;
GO

IF OBJECT_ID(N'mgr.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE mgr.Orders
    (
        OrderId   INT IDENTITY(1,1) PRIMARY KEY,
        OrderDate DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
        Amount    DECIMAL(10,2) NOT NULL
    );
END;
GO
```

Запуск:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/07-schema-and-table-for-testuser1.sql
```

Проверка:

```sql
USE Test;
GO

SELECT s.name AS SchemaName, t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'mgr';
GO
```

<p align="center">
  <img src="../screenshots/lab4-mgr-orders.png" width="700" alt="Таблица mgr.Orders в новой схеме">
  <br>
  <em>Рис. 4. Таблица mgr.Orders в схеме mgr, принадлежащей TestUser1.</em>
</p>

## 5. Пользователи User1, User2 и запрет SELECT из mgr.Orders (п.4.2)

### 5.1. Создание логинов и пользователей

Скрипт `08-manager-users-and-deny-select.sql` создаёт логины `User1Login`, `User2Login`, пользователей `User1`, `User2` в базе `Test` и добавляет их в роль `Manager`:[web:284][web:292]

```sql
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'User1Login')
BEGIN
    CREATE LOGIN User1Login
    WITH PASSWORD = N'Strong_Us3r1!',
         CHECK_POLICY = OFF;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'User2Login')
BEGIN
    CREATE LOGIN User2Login
    WITH PASSWORD = N'Strong_Us3r2!',
         CHECK_POLICY = OFF;
END;
GO

USE Test;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'User1')
BEGIN
    CREATE USER User1 FOR LOGIN User1Login;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'User2')
BEGIN
    CREATE USER User2 FOR LOGIN User2Login;
END;
GO

ALTER ROLE Manager ADD MEMBER User1;
GO

ALTER ROLE Manager ADD MEMBER User2;
GO
```

Запуск:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/08-manager-users-and-deny-select.sql
```

### 5.2. Запрет SELECT несколькими способами

#### Способ 1: прямой DENY SELECT

В скрипте выполнены прямые запреты SELECT для пользователей `User1` и `User2`:[web:288]

```sql
DENY SELECT ON OBJECT::mgr.Orders TO User1;
GO

DENY SELECT ON OBJECT::mgr.Orders TO User2;
GO
```

#### Способ 2: роль с запретом SELECT

Также создана роль `NoSelectMgrOrders`:

```sql
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'NoSelectMgrOrders' AND type = 'R')
BEGIN
    CREATE ROLE NoSelectMgrOrders;
END;
GO

DENY SELECT ON OBJECT::mgr.Orders TO NoSelectMgrOrders;
GO

ALTER ROLE NoSelectMgrOrders ADD MEMBER User1;
GO

ALTER ROLE NoSelectMgrOrders ADD MEMBER User2;
GO
```

Таким образом, запрет получается продублирован:
- прямой `DENY` на пользователей;
- `DENY` на роль, в которую они включены.

### 5.3. Проверка запрета SELECT под User1 и User2

Подключение под логином `User1Login` к базе `Test`:

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U User1Login -P "Strong_Us3r1!" -d Test -C
```

Попытка выборки:

```sql
SELECT * FROM mgr.Orders;
GO
```

Запрос завершился ошибкой:

> The SELECT permission was denied on the object 'Orders', database 'Test', schema 'mgr'.

Аналогичная ошибка появляется при подключении под `User2Login`.

<p align="center">
  <img src="../screenshots/lab4-user1-deny-select.png" width="700" alt="Запрет SELECT для User1">
  <br>
  <em>Рис. 5. Пользователь User1 не имеет права SELECT из mgr.Orders.</em>
</p>

## 6. Выводы

В ходе лабораторной работы:

- Созданы логины `TestLogin1`, `TestLogin2` с аутентификацией SQL Server и соответствующие пользователи базы данных `TestUser1`, `TestUser2`.[web:284][web:287]
- Логин `TestLogin1` добавлен в серверную роль `sysadmin`, а базой по умолчанию для него установлена `Test`.
- В базе `Test` созданы пользовательские роли `Manager`, `Employee`, `NoUpdate`, назначены пользователям права, для роли `Employee` запрещено изменение пользователя `guest`, а роль `NoUpdate` лишена права обновлять таблицы.[web:288][web:291]
- Создана схема `mgr`, принадлежащая `TestUser1`, и таблица `mgr.Orders` в этой схеме, что соответствует пункту 4.1 задания.[web:292]
- Созданы пользователи `User1`, `User2`, добавлены в роль `Manager` и двумя способами лишены права выбирать данные из таблицы `mgr.Orders` (через прямой `DENY SELECT` и через дополнительную роль `NoSelectMgrOrders`).[web:288]
- Все операции выполнены с использованием T‑SQL и утилиты `sqlcmd` в Docker‑контейнере SQL Server, что демонстрирует управление безопасностью без использования графического интерфейса SSMS.[web:23][web:260]

Поставленные задачи по управлению безопасностью в SQL Server выполнены в полном объёме.