
USE [medical]
GO 
IF OBJECT_ID('MCdbLASTRUN') IS NOT NULL DROP TABLE [dbo].[MCdbLASTRUN] 
CREATE TABLE MCdbLASTRUN ([LASTRUN] [VARCHAR](MAX) NOT NULL) 
INSERT INTO MCdbLASTRUN SELECT DATENAME(MONTH,GETDATE())+' '+DATENAME(DAY,GETDATE())+', '+DATENAME(YEAR,GETDATE())
+' @ '+FORMAT(GETDATE(),'hh')+':'+FORMAT(GETDATE(),'mm')+':'+FORMAT(GETDATE(),N'tt'); --SELECT * FROM MCdbLASTRUN
GO 
IF OBJECT_ID('MCdbVER') IS NOT NULL DROP TABLE [dbo].[MCdbVER] 
CREATE TABLE MCdbVER ([VERSION] [VARCHAR](MAX) NOT NULL) 
INSERT INTO MCdbVER SELECT @@VERSION; --SELECT * FROM MCdbVER
GO 
IF OBJECT_ID('MCdbWAITS') IS NOT NULL DROP TABLE [dbo].[MCdbWAITS] 
CREATE TABLE MCdbWAITS ([WAITS] [VARCHAR](MAX) NOT NULL) 
GO 
WITH [Waits] AS
(SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
       100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', 
N'CHECKPOINT_QUEUE', N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE', 
 -- Maybe comment these four out if you have mirroring issues
N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', 
N'DISPATCHER_QUEUE_SEMAPHORE', N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX', 
 -- Maybe comment these six out if you have AG issues
N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE', 
N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE', N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT', 
N'ONDEMAND_TASK_QUEUE', N'PREEMPTIVE_XE_GETTARGETSTATE', N'PWAIT_ALL_COMPONENTS_INITIALIZED', 
N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE', 
N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK', 
N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP', 
N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY', N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', 
N'SLEEP_SYSTEMTASK', N'SLEEP_TASK', N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP', 
N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS', N'WAITFOR', 
N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_RECOVERY', N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', 
N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN', N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
AND [waiting_tasks_count] > 0)
INSERT INTO MCdbWAITS SELECT '<a href="https://app.spotlightcloud.io/waitopedia/waits/'+LOWER(MAX ([W1].[wait_type]))+'">
<font color="#008000">'+LOWER(MAX ([W1].[wait_type]))+' -- '+ 
    --MAX ([W1].[WaitCount]) AS [WaitCount], 
	CONVERT(CHAR,CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)))+' %</a><br>' 
	--CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S], 
    --CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S], 
	--CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S], 
    --CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S], 
	--CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
    --CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S],
    --CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
FROM [Waits] AS [W1] INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum] HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; --SELECT * FROM MCdbWAITS
GO 
IF OBJECT_ID('MCdbSIGRES') IS NOT NULL DROP TABLE [dbo].[MCdbSIGRES] 
CREATE TABLE MCdbSIGRES ([SIG] [VARCHAR](MAX) NOT NULL,[RES] [VARCHAR](MAX) NOT NULL) 
GO 
INSERT INTO MCdbSIGRES SELECT '
<font color="#0046BF">Signal (CPU) Waits: 
<font color="#008000">'
+CONVERT(CHAR,CAST(100.0 * SUM(signal_wait_time_ms) / 
SUM(wait_time_ms) AS NUMERIC(20,2)))+'%' AS [%signal (cpu) waits] , '<br>  
<font color="#0046BF">Resource Waits: 
<font color="#008000">'
+CONVERT(CHAR,CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / 
SUM(wait_time_ms) AS NUMERIC(20, 2)))+'%' AS [%resource waits]
FROM sys.dm_os_wait_stats; --SELECT * FROM MCdbSIGRES
GO 
IF OBJECT_ID('MCdbCPUSTATS') IS NOT NULL DROP TABLE [dbo].[MCdbCPUSTATS] 
CREATE TABLE MCdbCPUSTATS ([db] [VARCHAR](MAX) NOT NULL,[CPUSTATS] [VARCHAR](MAX) NOT NULL) 
GO 
WITH DB_CPU_Stats AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_worker_time) AS [CPU_Time_Ms]
 FROM sys.dm_exec_query_stats AS qs
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID)
INSERT INTO MCdbCPUSTATS SELECT DatabaseName+' -- '
,RTRIM(CONVERT(CHAR,CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2))))+' %<br>'
FROM DB_CPU_Stats WHERE DatabaseName IS NOT NULL 
ORDER BY CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) DESC; 
--SELECT dbCPUSTATS=DB+CPUSTATS FROM MCdbCPUSTATS ORDER BY CPUSTATS DESC
GO 
IF OBJECT_ID('MCdbPLERES') IS NOT NULL DROP TABLE [dbo].[MCdbPLERES] 
CREATE TABLE MCdbPLERES ([COLOR] [VARCHAR](MAX) NULL,[NAME] [VARCHAR](MAX) NOT NULL) 
GO 
INSERT INTO MCdbPLERES SELECT DISTINCT COLOR=
CASE WHEN [counter_name] = 'Page life expectancy' AND [cntr_value] >=2400 THEN '<font color="#008000">' 
     WHEN [counter_name] = 'Page life expectancy' AND [cntr_value] BETWEEN 2400 AND 901 THEN '<font color="#FF6600">' 
     WHEN [counter_name] = 'Page life expectancy' AND [cntr_value] <=900 THEN '<font color="#FF0000">' 
     WHEN [counter_name] = 'Buffer cache hit ratio' AND [cntr_value] >=95 THEN '<font color="#008000">' 
     WHEN [counter_name] = 'Buffer cache hit ratio' AND [cntr_value] < 94 THEN '<font color="#FF0000">' END 
,NAME=RTRIM([counter_name])+' -- '+RTRIM(CONVERT(CHAR,[cntr_value]))+'<br>
<font color="#008000">' 
FROM sys.dm_os_performance_counters 
WHERE [counter_name] = 'Page life expectancy' 
OR [counter_name] = 'Free list stalls/sec' 
OR [counter_name] = 'Lazy writes/sec' 
OR [counter_name] = 'Buffer cache hit ratio' ORDER BY NAME; --SELECT * FROM MCdbPLERES ORDER BY NAME
GO 
USE MEDICAL 
IF OBJECT_ID('MCdbSIZE') IS NOT NULL DROP TABLE [dbo].[MCdbSIZE] CREATE TABLE MCdbSIZE (
[Database] [VARCHAR](MAX) NULL,[Size] [INT] NULL) 
GO 
INSERT INTO MCdbSIZE 
SELECT '<br>'+d.name+' -- ' AS 'Database',sum(m.size * 8/1024) 'Size'
FROM sys.master_files m 
INNER JOIN sys.databases d ON d.database_id = m.database_id
group by d.name order by 'Size' desc; 
--SELECT * FROM MCdbSIZE ORDER BY SIZE DESC
--SELECT 'Total: ',SUM(SIZE)/1000,'GB' FROM MCdbSIZE
GO 
IF OBJECT_ID('MCdbMEMCLERK') IS NOT NULL DROP TABLE [dbo].[MCdbMEMCLERK] 
CREATE TABLE MCdbMEMCLERK ([MEMCLERK] [VARCHAR](MAX) NULL) 
GO 
INSERT INTO MCdbMEMCLERK SELECT TOP(10) '<br>'+LOWER(mc.[type])+' -- '+ 
       CONVERT(CHAR,CAST((SUM(mc.pages_kb)/1024.0) AS DECIMAL (15, 2))) AS [MEMCLERK] 
FROM sys.dm_os_memory_clerks AS mc WITH (NOLOCK)
GROUP BY mc.[type] ORDER BY SUM(mc.pages_kb) DESC OPTION (RECOMPILE); --SELECT * FROM MCdbMEMCLERK
GO 
IF OBJECT_ID('tempdb..#MAILCOUNT') IS NOT NULL DROP TABLE [dbo].[#MAILCOUNT] 
SELECT total=COUNT(sent_status),sent_status INTO #MAILCOUNT FROM msdb.dbo.sysmail_allitems 
WHERE mailitem_id IN (
SELECT TOP 50 mailitem_id FROM msdb.dbo.sysmail_allitems ORDER BY mailitem_id DESC) GROUP BY sent_status
GO
IF OBJECT_ID('MCdbMAILSTATUS') IS NOT NULL DROP TABLE [dbo].[MCdbMAILSTATUS] 
CREATE TABLE MCdbMAILSTATUS ([MAILSTATUS] [VARCHAR](MAX) NULL) 
GO 
INSERT INTO MCdbMAILSTATUS SELECT 'db-Mail Status'=CASE WHEN (
SELECT top 1 sent_status from #MAILCOUNT order by total desc) LIKE '%fail%' THEN '<font color="#FF0000">Failure @ '+
(SELECT RTRIM(CONVERT(CHAR,((SELECT CONVERT(FLOAT,total) FROM #MAILCOUNT WHERE sent_status='fail')/(
SELECT CONVERT(FLOAT,SUM(total)) FROM #MAILCOUNT)) * 100)) +' %') ELSE '<font color="#008000">Functional @ '+
(SELECT RTRIM(CONVERT(CHAR,((SELECT CONVERT(FLOAT,total) FROM #MAILCOUNT WHERE sent_status='sent')/(
SELECT CONVERT(FLOAT,SUM(total)) FROM #MAILCOUNT)) * 100)) +' %') END
GO
--SELECT * FROM #MAILCOUNT
--SELECT * FROM MCdbMAILSTATUS
GO 
IF OBJECT_ID('MCdbAVGTEMPSTALL') IS NOT NULL DROP TABLE [dbo].[MCdbAVGTEMPSTALL] 
CREATE TABLE MCdbAVGTEMPSTALL ([AVGTEMPSTALL] [VARCHAR](MAX) NULL) 
GO 
INSERT INTO MCdbAVGTEMPSTALL SELECT 'Average Temb db Stall'=rtrim(convert(char,cast(avg(1.0 * stats.io_stall_read_ms / stats.num_of_reads) 
AS DECIMAL (5,2))))+' (ms)' FROM master.sys.dm_io_virtual_file_stats(2, NULL) as stats
INNER JOIN master.sys.master_files AS files ON stats.database_id = files.database_id AND stats.file_id = files.file_id
WHERE files.type_desc = 'ROWS';--SELECT * FROM MCdbAVGTEMPSTALL
GO 
IF OBJECT_ID('MCdbBLOCKEDSESSIONS') IS NOT NULL DROP TABLE [dbo].[MCdbBLOCKEDSESSIONS] 
CREATE TABLE MCdbBLOCKEDSESSIONS ([SESSIONID] [VARCHAR](MAX) NULL) 
GO 
WITH [Blocking]
AS (SELECT w.[session_id],s.[original_login_name],s.[login_name],w.[wait_duration_ms],w.[wait_type]
          ,r.[status],r.[wait_resource],w.[resource_description],s.[program_name],w.[blocking_session_id]
          ,s.[host_name],r.[command],r.[percent_complete],r.[cpu_time],r.[total_elapsed_time],r.[reads]
          ,r.[writes],r.[logical_reads],r.[row_count],q.[text],q.[dbid],p.[query_plan],r.[plan_handle]
 FROM [sys].[dm_os_waiting_tasks] w
 INNER JOIN [sys].[dm_exec_sessions] s ON w.[session_id] = s.[session_id]
 INNER JOIN [sys].[dm_exec_requests] r ON s.[session_id] = r.[session_id]
 CROSS APPLY [sys].[dm_exec_sql_text](r.[plan_handle]) q
 CROSS APPLY [sys].[dm_exec_query_plan](r.[plan_handle]) p
 WHERE w.[session_id] > 50 AND w.[wait_type] NOT IN ('DBMIRROR_DBM_EVENT','ASYNC_NETWORK_IO'))
INSERT INTO MCdbBLOCKEDSESSIONS SELECT [WaitingSessionID]='<br>'+CONVERT(CHAR,b.[session_id])+''+b.[blocking_session_id]+''
+b.[login_name]+''+s1.[login_name]+''+b.[original_login_name]+''+s1.[original_login_name]+''+b.[wait_duration_ms]
      --,b.[wait_type] AS [WaitType],t.[request_mode] AS [WaitRequestMode],UPPER(b.[status]) AS [WaitingProcessStatus]
      --,UPPER(s1.[status]) AS [BlockingSessionStatus],b.[wait_resource] AS [WaitResource]
      --,t.[resource_type] AS [WaitResourceType],t.[resource_database_id] AS [WaitResourceDatabaseID]
      --,DB_NAME(t.[resource_database_id]) AS [WaitResourceDatabaseName]
      --,b.[resource_description] AS [WaitResourceDescription],b.[program_name] AS [WaitingSessionProgramName]
      --,s1.[program_name] AS [BlockingSessionProgramName],b.[host_name] AS [WaitingHost]
      --,s1.[host_name] AS [BlockingHost],b.[command] AS [WaitingCommandType],b.[text] AS [WaitingCommandText]
      --,b.[row_count] AS [WaitingCommandRowCount],b.[percent_complete] AS [WaitingCommandPercentComplete]
      --,b.[cpu_time] AS [WaitingCommandCPUTime],b.[total_elapsed_time] AS [WaitingCommandTotalElapsedTime]
      --,b.[reads] AS [WaitingCommandReads],b.[writes] AS [WaitingCommandWrites]
      --,b.[logical_reads] AS [WaitingCommandLogicalReads],b.[query_plan] AS [WaitingCommandQueryPlan]
      --,b.[plan_handle] AS [WaitingCommandPlanHandle]
FROM [Blocking] b INNER JOIN [sys].[dm_exec_sessions] s1 ON b.[blocking_session_id] = s1.[session_id]
                  INNER JOIN [sys].[dm_tran_locks] t     ON t.[request_session_id] = b.[session_id]
WHERE t.[request_status] = 'WAIT';-- SELECT * FROM MCdbBLOCKEDSESSIONS
GO

grant SELECT on MCdbLASTRUN to mwuser 
grant SELECT on MCdbVER to mwuser 
grant SELECT on MCdbWAITS to mwuser 
grant SELECT on MCdbSIGRES to mwuser 
grant SELECT on MCdbCPUSTATS to mwuser 
grant SELECT on MCdbPLERES to mwuser 
grant SELECT on MCdbSIZE to mwuser 
grant SELECT on MCdbMEMCLERK to mwuser 
grant SELECT on MCdbMAILSTATUS to mwuser 
grant SELECT on MCdbAVGTEMPSTALL to mwuser 
grant SELECT on MCdbBLOCKEDSESSIONS to mwuser 
