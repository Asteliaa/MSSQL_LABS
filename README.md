# MSSQL Administration Labs

Репозиторий лабораторных работ по администрированию Microsoft SQL Server в формате Ubuntu + Docker + sqlcmd.

## Быстрый старт

```bash
cd docker
docker compose up -d
docker compose ps
```

Проверка подключения к default экземпляру:

```bash
docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
	-S localhost -U SA -P "Strong_Passw0rd!" -C \
	-Q "SELECT @@VERSION AS version_info;"
```

## Документация

- `docs/environment-setup.md` - пошаговая подготовка окружения и диагностика проблем.
- `docs/execution-plan.md` - план выполнения лабораторных и критерии приемки.

## Структура репозитория

- `docker/` - контейнеры SQL Server и инфраструктура запуска.
- `docs/` - общая документация проекта.
- `labs/` - материалы лабораторных работ.
- `assets/` - шаблоны и вспомогательные ресурсы.

## Лабораторные

- 01 Installation
- 02 Databases and Files
- 03 Backup and Recovery
- 04 Security
- 05 Automation
- 06 Replication and HA
- 07 Monitoring