# Lab 03 — Commands

## Check backups directory in container

```bash
docker exec -it mssql-default bash
ls -ld /var/opt/mssql/backups
ls /var/opt/mssql/backups
exit
```

## Run backup and restore in default instance

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/backups/scripts/backup_and_restore_in_default.sql
```

> Note: after the OFFLINE step, manually delete the Test data file inside the container before re‑running the ONLINE / RESTORE part:

```bash
docker exec -it mssql-default bash
rm /var/opt/mssql/data/testdata_a.mdf
exit
```

## Copy Test from default to named instance

### Part A — backup on mssql-default

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/backups/scripts/copy_test_to_named_instance.sql
```

### Part B — restore on mssql-named

```bash
cd docker

docker exec -i mssql-named /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/backups/scripts/copy_test_to_named_instance.sql
```

## Log backup and point-in-time restore (delete + restore rows)

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/backups/scripts/log_backup_and_point_in_time_restore.sql
```

## Snapshot and mirroring examples

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/backups/scripts/snapshot_and_mirroring_examples.sql
```