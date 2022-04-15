/***********************

	Configure

***********************/

DECLARE @company varchar(10),
		@category varchar(100),
		@name varchar(100),
		@detail bit

SELECT	@company = 'MAIN',
		@category = '%',
		@name = '%'

/***********************

	Setup

***********************/

if (object_id('tempdb..#results')) is not null
	drop table #results

CREATE TABLE #results (
	category varchar(100),
	name varchar(100),
	value varchar(2000)
)

/***********************

	General 

***********************/

--Connection Info
	insert into #results
		SELECT '_General', 'Servername', @@SERVERNAME;

-- Version of SQL Server
	insert into #results
		select '_General', 'Version', @@version;

/***********************

	SQL Server Agent 

*************************/

-- Agent Alerts
	insert into #results
		select 'Agent', 'Alerts' , cast(count(*) as varchar(10)) from msdb.dbo.sysalerts

-- Operators
	insert into #results
		select 'Agent', 'Operators', cast(count(*) as varchar(10)) from msdb.dbo.sysoperators

-- Proxies
	insert into #results
		select 'Agent', 'Proxies', cast(count(*) as varchar(10)) from msdb.dbo.sysproxies

-- Jobs 
	insert into #results
		select 'Agent', 'Jobs', cast(count(*) as varchar(10)) from msdb.dbo.sysjobs

--SSIS packages
	insert into #results
		select 'Agent', 'SSIS Packages in MSDB', cast(count(*) as varchar(10)) from msdb.dbo.sysssispackages

/***********************

	Management 

*************************/

-- Data Collector Collection Sets - In a Running/Paused State
	insert into #results
		select 'Management', 'DataCollector Sets - Running/Paused', cast(count(*) as varchar(10)) 
		from msdb.dbo.syscollector_collection_sets_internal where is_running = 1

-- Extended Event Sessions

	-- Running
	insert into #results
		SELECT 'Management', 'ExtendedEventSessions - Running', cast(count(*) as varchar(10)) 
		FROM 
			sys.server_event_sessions AS session
			LEFT OUTER JOIN sys.dm_xe_sessions AS running 
				ON running.name = session.name
		WHERE
			(CASE WHEN (running.create_time IS NULL) THEN 0 ELSE 1 END) = 1

	--Stopped
	insert into #results
		SELECT 'Management', 'ExtendedEventSessions - Stopped', cast(count(*) as varchar(10)) 
		FROM 
			sys.server_event_sessions AS session
			LEFT OUTER JOIN sys.dm_xe_sessions AS running 
				ON running.name = session.name
		WHERE
			(CASE WHEN (running.create_time IS NULL) THEN 0 ELSE 1 END) = 0

-- DB Mail Profile
	insert into #results
		select 'Management', 'DB Mail Profiles', cast(count(*) as varchar(10)) from msdb.dbo.sysmail_profile	

-- DB Mail Account
	insert into #results
		select 'Management', 'DB Mail Accounts', cast(count(*) as varchar(10)) from msdb.dbo.sysmail_account

/***********************

	Server Objects

*************************/

-- All Servers
	insert into #results
		SELECT 'Server Objects', 'Servers', cast(count(*) as varchar(10)) FROM sys.Servers a

-- All Endpoints
	insert into #results
		select 'Server Objects', 'Endpoints', cast(count(*) as varchar(10)) from sys.endpoints

-- All Backup Devices
	insert into #results
		select 'Server Objects', 'Backup Devices', cast(count(*) as varchar(10)) from sys.backup_devices

-- Server Triggers
	insert into #results	
		select 'Server Objects', 'Server Triggers', cast(count(*) as varchar(10)) from sys.server_triggers

/***********************

	Security 

*************************/
-- SQL Logins
	insert into #results
		select 'Security', 'SQL Logins', cast(count(*) as varchar(10)) from sys.server_principals where type = 'S'

-- Windows Logins
	insert into #results
		select 'Security', 'Windows Logins', cast(count(*) as varchar(10)) from sys.server_principals where type = 'U'

-- Windows Group Logins
	insert into #results
		select 'Security', 'Windows Group Logins', cast(count(*) as varchar(10)) from sys.server_principals where type = 'G'

-- Credentials
	insert into #results
		select 'Security', 'Credentials', cast(count(*) as varchar(10)) from sys.credentials

/***********************

	MI Specific Info

*************************/

-- ERX
	insert into #results
		select 'MI', 'ERX', case when count(*) > 0 then 1 else 0 end 
		from clparms 
		where code like '%erx%' and skey like 'up' and company = @company

--Dashboard
	insert into #results
		select 'MI', 'Dashboard', case when count(*) > 0 then 1 else 0 end 
		from msdb.dbo.sysjobs 
		where name like '%PopulateMedinfoSSAS%' and enabled = 1 

--PatientPortal
	insert into #results
		select 'MI', 'Patient Portal - SQL Jobs', case when count(*) > 0 then 1 else 0 end  
		from msdb.dbo.sysjobs 
		where name like '%Portal%' and enabled = 1	

-- Ola Hallengren's Maintenance Strategy Installed
	insert into #results
		select 'MI', 'Ola Hallengren''s Maintenance Strategy', case when count(*) > 0 then 1 else 0 end 
		from master.sys.objects 
		where name in ('IndexOptimize', 'CommandExecute', 'DatabaseBackup', 'DatabaseIntegrityCheck', 'CommandLog')

/***********************

	Display Results

*************************/

select * from #results
where category like @category
	and name like @name
order by category, name, value

