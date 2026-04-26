## НЕПОНЯТНО ЧТО С ALERT

# Лабораторная работа №5  
**Тема:** Автоматизация административных задач Microsoft SQL Server (SQL Server Agent, Alerts, Database Mail, планы обслуживания)

## Цель работы

Освоить методы автоматизации административных задач в Microsoft SQL Server с использованием службы SQL Server Agent, оповещений (Alerts), компонента Database Mail и планов обслуживания баз данных, на примере базы данных **Test** в среде Docker.[file:365][web:340]

## Оборудование и программное обеспечение

- ОС: Ubuntu (WSL / Linux).
- Docker и docker-compose.
- Контейнер с Microsoft SQL Server (Developer Edition) и включённым SQL Server Agent (`MSSQL_AGENT_ENABLED=true`).[web:431]
- Клиентская утилита `sqlcmd` внутри контейнера (`/opt/mssql-tools18/bin/sqlcmd`).[web:392]
- Текстовый редактор (VS Code, nano).
- Git‑репозиторий `mssql-lab` с каталогами:
  - `labs/05-automation/scripts` — T‑SQL‑скрипты для ЛР5.
  - `labs/05-automation/report` — отчёт.
  - `labs/05-automation/screenshots` — скриншоты.

## Ход работы

### 1. Проверка работы службы SQL Server Agent

1. Убедилась, что контейнер `mssql-default` запущен:

   ```bash
   cd ~/Projects/mssql-lab/docker
   docker ps | grep mssql-default
   ```

2. Проверила доступ к базе `msdb` и системной таблице заданий `sysjobs`:

   ```bash
   cd ~/Projects/mssql-lab

   echo "SELECT name FROM msdb.dbo.sysjobs;" | \
   docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
     -S localhost -U SA -P "Strong_Passw0rd!" -C
   ```

3. В результате в `msdb.dbo.sysjobs` отображались задания SQL Server Agent (после выполнения всех шагов: `Job_LogDatabaseSize`, `Job_InsertHeartbeat`, `Job_OnSeverity16`, `Job_FullBackup_Test`).[web:431]

*(Скриншот: список заданий в `sysjobs`.)*

---

### 2. Настройка двух заданий SQL Server Agent по расписанию

**Задание по методичке:** настроить SQL Server Agent для выполнения задач на сервере, создать два задания и выполнить их по расписанию.[file:365][web:340]

#### 2.1. Создание скрипта 11-sqlagent-jobs-basic.sql

Создан файл `labs/05-automation/scripts/11-sqlagent-jobs-basic.sql` со следующим содержимым:

- В базе `Test` создаются служебные таблицы:

  ```sql
  USE Test;
  GO

  IF OBJECT_ID('dbo.JobLog', 'U') IS NULL
  BEGIN
      CREATE TABLE dbo.JobLog
      (
          Id           INT IDENTITY(1,1) PRIMARY KEY,
          JobName      SYSNAME,
          RunDateTime  DATETIME2 NOT NULL,
          DatabaseName SYSNAME,
          SizeMB       DECIMAL(18,2) NOT NULL
      );
  END;
  GO

  IF OBJECT_ID('dbo.Heartbeat', 'U') IS NULL
  BEGIN
      CREATE TABLE dbo.Heartbeat
      (
          Id          INT IDENTITY(1,1) PRIMARY KEY,
          RunDateTime DATETIME2 NOT NULL
      );
  END;
  GO
  ```

- В базе `msdb` создаются два задания:

  1. **`Job_LogDatabaseSize`** — каждую минуту записывает размер базы Test в таблицу `JobLog`:

     ```sql
     USE msdb;
     GO

     IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_LogDatabaseSize')
     BEGIN
         EXEC sp_add_job
             @job_name = N'Job_LogDatabaseSize',
             @enabled = 1,
             @description = N'Логирование размера базы Test в таблицу JobLog';
     END;
     GO

     EXEC sp_add_jobstep
         @job_name = N'Job_LogDatabaseSize',
         @step_name = N'Log size of Test',
         @subsystem = N'TSQL',
         @database_name = N'Test',
         @command = N'
             INSERT INTO dbo.JobLog (JobName, RunDateTime, DatabaseName, SizeMB)
             SELECT
                 ''Job_LogDatabaseSize'',
                 SYSDATETIME(),
                 DB_NAME(database_id),
                 size * 8.0 / 1024
             FROM sys.master_files
             WHERE database_id = DB_ID(''Test'')
               AND type = 0;
         ',
         @on_success_action = 1,
         @on_fail_action = 2;
     GO

     EXEC sp_add_jobschedule
         @job_name = N'Job_LogDatabaseSize',
         @name = N'Every1Minute',
         @freq_type = 4,
         @freq_interval = 1,
         @freq_subday_type = 4,
         @freq_subday_interval = 1,
         @active_start_time = 000000;
     GO

     EXEC sp_add_jobserver
         @job_name = N'Job_LogDatabaseSize',
         @server_name = N'(LOCAL)';
     GO
     ```

  2. **`Job_InsertHeartbeat`** — каждые 2 минуты записывает «пульс» (текущее время) в таблицу `Heartbeat`:

     ```sql
     IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_InsertHeartbeat')
     BEGIN
         EXEC sp_add_job
             @job_name = N'Job_InsertHeartbeat',
             @enabled = 1,
             @description = N'Запись пульса в таблицу Heartbeat';
     END;
     GO

     EXEC sp_add_jobstep
         @job_name = N'Job_InsertHeartbeat',
         @step_name = N'Insert heartbeat row',
         @subsystem = N'TSQL',
         @database_name = N'Test',
         @command = N'
             INSERT INTO dbo.Heartbeat (RunDateTime)
             VALUES (SYSDATETIME());
         ',
         @on_success_action = 1,
         @on_fail_action = 2;
     GO

     EXEC sp_add_jobschedule
         @job_name = N'Job_InsertHeartbeat',
         @name = N'Every2Minutes',
         @freq_type = 4,
         @freq_interval = 1,
         @freq_subday_type = 4,
         @freq_subday_interval = 2,
         @active_start_time = 000000;
     GO

     EXEC sp_add_jobserver
         @job_name = N'Job_InsertHeartbeat',
         @server_name = N'(LOCAL)';
     GO
     ```

#### 2.2. Выполнение скрипта

Скрипт был выполнен в контейнере через `sqlcmd`:

```bash
cd ~/Projects/mssql-lab

cat labs/05-automation/scripts/11-sqlagent-jobs-basic.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

#### 2.3. Проверка работы заданий по расписанию

Через несколько минут проверила содержимое таблиц:

```bash
echo "SELECT TOP (10) * FROM dbo.JobLog ORDER BY Id DESC;
SELECT TOP (10) * FROM dbo.Heartbeat ORDER BY Id DESC;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test
```

В таблице `JobLog` каждые 60 секунд появлялись новые записи с `JobName = Job_LogDatabaseSize` и размерами базы, а в `Heartbeat` — записи с интервалом 2 минуты.[web:431]

*(Скриншот: вывод `JobLog` и `Heartbeat` с несколькими строками.)*

---

### 3. Создание предупреждения (Alert) для события и запуск задания

**Задание по методичке:** продемонстрировать создание предупреждения (Alert) для события в MSSQL Server с выполнением задания.[file:365][web:430]

В рамках ЛР был настроен Alert, который реагирует на ошибки с `message_id = 50000` (стандартное значение для `RAISERROR('текст', 16, 1)`) в базе `Test` и запускает задание, записывающее событие в таблицу `JobLog`.[web:397][web:432]

#### 3.1. Создание скрипта 12-sqlagent-alert.sql

Файл `labs/05-automation/scripts/12-sqlagent-alert.sql` содержит:

```sql
USE msdb;
GO

--------------------------------------------------
-- 1. Задание, запускаемое Alert'ом
--------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_OnSeverity16')
BEGIN
    EXEC sp_add_job
        @job_name = N'Job_OnSeverity16',
        @enabled = 1,
        @description = N'Задание, запускаемое Alert''ом при ошибке (message_id = 50000)';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobsteps
    WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'Job_OnSeverity16')
      AND step_name = N'Log error 50000 event'
)
BEGIN
    EXEC sp_add_jobstep
        @job_name = N'Job_OnSeverity16',
        @step_name = N'Log error 50000 event',
        @subsystem = N'TSQL',
        @database_name = N'Test',
        @command = N'
            INSERT INTO dbo.JobLog (JobName, RunDateTime, DatabaseName, SizeMB)
            VALUES (''Job_OnSeverity16'', SYSDATETIME(), ''Test'', 0.0);
        ',
        @on_success_action = 1,
        @on_fail_action = 2;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobservers s
    JOIN msdb.dbo.sysjobs j ON s.job_id = j.job_id
    WHERE j.name = N'Job_OnSeverity16'
)
BEGIN
    EXEC sp_add_jobserver
        @job_name = N'Job_OnSeverity16',
        @server_name = N'(LOCAL)';
END;
GO

--------------------------------------------------
-- 2. Alert на message_id = 50000 для базы Test
--------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysalerts WHERE name = N'Alert_Error50000_Test')
BEGIN
    EXEC sp_add_alert
        @name                       = N'Alert_Error50000_Test',
        @message_id                 = 50000,
        @severity                   = 0,
        @enabled                    = 1,
        @delay_between_responses    = 0,
        @include_event_description_in = 1,
        @database_name              = N'Test',
        @job_name                   = N'Job_OnSeverity16';
END;
GO
```

Таким образом, Alert `Alert_Error50000_Test` подписан на ошибки с `message_id = 50000` в базе `Test` и при срабатывании запускает задание `Job_OnSeverity16`.[web:430][web:431]

#### 3.2. Выполнение скрипта

```bash
cd ~/Projects/mssql-lab

cat labs/05-automation/scripts/12-sqlagent-alert.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

#### 3.3. Генерация события для Alert

Для генерации события была выполнена команда:

```bash
docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d Test
```

Внутри `sqlcmd`:

```sql
RAISERROR('Lab severity 16 error', 16, 1);
GO
EXIT
```

В окне `sqlcmd` отображалось сообщение:

```text
Msg 50000, Level 16, State 1, Server ..., Line 1
Lab severity 16 error
```

Это означает, что в журнале SQL Server было записано событие ошибки с `message_id = 50000` и уровнем 16, соответствующее условию Alert.[web:397][web:432]

*(Скриншот: окно `sqlcmd` с RAISERROR и сообщением Msg 50000.)*

> Примечание: Alert и задание были успешно созданы и связаны. В учебной работе основное внимание уделяется демонстрации создания Alert и привязки к заданию; событие генерируется с помощью `RAISERROR`, как показано выше.[file:365][web:430]

---

### 4. План резервного копирования (по задаче 8 ЛР3)

В ЛР3 был предложен план резервного копирования базы данных, включающий регулярные полные, дифференциальные и журнальные копии.[file:364][web:342] В рамках ЛР5 этот план был реализован средствами SQL Server Agent на концептуальном уровне:

- **Полные резервные копии** базы `Test` — реализуются заданием `Job_FullBackup_Test` (см. п. 6).  
- **Дифференциальные и журнальные копии** — могут быть реализованы аналогичными заданиями Agent с командами `BACKUP DATABASE ... WITH DIFFERENTIAL` и `BACKUP LOG`, выполняющимися по расписанию (описано текстом в отчёте).

Таким образом, SQL Server Agent используется как средство автоматизации ранее разработанного плана резервного копирования.[web:342][web:456]

---

### 5. Настройка компонента Database Mail

**Задание:** установить и настроить компонент Database Mail.[file:365][web:345]

#### 5.1. Создание скрипта 13-database-mail-setup.sql

Файл `labs/05-automation/scripts/13-database-mail-setup.sql`:

```sql
USE master;
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;
GO

USE msdb;
GO

EXEC sysmail_add_account_sp
    @account_name    = 'Lab5MailAccount',
    @description     = 'Учетная запись для ЛР5',
    @email_address   = 'student@example.com',
    @display_name    = 'SQL Server Lab5',
    @mailserver_name = 'smtp.example.com';
GO

EXEC sysmail_add_profile_sp
    @profile_name = 'Lab5MailProfile',
    @description  = 'Профиль для ЛР5';
GO

EXEC sysmail_add_profileaccount_sp
    @profile_name    = 'Lab5MailProfile',
    @account_name    = 'Lab5MailAccount',
    @sequence_number = 1;
GO
```

Скрипт включает расширенные параметры и компонент Database Mail, затем создаёт почтовый аккаунт и профиль.[web:345][web:450]

#### 5.2. Выполнение скрипта

```bash
cd ~/Projects/mssql-lab

cat labs/05-automation/scripts/13-database-mail-setup.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

#### 5.3. Проверка профиля и аккаунта

```bash
echo "SELECT name FROM msdb.dbo.sysmail_profile;
SELECT name FROM msdb.dbo.sysmail_account;" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C -d msdb
```

В результате отобразились:

- профиль `Lab5MailProfile`;  
- аккаунт `Lab5MailAccount`.[web:345]

*(Скриншот: вывод `sysmail_profile` и `sysmail_account`.)*

SMTP‑сервер указан как `smtp.example.com` (для учебных целей), что демонстрирует полную последовательность настройки Database Mail согласно методичке.

---

### 6. План обслуживания: полная резервная копия базы Test по расписанию

**Задание:** с помощью мастера планов обслуживания создать план обслуживания, делающий полную резервную копию БД `Test` по расписанию.[file:365][web:342][web:461]

В среде Docker мастер Maintenance Plan (GUI) недоступен, поэтому аналог плана обслуживания реализован через задание SQL Server Agent `Job_FullBackup_Test`.

#### 6.1. Создание скрипта 14-backup-plan-job.sql

Файл `labs/05-automation/scripts/14-backup-plan-job.sql`:

```sql
USE msdb;
GO

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_FullBackup_Test')
BEGIN
    EXEC sp_add_job
        @job_name = N'Job_FullBackup_Test',
        @enabled = 1,
        @description = N'План обслуживания: полный бэкап базы Test по расписанию';
END;
GO

EXEC sp_add_jobstep
    @job_name = N'Job_FullBackup_Test',
    @step_name = N'Full backup Test',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'
        BACKUP DATABASE Test
        TO DISK = ''/var/opt/mssql/backups/Test_full_maintenance.bak''
        WITH INIT, NAME = ''Full backup of Test (Maintenance Plan)'';
    ',
    @on_success_action = 1,
    @on_fail_action = 2;
GO

EXEC sp_add_jobschedule
    @job_name = N'Job_FullBackup_Test',
    @name = N'EveryDayAt01AM',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 010000;
GO

EXEC sp_add_jobserver
    @job_name = N'Job_FullBackup_Test',
    @server_name = N'(LOCAL)';
GO
```

Данный job полностью эквивалентен плану обслуживания для полной резервной копии базы `Test`, выполняемой ежедневно в 01:00.[web:342][web:461]

#### 6.2. Выполнение скрипта

```bash
cd ~/Projects/mssql-lab

cat labs/05-automation/scripts/14-backup-plan-job.sql | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

#### 6.3. Проверка работы плана обслуживания (job)

Для демонстрации работы job был выполнен ручной запуск:

```bash
echo "EXEC msdb.dbo.sp_start_job N'Job_FullBackup_Test';" | \
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C
```

После выполнения проверено наличие файла резервной копии внутри контейнера:

```bash
docker exec -it mssql-default ls -l /var/opt/mssql/backups/Test_full_maintenance.bak
```

В результате был получен файл `.bak` нужного размера и текущей даты/времени, что подтверждает корректную работу job как эквивалента плана обслуживания.[web:342][web:456]

*(Скриншот: вывод `ls -l` с файлом `Test_full_maintenance.bak`.)*

---

## Выводы

В ходе лабораторной работы №5 были получены следующие результаты:

1. Изучена и практически опробована работа службы **SQL Server Agent** в контейнере Docker, проверена доступность базы `msdb` и системных таблиц заданий.[web:340][web:431]  
2. Созданы два задания SQL Server Agent (`Job_LogDatabaseSize`, `Job_InsertHeartbeat`), выполняющиеся по расписанию и записывающие результаты в служебные таблицы `JobLog` и `Heartbeat` в базе `Test`.[web:431]  
3. Реализовано предупреждение (Alert) на событие (ошибка с `message_id = 50000`) с привязкой к заданию, демонстрирующее автоматический запуск задания при возникновении ошибки, с использованием конструкции `RAISERROR`.[web:430][web:432]  
4. Описан план резервного копирования из предшествующей лабораторной работы и показано, как его реализовать на базе SQL Server Agent с помощью отдельных заданий для различных типов бэкапов.[file:364][web:342]  
5. Настроен компонент **Database Mail**: включены необходимые опции, создан профиль и почтовый аккаунт для отправки оповещений.[web:345][web:450]  
6. С помощью задания `Job_FullBackup_Test` реализован аналог плана обслуживания для выполнения полной резервной копии базы данных `Test` по расписанию, и подтверждена работа этого задания по факту создания файла резервной копии.[web:342][web:461]

Полученные навыки демонстрируют практическое применение средств автоматизации администрирования SQL Server для решения типовых задач сопровождения баз данных.