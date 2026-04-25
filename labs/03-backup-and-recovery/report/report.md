# Лабораторная работа 3. Аварийное восстановление, резервное копирование и восстановление

## Цель работы

- Освоить основные типы резервных копий в SQL Server: полные, дифференциальные и журнальные (log backup).
- Научиться восстанавливать базу данных после повреждения файлов и логических ошибок с использованием резервных копий.
- Закрепить навыки работы с Transact‑SQL и утилитой `sqlcmd` в Docker‑среде.
- Рассмотреть примеры зеркальной копии и моментального снимка базы данных, а также разработать стратегию резервного копирования для заданного бизнес‑кейса.

## 1. Описание стенда и используемых экземпляров

Работа выполнялась в среде Docker на Ubuntu. В docker‑compose конфигурации определены два контейнера SQL Server:[web:23][web:252]

- `mssql-default` — экземпляр по умолчанию, в котором находятся:
  - системные базы (`master`, `msdb`, `tempdb`, `model`);
  - пользовательская база `Test`, созданная в лабораторной работе №2 и использованная для экспериментов с резервным копированием и восстановлением.
- `mssql-named` — второй экземпляр SQL Server, моделирующий «именованный» сервер. В нём находятся:
  - база `RZ_DB`, созданная в ЛР2;
  - база `Test_from_default`, восстановленная из резервной копии `Test`, созданной на `mssql-default`.

Путь для резервных копий:

- в контейнерах: `/var/opt/mssql/backups`;
- на хосте эта директория примонтирована как `docker/backups`.

Все действия выполнялись через утилиту `sqlcmd`:

```bash
docker exec -it <container-name> /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

## 2. Резервное копирование базы master (п.1)

Перед выполнением остальных заданий была создана полная резервная копия системной базы `master` на сменный носитель (в данном случае — каталог `/var/opt/mssql/backups` внутри контейнера):[file:268][file:6]

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "BACKUP DATABASE master 
      TO DISK = '/var/opt/mssql/backups/master_full_1.bak'
      WITH INIT, NAME = 'Full backup of master';"
```

После выполнения команды в каталоге `/var/opt/mssql/backups` появился файл `master_full_1.bak`, что подтверждает успешное создание резервной копии.

<p align="center">
  <img src="../screenshots/backup-master.png" width="700" alt="Резервное копирование базы master">
  <br>
  <em>Рис. 1. Резервное копирование базы master в контейнере mssql-default.</em>
</p>

## 3. Резервное копирование и восстановление базы Test после повреждения (п.2–4)

### 3.1. Резервное копирование базы Test

На экземпляре `mssql-default` была выполнена полная резервная копия пользовательской базы `Test`:[file:268][file:6]

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "BACKUP DATABASE Test
      TO DISK = '/var/opt/mssql/backups/Test_full_1.bak'
      WITH INIT, NAME = 'Full backup of Test';"
```

<p align="center">
  <img src="../screenshots/backup-test-full-1.png" width="700" alt="Резервное копирование базы Test">
  <br>
  <em>Рис. 2. Резервное копирование базы Test.</em>
</p>

### 3.2. Перевод базы Test в OFFLINE и «повреждение» файла данных

Для имитации повреждения файла данных (как если бы в него внесли случайные изменения в редакторе) база `Test` была переведена в состояние OFFLINE, после чего соответствующий файл данных был удалён на уровне файловой системы:[file:268]

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

```sql
USE master;
GO

ALTER DATABASE Test SET OFFLINE WITH ROLLBACK IMMEDIATE;
GO
```

<p align="center">
  <img src="../screenshots/test-offline.png" width="700" alt="Перевод базы Test в OFFLINE">
  <br>
  <em>Рис. 3. База Test переведена в состояние OFFLINE.</em>
</p>

Информация о файлах базы извлекалась из представления `sys.master_files`:

```sql
SELECT
    name,
    physical_name
FROM sys.master_files
WHERE database_id = DB_ID('Test');
GO
```

Далее файл данных `testdata_a.mdf` был удалён внутри контейнера:

```bash
docker exec -it mssql-default bash
rm /var/opt/mssql/data/testdata_a.mdf
exit
```

### 3.3. Попытка подключения к повреждённой базе

После удаления файла данных попытка перевести базу `Test` в ONLINE завершилась ошибкой, что демонстрирует невозможность работы с повреждённой БД:[file:268][file:6]

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

```sql
USE master;
GO

ALTER DATABASE Test SET ONLINE;
GO
```

<p align="center">
  <img src="../screenshots/test-online-error.png" width="700" alt="Ошибка при попытке перевести повреждённую Test в ONLINE">
  <br>
  <em>Рис. 4. Попытка подключения к повреждённой базе Test приводит к ошибке.</em>
</p>

### 3.4. Восстановление базы Test из резервной копии

База `Test` была восстановлена из ранее созданного полного бэкапа `Test_full_1.bak`:[file:268][file:6]

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "RESTORE DATABASE Test
      FROM DISK = '/var/opt/mssql/backups/Test_full_1.bak'
      WITH REPLACE;"
```

Проверка состояния базы:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "SELECT name, state_desc 
      FROM sys.databases 
      WHERE name = 'Test';"
```

Результат показал, что база `Test` находится в состоянии `ONLINE`.

<p align="center">
  <img src="../screenshots/test-restored-ok.png" width="700" alt="Успешное восстановление базы Test">
  <br>
  <em>Рис. 5. Восстановленная база Test находится в состоянии ONLINE.</em>
</p>

Таким образом, пункты задания, связанные с повреждением файла данных и восстановлением базы из резервной копии, выполнены.

## 4. Резервное копирование и восстановление через другой экземпляр (п.5)

Для демонстрации восстановления из резервной копии, созданной на другом экземпляре, выполнялись следующие шаги:[file:268]

1. В экземпляре `mssql-default` была создана полная резервная копия базы `Test` в файл `Test_full_for_named.bak`:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "BACKUP DATABASE Test
      TO DISK = '/var/opt/mssql/backups/Test_full_for_named.bak'
      WITH INIT, NAME = 'Full backup of Test for named instance';"
```

2. На экземпляре `mssql-named` из этого файла была восстановлена база `Test_from_default` под другим именем и с новыми физическими файлами:

```bash
docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "RESTORE DATABASE Test_from_default
      FROM DISK = '/var/opt/mssql/backups/Test_full_for_named.bak'
      WITH MOVE 'testdata_a' TO '/var/opt/mssql/data/testdata_a_from_default.mdf',
           MOVE 'testlog'   TO '/var/opt/mssql/data/testlog_from_default.ldf',
           REPLACE;"
```

3. Список баз данных на `mssql-named` подтвердил наличие `RZ_DB` и `Test_from_default`.

<p align="center">
  <img src="../screenshots/backup-default-restore-named.png" width="700" alt="Восстановление Test_from_default на mssql-named">
  <br>
  <em>Рис. 6. База Test_from_default восстановлена на другом экземпляре SQL Server.</em>
</p>

Этот эксперимент соответствует пункту задания о резервном копировании и восстановлении с использованием другого экземпляра сервера.

## 5. Пример настройки зеркальной копии и моментального снимка (п.6–7)

### 5.1. Пример настройки зеркальной копии базы

Для выполнения теоретического пункта о зеркальной копии была подготовлена T‑SQL‑заготовка, иллюстрирующая основные шаги настройки зеркалирования базы `Test`:[file:6]

```sql
-- Пример настройки зеркальной копии базы Test (концептуально)

CREATE ENDPOINT MirroringEndpoint
    STATE = STARTED
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (ROLE = ALL);
GO

ALTER DATABASE Test SET RECOVERY FULL;
GO

-- После резервного копирования и восстановления базы Test на зеркальном сервере
-- выполняется привязка партнёров:

ALTER DATABASE Test
SET PARTNER = 'TCP://principal-server:5022';
GO

ALTER DATABASE Test
SET PARTNER = 'TCP://mirror-server:5022';
GO

-- При необходимости:
-- ALTER DATABASE Test SET WITNESS = 'TCP://witness-server:5022';
```

В отчёте поясняется, что в реальной инфраструктуре для зеркалирования используются отдельные серверы principal, mirror и witness, а также требуются предварительные шаги по резервному копированию и восстановлению базы на зеркальном сервере.[file:6]

### 5.2. Пример моментального снимка базы Test2

Также приведён пример создания моментального снимка базы `Test2` с использованием инструкции `CREATE DATABASE ... AS SNAPSHOT OF`:[file:6]

```sql
-- Пример создания моментального снимка базы Test2

CREATE DATABASE Test2_Snapshot
ON
(
    NAME = N'Test2_data',
    FILENAME = N'/var/opt/mssql/data/Test2_Snapshot.ss'
)
AS SNAPSHOT OF Test2;
GO
```

Моментальный снимок фиксирует состояние базы `Test2` в определённую точку времени и используется для чтения и возможного отката.

## 6. Сценарий с журналом транзакций и удалением строк (п.8–10)

В этом пункте была смоделирована ситуация логической ошибки (удаление строк) и последующее восстановление базы `Test` с использованием резервной копии журнала транзакций. Основные шаги:[file:268][file:6]

### 6.1. Перевод базы Test в модель восстановления FULL

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "ALTER DATABASE Test SET RECOVERY FULL;"
```

### 6.2. Полный бэкап базы Test

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "BACKUP DATABASE Test
      TO DISK = '/var/opt/mssql/backups/Test_full_for_log.bak'
      WITH INIT, NAME = 'Full backup of Test before log backup';"
```

<p align="center">
  <img src="../screenshots/log-full-backup.png" width="700" alt="Полный бэкап Test для сценария с журналом">
  <br>
  <em>Рис. 7. Полная резервная копия базы Test для сценария с журналом.</em>
</p>

### 6.3. Резервная копия журнала транзакций

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q \"BACKUP LOG Test
      TO DISK = '/var/opt/mssql/backups/Test_log_1.trn'
      WITH INIT, NAME = 'Log backup of Test before delete';\"
```

<p align="center">
  <img src="../screenshots/log-backup-1.png" width="700" alt="Резервная копия журнала транзакций Test">
  <br>
  <em>Рис. 8. Резервная копия журнала транзакций базы Test.</em>
</p>

### 6.4. Удаление строк из таблицы и фиксация результата

В качестве примера была использована таблица `app.TABLE_1` в базе `Test`:

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

```sql
USE Test;
GO

SELECT TOP (5) * FROM app.TABLE_1;
GO

DELETE TOP (5) FROM app.TABLE_1;
GO

SELECT COUNT(*) AS RowsAfterDelete
FROM app.TABLE_1;
GO
```

<p align="center">
  <img src="../screenshots/log-scenario-delete.png" width="700" alt="Удаление строк из таблицы app.TABLE_1">
  <br>
  <em>Рис. 9. Удаление строк из таблицы app.TABLE_1.</em>
</p>

### 6.5. Восстановление Test из полного бэкапа и журнала

1. Восстановление полного бэкапа с параметром `NORECOVERY`:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "RESTORE DATABASE Test
      FROM DISK = '/var/opt/mssql/backups/Test_full_for_log.bak'
      WITH NORECOVERY;"
```

2. Восстановление журнала транзакций с параметром `RECOVERY`:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q \"RESTORE LOG Test
      FROM DISK = '/var/opt/mssql/backups/Test_log_1.trn'
      WITH RECOVERY;\"
```

3. Проверка числа строк в таблице после восстановления:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -Q "USE Test;
      SELECT COUNT(*) AS RowsAfterRestore
      FROM app.TABLE_1;"
```

<p align="center">
  <img src="../screenshots/log-scenario-restored.png" width="700" alt="Количество строк после восстановления из журнала">
  <br>
  <em>Рис. 10. Количество строк в таблице app.TABLE_1 восстановлено до исходного.</em>
</p>

Результаты показали, что удалённые строки были успешно восстановлены, что подтверждает правильное использование резервной копии журнала транзакций.

## 7. Задача про риэлтерскую компанию

### 7.1. Предложенная стратегия резервного копирования

Условие задачи:[file:268][file:6]

- Рабочие дни: понедельник, вторник, среда, пятница.
- Выходные: четверг и суббота, при этом отчёт в пятницу и воскресенье включает данные за выходные дни.
- Данные поступают непрерывно, обработка и формирование отчётов — только в рабочее время.
- Каждое утро рабочего дня формируется отчёт за предыдущий день, который критически важен.

Предлагаемая стратегия:

- **Полная резервная копия базы данных (FULL):**
  - в ночь с воскресенья на понедельник;
  - в ночь с четверга на пятницу.
- **Дифференциальная резервная копия (DIFF):**
  - в ночь с понедельника на вторник;
  - в ночь с вторника на среду.
- **Резервные копии журнала транзакций (LOG):**
  - каждые 15–30 минут в рабочее время;
  - раз в 1–2 часа в выходные дни.

Аргументы оптимальности по времени:

- При восстановлении требуется не более одной полной и одной дифференциальной резервной копии плюс небольшое количество логов, что минимизирует время восстановления и объём данных, которые нужно читать и проигрывать.[file:6]
- Редкие полные бэкапы (2 раза в неделю) уменьшают окно обслуживания и нагрузку на систему, а дифференциальные копии позволяют избежать чрезмерного накопления логов.
- Частые log‑backup’ы ограничивают размер каждого файла лога и позволяют гибко выбирать точку восстановления (например, до момента логической ошибки или сбоя).

### 7.2. Восстановление в среду утром при отказе основного сервера

Сценарий аварии: в среду утром, до формирования отчёта за вторник, «сгорает» основной сервер.[file:268][file:6]

При предложенной стратегии к этому моменту доступны:

- Полная резервная копия базы (сделанная в ночь с воскресенья на понедельник).
- Дифференциальные бэкапы за ночь с понедельника на вторник и вторника на среду.
- Набор лог‑бэкапов за вторник и раннее утро среды.

Алгоритм восстановления на новом сервере:

1. Развернуть новый экземпляр SQL Server.
2. Восстановить последнюю полную резервную копию базы с опцией `NORECOVERY`.
3. Восстановить последнюю дифференциальную резервную копию (за ночь вторника на среду), также с `NORECOVERY`.
4. Последовательно восстановить все резервные копии журналов транзакций, созданные после дифференциальной копии, вплоть до последнего доступного log‑бэкапа (или до конкретного времени с использованием параметра `STOPAT`).
5. Выполнить последний `RESTORE LOG` с параметром `RECOVERY`, после чего база станет доступной.
6. Сформировать отчёт за вторник, используя восстановленные данные.

Такой подход минимизирует время восстановления (используется всего два больших файла — FULL и DIFF, плюс сравнительно небольшой набор логов) и позволяет восстановить данные максимально близко к моменту отказа сервера, удовлетворяя требованиям задачи.

## 8. Выводы

В рамках лабораторной работы были выполнены следующие действия:

- Созданы резервные копии системной базы `master` и пользовательской базы `Test` на уровне Docker‑контейнера в каталог `/var/opt/mssql/backups`.
- Смоделирована ситуация повреждения файла данных базы `Test` (OFFLINE + удаление файла MDF), продемонстрирована невозможность подключения и выполнено восстановление базы из полной резервной копии.
- Выполнено резервное копирование базы `Test` на экземпляре `mssql-default` и последующее восстановление этой базы под другим именем на экземпляре `mssql-named`.
- Рассмотрены примеры T‑SQL‑конфигураций зеркальной копии базы данных и моментального снимка базы `Test2`.
- Смоделирован сценарий логической ошибки (удаление строк из таблицы) и выполнено восстановление базы `Test` в исходное состояние с использованием полной резервной копии и резервной копии журнала транзакций.
- Разработана и обоснована стратегия резервного копирования для риэлтерской компании, а также описан алгоритм восстановления в случае аварии в среду утром.

Все пункты задания 3 выполнены с использованием утилиты `sqlcmd` и Docker‑контейнеров Microsoft SQL Server, что демонстрирует возможность переноса лабораторных работ по администрированию SQL Server в консольную среду без использования графического интерфейса SSMS.[file:268][file:6][web:23][web:252]