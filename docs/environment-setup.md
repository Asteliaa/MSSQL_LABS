# Настройка окружения для лабораторных работ по администрированию Microsoft SQL Server в Docker

Этот документ описывает подготовку рабочего окружения для выполнения лабораторных работ по администрированию Microsoft SQL Server в Docker. Окружение строится вокруг Docker, терминала VS Code, Git/GitHub и структуры проекта, в которой каждая лабораторная работа хранится отдельно вместе с командами, скриптами, отчётом и скриншотами. Идея такого подхода совпадает с практикой воспроизводимой работы через Git-репозитории и удобной интеграцией Git в VS Code.

## Цель подготовки окружения

Перед началом выполнения лабораторных работ необходимо подготовить единое окружение, в котором будут храниться исходные файлы, команды, отчёты и Docker-конфигурация. Такой подход упрощает повторяемость шагов, позволяет отслеживать изменения через Git и отделяет настройку инфраструктуры от выполнения самих лабораторных заданий.

## Что должно быть установлено

Для начала работы понадобятся следующие инструменты:

- Docker Desktop или Docker Engine для запуска контейнеров SQL Server.
- Visual Studio Code как основная среда работы с файлами проекта, терминалом и Git.
- Git для ведения истории изменений и публикации репозитория на GitHub.
- SQL-клиент для подключения к экземплярам SQL Server: SSMS, Azure Data Studio или DBeaver.

## Шаг 1. Установка Docker

Docker нужен для запуска контейнеров с SQL Server вместо развёртывания виртуальной машины. Microsoft поддерживает сценарий запуска и подключения к SQL Server в контейнере, включая проброс портов и конфигурирование параметров окружения.

### Windows

1. Скачай и установи Docker Desktop.
2. Убедись, что включён WSL2 или Hyper-V, если этого требует установщик.
3. После установки запусти Docker Desktop и дождись статуса `Engine running`.

### Linux

1. Установи Docker Engine и Docker Compose Plugin.
2. Добавь своего пользователя в группу `docker`, чтобы запускать команды без `sudo`.
3. Проверь работу командой:

```bash
docker --version
docker compose version
```

Проверка версий нужна, чтобы убедиться, что Docker CLI и compose доступны из терминала, который будет использоваться в VS Code.

## Шаг 2. Установка Visual Studio Code

VS Code нужен как единая точка работы: редактирование Markdown, SQL и YAML-файлов, работа с Git и запуск команд в терминале. Встроенная поддержка Source Control и GitHub позволяет создавать и публиковать репозитории прямо из редактора или терминала.

После установки рекомендуется добавить следующие расширения:

- Docker
- GitHub Pull Requests and Issues
- Markdown All in One
- SQLTools или MSSQL
- YAML

## Шаг 3. Установка Git

Git нужен для фиксации истории работы, ведения репозитория и отправки файлов на GitHub. Репозиторий удобнее вести как «лабораторный журнал», в котором сохраняются и инфраструктурные файлы, и отчёты, и реальные команды выполнения.

Проверь установку:

```bash
git --version
```

Если Git установлен впервые, выполни начальную настройку:

```bash
git config --global user.name "ТВОЁ_ИМЯ"
git config --global user.email "ТВОЙ_EMAIL"
```

## Шаг 4. Установка клиента для SQL Server

Для подключения к контейнерам SQL Server можно использовать SQL Server Management Studio, Azure Data Studio или другой совместимый клиент. Для Docker-сценария важно, чтобы клиент умел подключаться к `localhost,порт`, потому что разные экземпляры SQL Server будут различаться именно по портам.

Рекомендуемый минимум:

- Windows: SSMS.
- Linux/macOS: Azure Data Studio или DBeaver.

## Шаг 5. Создание рабочей папки проекта

Открой терминал в VS Code или системный терминал и создай корневую папку проекта:

```bash
mkdir mssql-administration-labs
cd mssql-administration-labs
code .
```

Эта команда создаёт основу репозитория и сразу открывает её в VS Code для дальнейшей работы через встроенный терминал и редактор.

## Шаг 6. Инициализация структуры проекта

Структура проекта уже была создана следующими командами:

```bash
mkdir -p docker/init docker/backups
mkdir -p docs
mkdir -p labs/01-installation/{report,commands,scripts,screenshots}
mkdir -p labs/02-databases-and-files/{report,commands,scripts,screenshots}
mkdir -p labs/03-backup-and-recovery/{report,commands,scripts,screenshots}
mkdir -p labs/04-security/{report,commands,scripts,screenshots}
mkdir -p labs/05-automation/{report,commands,scripts,screenshots}
mkdir -p labs/06-replication-ha/{report,commands,scripts,screenshots}
mkdir -p labs/07-monitoring/{report,commands,scripts,screenshots}
mkdir -p assets/templates
touch README.md .gitignore docs/environment-setup.md docs/execution-plan.md
touch labs/01-installation/README.md labs/01-installation/report/report.md
touch labs/02-databases-and-files/README.md labs/02-databases-and-files/report/report.md
touch labs/03-backup-and-recovery/README.md labs/03-backup-and-recovery/report/report.md
touch labs/04-security/README.md labs/04-security/report/report.md
touch labs/05-automation/README.md labs/05-automation/report/report.md
touch labs/06-replication-ha/README.md labs/06-replication-ha/report/report.md
touch labs/07-monitoring/README.md labs/07-monitoring/report/report.md
```

Такая структура отделяет общую документацию от лабораторных работ и инфраструктурных файлов Docker. Отдельные каталоги для отчётов, команд, скриптов и скриншотов соответствуют хорошей практике структурирования репозиториев для исследовательской и лабораторной работы.

## Шаг 7. Инициализация Git-репозитория

Из корня проекта выполни:

```bash
git init
```

Затем создай `.gitignore` и добавь базовые исключения:

```gitignore
.env
.vscode/
*.log
*.tmp
*.bak
*.mdf
*.ldf
.DS_Store
Thumbs.db
```

После этого можно сделать первый коммит:

```bash
git add .
git commit -m "Initial project structure for MSSQL administration labs"
```

Git-репозиторий позволит фиксировать этапы работы, а VS Code поддерживает отображение изменений и коммитов прямо в панели Source Control.

## Шаг 8. Создание удалённого репозитория на GitHub

После создания локального репозитория можно связать его с GitHub. Обычно это делается через новый пустой репозиторий на GitHub и последующую привязку удалённого адреса.

Команды привязки:

```bash
git remote add origin https://github.com/USERNAME/mssql-administration-labs.git
git branch -M main
git push -u origin main
```

## Шаг 9. Подготовка Docker-конфигурации

Следующий обязательный файл после инициализации структуры — `docker/docker-compose.yml`, потому что именно он будет поднимать контейнеры SQL Server для выполнения лабораторных работ. Официальная документация Microsoft описывает развёртывание SQL Server в Docker через переменные среды, проброс порта и использование volume для хранения данных.

Минимальный состав `docker/`:

- `docker-compose.yml`
- `.env`
- `init/`
- `backups/`

## Шаг 10. Проверка, что окружение готово

Перед переходом к первой лабораторной работе нужно убедиться, что:

- Docker запускается без ошибок.
- VS Code открывает проект и видит структуру каталогов.
- Git работает, а репозиторий инициализирован.
- Есть SQL-клиент для подключения к будущим контейнерам SQL Server.
- В проекте уже созданы `docs/environment-setup.md` и `docs/execution-plan.md`, которые будут использоваться как базовая документация.