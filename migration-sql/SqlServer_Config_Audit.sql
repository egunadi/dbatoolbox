USE master
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<SQL Server Instance Name>'
SELECT @@SERVERNAME
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<SQL Server Version, Edition and Build>'
SELECT @@VERSION
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<The server wide configuration>'
GO
SP_CONFIGURE 'show advanced options',1
reconfigure with override
GO
sp_configure
GO
SP_CONFIGURE 'show advanced options',0
reconfigure with override
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List of Attached Databases>'
SELECT name as Database_Name, dbid as Database_ID, cmptlevel as Database_Compatibility_Level, filename as Database_MDF_Location from SYSDATABASES
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<Information for all the databases and their files>'
SET NOCOUNT ON
IF (object_id( 'tempdb..#TMPFIXEDDRIVES' ) IS NOT NULL) DROP TABLE #TMPFIXEDDRIVES
IF (object_id( 'tempdb..#TMPSPACEUSED' ) IS NOT NULL) DROP TABLE #TMPSPACEUSED
IF (object_id( 'tempdb..#HDB' ) IS NOT NULL) DROP TABLE #HDB
CREATE TABLE #TMPFIXEDDRIVES (DRIVE CHAR(1), MBFREE INT) 
INSERT INTO #TMPFIXEDDRIVES 
EXEC xp_FIXEDDRIVES 
CREATE TABLE #TMPSPACEUSED (DBNAME VARCHAR(255), FILEID INT,FILENME VARCHAR(255), SPACEUSED FLOAT) 
CREATE TABLE #HDB (name sysname not null,db_size varchar(25) not null,owner varchar(40) not null,dbid int not null,created smalldatetime not null,status varchar(500) not null,compatibility_level int not null)
INSERT INTO #HDB exec sp_helpdb;

INSERT INTO #TMPSPACEUSED 
EXEC( 'sp_msforeachdb ''USE [?]; Select ''''?'''' DBName,fileid, Name FileNme, fileproperty(Name,''''SpaceUsed'''') SpaceUsed from sysfiles''') 

SELECT @@servername as SQLServerInstance, A.Database_id as Database_ID,A.NAME AS Database_Name,
CASE D.FILEID WHEN 1 THEN ltrim(XX.db_size) ELSE NULL END as Database_Size ,CASE D.FILEID  WHEN 1 THEN XX.owner ELSE NULL END as Database_Owner,
CASE D.FILEID WHEN 1 THEN XX.created ELSE NULL END as Database_Creation_Date ,C.DRIVE, C.MBFREE AS Free_Space_of_the_Disk, D.FILEID as Database_File_ID, B.NAME AS Database_Filename, 
CASE B.TYPE WHEN 0 THEN 'DATA' ELSE TYPE_DESC END AS FILETYPE, (B.SIZE * 8 / 1024)AS FILESIZE_MB, ROUND((B.SIZE * 8 / 1024) - (D.SPACEUSED / 128),2) as SPACEFREE_MB,
--ROUND(100-((((B.SIZE * 8 / 1024) – (D.SPACEUSED / 128))*100)/ CASE(B.SIZE * 8 / 1024) WHEN 0 THEN 1 ELSE (B.SIZE * 8 / 1024)  END ),2) as [%USED], b.size,
b.max_size, b.growth, b.is_percent_growth, B.PHYSICAL_NAME, CASE B.TYPE WHEN 0 THEN A.recovery_model_desc ELSE NULL END AS [Recovery_Model], 
CASE B.TYPE WHEN 0 THEN A.compatibility_level ELSE NULL END AS [Compatibility_Level] ,CASE D.FILEID WHEN 1 THEN BR.last_backup_finish_date 
ELSE NULL END as [Backup],CASE D.FILEID  WHEN 1 THEN BR.last_TRLog_backup_finish_date ELSE NULL  END as TRBackup ,CASE D.FILEID 
WHEN 1 THEN BR.last_restore_date ELSE NULL END as [Restore],  DM.mirroring_role_desc+'('+DM.mirroring_state_desc+')' as DBMirror_Info
FROM SYS.DATABASES A  
INNER JOIN SYS.MASTER_FILES B ON A.DATABASE_ID = B.DATABASE_ID 
INNER JOIN #TMPFIXEDDRIVES C ON LEFT(B.PHYSICAL_NAME,1) = C.DRIVE 
INNER JOIN #TMPSPACEUSED D ON A.NAME = D.DBNAME AND B.NAME = D.FILENME 
INNER JOIN #HDB XX on XX.dbid= A.Database_id 
INNER JOIN (SELECT D.database_id,B.last_backup_finish_date,TR.last_TRLog_backup_finish_date,R.last_restore_date
FROM sys.databases D
LEFT JOIN (SELECT BS.database_name ,max(BS.backup_finish_date) as last_backup_finish_date FROM msdb.dbo.backupset BS (NOLOCK)
INNER JOIN msdb.dbo.backupmediafamily MF(NOLOCK) ON BS.media_set_id = MF.media_set_id 
WHERE  BS.backup_start_date >= CAST(CONVERT(varchar(10),dateadd(mm,-3,getdate()),120) AS datetime)
AND BS.server_name = @@servername and BS.type='D'
GROUP BY BS.database_name ) B on D.name=B.database_name LEFT JOIN (SELECT BS.database_name ,max(BS.backup_finish_date) as last_TRLog_backup_finish_date 
FROM  msdb.dbo.backupset BS (NOLOCK) INNER JOIN msdb.dbo.backupmediafamily MF(NOLOCK) ON BS.media_set_id = MF.media_set_id
WHERE BS.backup_start_date >= CAST(CONVERT(varchar(10),dateadd(mm,-1,getdate()),120) AS datetime) AND BS.server_name = @@servername and BS.type='L'
GROUP BY BS.database_name) TR on D.name=TR.database_name 
LEFT JOIN (SELECT rh.destination_database_name, max(rh.restore_date) as last_restore_date FROM msdb.dbo.restorehistory rh (NOLOCK)
INNER JOIN msdb.dbo.backupset BS (NOLOCK) ON rh.backup_set_id=BS.backup_set_id
WHERE BS.type= 'D' AND RH.restore_date >=CAST(CONVERT(varchar(10),dateadd(mm,-3,getdate()),120) AS datetime)
GROUP BY rh.destination_database_name) R on D.name=R.destination_database_name) BR on A.Database_id=BR.database_id
LEFT JOIN msdb.sys.database_mirroring dm (nolock) on A.database_id=dm.database_id
ORDER BY Database_Name
IF (object_id( 'tempdb..#TMPFIXEDDRIVES' ) IS NOT NULL) DROP TABLE #TMPFIXEDDRIVES
IF (object_id( 'tempdb..#TMPSPACEUSED' ) IS NOT NULL) DROP TABLE #TMPSPACEUSED
IF (object_id( 'tempdb..#HDB' ) IS NOT NULL) DROP TABLE #HDB
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<Information for all the server logins>'
EXEC sp_helplogins
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<The permissions of the users for each database>'
DECLARE @DB_USers TABLE(DBName sysname, UserName sysname, LoginType sysname, AssociatedRole varchar(max),create_date datetime,modify_date datetime)

INSERT @DB_USers 
EXEC sp_MSforeachdb 
'use [?];
SELECT ''?'' AS DB_Name,
case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName,
prin.type_desc AS LoginType,
isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,create_date,modify_date
FROM sys.database_principals prin
LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%'''

SELECT dbname,username ,logintype ,create_date ,modify_date ,STUFF((SELECT ',' + CONVERT(VARCHAR(500),associatedrole)
FROM @DB_USers user2 WHERE user1.DBName=user2.DBName AND user1.UserName=user2.UserName FOR XML PATH('') ),1,1,'') AS Permissions_user
FROM @DB_USers user1 GROUP BY dbname,username ,logintype ,create_date ,modify_date ORDER BY DBName,username
GO



PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<Script out any Credentials under Security>'
select   'CREATE CREDENTIAL ' + name + ' WITH IDENTITY = ''' + credential_identity + ''', SECRET = ''<Put Password Here>'';'  from sys.credentials  order by name;
GO

PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List all Server Backup Devices>'
SELECT 'Server[@Name=' + quotename(CAST(serverproperty(N'Servername') AS sysname),'') + ']' + '/BackupDevice[@Name=' + quotename(o.name,'''') + ']' AS [Urn],
o.name AS [Name], case when 1=msdb.dbo.fn_syspolicy_is_automation_enabled() and exists (select * from msdb.dbo.syspolicy_system_health_state 
where target_query_expression_with_id like 'Server/BackupDevice\[@Name=' + QUOTENAME(o.name, '''') + '\]%' ESCAPE '\') then 1 else 0 end AS [PolicyHealthState] 
FROM sys.backup_devices o ORDER BY [Name] ASC
GO

PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List all System and Mirroring endpoints>'
select * from sys.endpoints 
GO

PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List all Linked Servers and their associated login>'
SELECT ss.server_id ,ss.name ,'Server ' = Case ss.Server_id   when 0 then 'Current Server'   else 'Remote Server'   end
,ss.product   ,ss.provider  ,ss.catalog  ,'Local Login ' = case sl.uses_self_credential   when 1 then 'Uses Self Credentials'
else ssp.name end ,'Remote Login Name' = sl.remote_name ,'RPC Out Enabled'    = case ss.is_rpc_out_enabled when 1 then 'True'
else 'False' end ,'Data Access Enabled' = case ss.is_data_access_enabled when 1 then 'True' else 'False' end
,ss.modify_date FROM sys.Servers ss  
LEFT JOIN sys.linked_logins sl ON ss.server_id = sl.server_id
LEFT JOIN sys.server_principals ssp ON ssp.principal_id = sl.local_principal_id
GO

PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<Script out the Logon Triggers of the server, if any exist>'
SELECT SSM.definition FROM sys.server_triggers AS ST JOIN sys.server_sql_modules AS SSM ON ST.object_id = SSM.object_id
GO

PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<REPLICATION – List Publication or Subscription articles>'
IF EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='sysextendedarticlesview') 
(SELECT  sub.srvname,  pub.name, art.name, art.dest_table,art.dest_owner
FROM sysextendedarticlesview art
inner join syspublications pub on (art.pubid = pub.pubid)
inner join syssubscriptions sub on (sub.artid = art.artid))
ELSE SELECT 'No Publication or Subcsription articles were found'
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List all SQL Server Agent jobs>'
USE MSDB
GO
SELECT        srv.srvname,
              sj.name,
              COALESCE(sj.description, ''),
              ss.name,
              ss.schedule_id,
              sc.name,
              ss.freq_type,
              ss.freq_interval,
              ss.freq_subday_type,
              ss.freq_subday_interval,
              ss.freq_relative_interval,
              ss.freq_recurrence_factor,
              COALESCE(STR(ss.active_start_date, 8), CONVERT(CHAR(8), GETDATE(), 112)),
              STUFF(STUFF(REPLACE(STR(ss.active_start_time, 6), ' ', '0'), 3, 0, ':'), 6, 0, ':'),
              STR(ss.active_end_date, 8),
              STUFF(STUFF(REPLACE(STR(ss.active_end_time, 6), ' ', '0'), 3, 0, ':'), 6, 0, ':'),
              sj.enabled,
              ss.enabled
FROM          msdb..sysschedules AS ss
INNER JOIN    msdb..sysjobschedules AS sjs ON sjs.schedule_id = ss.schedule_id
INNER JOIN    msdb..sysjobs AS sj ON sj.job_id = sjs.job_id
INNER JOIN    sys.sysservers AS srv ON srv.srvid = sj.originating_server_id
INNER JOIN    msdb..syscategories AS sc ON sc.category_id = sj.category_id
WHERE         ss.freq_type IN(1, 4, 8, 16, 32)
ORDER BY      srv.srvname,
              sj.name,
              ss.name
GO
USE master
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List of SQL Server Agent – Alerts>'
select * from  msdb.dbo.sysalerts 
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List of SQL Server Agent – Operators>'
SELECT name, email_address, enabled FROM MSDB.dbo.sysoperators ORDER BY name
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'
PRINT '<List of SSIS packages in MSDB>'
USE MSDB
GO
select name, description, createdate from sysssispackages where description not like 'System Data Collector Package'
USE master
GO
PRINT '*******************************************************************************************'
PRINT '*******************************************************************************************'