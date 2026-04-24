docker exec -it mssql-default /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!"

Выполненные sql скрипты


ruslana@vivobook:~/Projects/mssql-lab/docker$ docker exec -it mssql-default /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Strong_Passw0rd!" -C

1> SELECT @@SERVERNAME AS ServerName, @@VERSION AS VersionInfo;
2> go
ServerName                                                                                                                       VersionInfo                                                                                                                                                                                                                                                                                                 
-------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
c1ec40dc24f9                                                                                                                     Microsoft SQL Server 2022 (RTM-CU23) (KB5078297) - 16.0.4236.2 (X64) 
        Jan 22 2026 17:50:56 
        Copyright (C) 2022 Microsoft Corporation
        Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS) <X64>                                                                                                      

(1 rows affected)
ServerName                                                                                                                       VersionInfo                                                                                                                                                                                                                                                                                                 
-------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
c1ec40dc24f9                                                                                                                     Microsoft SQL Server 2022 (RTM-CU23) (KB5078297) - 16.0.4236.2 (X64) 
        Jan 22 2026 17:50:56 
        Copyright (C) 2022 Microsoft Corporation
        Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS) <X64>                                                                                                      

(1 rows affected)


1> SELECT name FROM sys.databases;
2> Go
name                                                                                                                            
--------------------------------------------------------------------------------------------------------------------------------
master                                                                                                                          
tempdb                                                                                                                          
model                                                                                                                           
msdb                                                                                                                            

(4 rows affected)
1> 