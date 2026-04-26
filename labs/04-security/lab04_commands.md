# Lab 04 — Commands

## 1. Run script to create logins and users

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/04-security/scripts/create_logins_and_users.sql
```

## 2. Run script to create roles and permissions

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/04-security/scripts/create_roles_and_permissions.sql
```

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

## 3. Run script to create mgr schema and mgr.Orders table

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/04-security/scripts/create_mgr_schema_and_orders_table.sql
```

```sql
USE Test;
GO

SELECT s.name AS SchemaName, t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'mgr';
GO
```

## 4. Run script to create User1/User2 and deny SELECT on mgr.Orders

```bash
cd docker

docker exec -i mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C \
  -i /var/opt/mssql/scripts/04-security/scripts/create_manager_users_and_deny_select.sql
```

### 4.1. Connect as User1 and test SELECT

```bash
cd docker

docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U User1Login -P "Strong_Us3r1!" -d Test -C
```

```sql
SELECT * FROM mgr.Orders;
GO
```

### 4.2. Connect as User2 and test SELECT

```bash
cd docker

docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U User2Login -P "Strong_Us3r2!" -d Test -C
```

```sql
SELECT * FROM mgr.Orders;
GO
```