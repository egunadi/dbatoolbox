# old server

$params = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    Database = 'medical'
    BackupLocation = 'E:\MED_SQL_BCK'
    CleanupTime = 96
    ReplaceExisting = $true
    InstallJobs = $true
    Verbose = $true
}
Install-DbaMaintenanceSolution @params 

$schedulesplat = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    Schedule = 'WorkingWeek-2am'
    FrequencyType = 'Weekly'
    FrequencyInterval = 'Weekdays'
    StartTime = '020036'
    Force = $true
    Job = 'DatabaseBackup - USER_DATABASES - FULL'
}
New-DbaAgentSchedule @schedulesplat

Remove-DbaAgentJob -SqlInstance 'D6HV63W1' -SqlCredential $cred -Job 'DatabaseBackup - SYSTEM_DATABASES - FULL'

Remove-DbaAgentJob -SqlInstance 'D6HV63W1' -SqlCredential $cred -Job 'DatabaseBackup - USER_DATABASES - DIFF'

Remove-DbaAgentJob -SqlInstance 'D6HV63W1' -SqlCredential $cred -Job 'DatabaseIntegrityCheck - SYSTEM_DATABASES'

$schedulesplat = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    FrequencyType = 'Weekly'
    FrequencyInterval = 'Weekdays'
    Schedule = 'WorkingWeek-Every-30-Minutes'
    Force = $true
    StartTime = '060036'
    EndTime = '210000'
    FrequencySubdayInterval = 30
    FrequencySubdayType = 'Minutes'
    Job = 'DatabaseBackup - USER_DATABASES - LOG'
}
New-DbaAgentSchedule @schedulesplat

$schedulesplat = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    Schedule = 'Weekly-Saturday-Midnight'
    FrequencyType = 'Weekly'
    FrequencyInterval = 'Saturday'
    StartTime = '000248'
    Force = $true
    Job = 'DatabaseIntegrityCheck - USER_DATABASES'
}
New-DbaAgentSchedule @schedulesplat

$schedulesplat = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    Schedule = 'Weekly-Saturday-3am'
    FrequencyType = 'Weekly'
    FrequencyInterval = 'Saturday'
    StartTime = '030248'
    Force = $true
    Job = 'IndexOptimize - USER_DATABASES'
}
New-DbaAgentSchedule @schedulesplat

$schedulesplat = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    Schedule = 'Weekly-Saturday-10pm'
    FrequencyType = 'Weekly'
    FrequencyInterval = 'Saturday'
    StartTime = '220248'
    Force = $true
    Job = 'CommandLog Cleanup'
}
New-DbaAgentSchedule @schedulesplat

$schedulesplat = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    Schedule = 'Weekly-Sunday-10pm'
    FrequencyType = 'Weekly'
    FrequencyInterval = 'Sunday'
    StartTime = '220248'
    Force = $true
    Job = 'Output File Cleanup'
}
New-DbaAgentSchedule @schedulesplat

$schedulesplat = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    Schedule = 'Weekly-Saturday-2am'
    FrequencyType = 'Weekly'
    FrequencyInterval = 'Saturday'
    StartTime = '020248'
    Force = $true
    Job = 'sp_delete_backuphistory'
}
New-DbaAgentSchedule @schedulesplat

$schedulesplat = @{
    SqlInstance = 'D6HV63W1'
    SqlCredential = $cred
    Schedule = 'Weekly-Sunday-2am'
    FrequencyType = 'Weekly'
    FrequencyInterval = 'Sunday'
    StartTime = '020248'
    Force = $true
    Job = 'sp_purge_jobhistory'
}
New-DbaAgentSchedule @schedulesplat











