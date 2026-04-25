# Lab 04 — Управление безопасностью

## Тема и исходное задание

**Тема:** управление безопасностью в Microsoft SQL Server: логины, пользователи, роли и права.

**Исходное задание (по методичке):**

1. Создать для выполнения заданий базу данных `Test`.
2. Изменить режим проверки подлинности сервера на смешанный (Windows + SQL Server Authentication).
3. Создать логин `TestLogin1` с аутентификацией SQL Server, задать пароль:
   - добавить логин `TestLogin1` в фиксированную серверную роль `sysadmin`;
   - установить базу данных `Test` как базу по умолчанию.
4. Создать логин `TestLogin2` и пользователей базы `Test`:
   - `TestUser1` для логина `TestLogin1`;
   - `TestUser2` для логина `TestLogin2`.
5. Создать в базе `Test` пользовательские роли `Manager` и `Employee`:
   - назначить пользователю `TestUser1` роль `Manager`;
   - назначить пользователю `TestUser2` роль `Employee`;
   - запретить для роли `Employee` изменение пользователя `guest`;
   - создать новую роль и запретить ей обновлять таблицы в базе.
6. Пункт 4.1: создать таблицу в новой схеме базы `Test`, принадлежащей пользователю `TestUser1` (Transact‑SQL).
7. Пункт 4.2: создать в базе `Test` пользователей `User1` и `User2`, добавить их в роль `Manager` и несколькими способами запретить им выборку данных из таблицы, созданной в п.4.1.

## Адаптация под Docker и sqlcmd

База данных `Test` используется из предыдущих лабораторных работ. Все действия по управлению безопасностью выполняются в контейнере `mssql-default` с помощью утилиты `sqlcmd`:[web:23][web:284]

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

Вместо настройки режима проверки подлинности через SSMS используется заранее сконфигурированный смешанный режим в Docker‑образе SQL Server.

## Структура лабораторной

- `commands/` — последовательность команд Docker и `sqlcmd`:
  - `01-logins-and-users.md` — создание логинов `TestLogin1`, `TestLogin2` и пользователей `TestUser1`, `TestUser2`;
  - `02-roles-and-permissions.md` — создание ролей `Manager`, `Employee`, `NoUpdate` и настройка прав;
  - `03-schema-and-table-for-testuser1.md` — создание схемы `mgr` и таблицы `mgr.Orders`;
  - `04-manager-users-and-deny-select.md` — создание пользователей `User1`, `User2`, добавление в роль `Manager` и запрет SELECT.
- `scripts/` — T‑SQL‑скрипты:
  - `05-logins-and-users.sql`;
  - `06-roles-and-permissions.sql`;
  - `07-schema-and-table-for-testuser1.sql`;
  - `08-manager-users-and-deny-select.sql`.
- `report/` — оформленный отчёт по лабораторной:
  - `report.md`.
- `screenshots/` — скриншоты выполнения ключевых команд и проверок.