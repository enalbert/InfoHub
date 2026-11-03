/* ============================================================
   instance_info.sql
   Basic SQL Server instance information
   READ ONLY
   ============================================================ */

SET NOCOUNT ON;

---------------------------------------------------------------
-- 1. Instance information
---------------------------------------------------------------
SELECT
    @@SERVERNAME AS server_name,
    SERVERPROPERTY('MachineName') AS machine_name,
    SERVERPROPERTY('InstanceName') AS instance_name,
    SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS physical_machine_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('ProductLevel') AS product_level,
    SERVERPROPERTY('ProductUpdateLevel') AS product_update_level,
    SERVERPROPERTY('Edition') AS edition,
    SERVERPROPERTY('EngineEdition') AS engine_edition,
    SERVERPROPERTY('IsClustered') AS is_clustered,
    SERVERPROPERTY('IsHadrEnabled') AS is_hadr_enabled;

---------------------------------------------------------------
-- 2. SQL Server startup / uptime
-- Requires VIEW SERVER STATE on many SQL Server versions
---------------------------------------------------------------
SELECT
    sqlserver_start_time,
    DATEDIFF(DAY, sqlserver_start_time, GETDATE()) AS uptime_days
FROM sys.dm_os_sys_info;

---------------------------------------------------------------
-- 3. CPU and memory visible to SQL Server
---------------------------------------------------------------
SELECT
    cpu_count,
    hyperthread_ratio,
    physical_memory_kb / 1024 AS physical_memory_mb,
    committed_kb / 1024 AS committed_memory_mb,
    committed_target_kb / 1024 AS committed_target_memory_mb
FROM sys.dm_os_sys_info;

---------------------------------------------------------------
-- 4. SQL Server process memory
---------------------------------------------------------------
SELECT
    physical_memory_in_use_kb / 1024 AS sql_memory_in_use_mb,
    locked_page_allocations_kb / 1024 AS locked_pages_mb,
    large_page_allocations_kb / 1024 AS large_pages_mb,
    memory_utilization_percentage,
    available_commit_limit_kb / 1024 AS available_commit_limit_mb,
    process_physical_memory_low,
    process_virtual_memory_low
FROM sys.dm_os_process_memory;

---------------------------------------------------------------
-- 5. Relevant instance configuration
---------------------------------------------------------------
SELECT
    name,
    value,
    value_in_use
FROM sys.configurations
WHERE name IN
(
    'min server memory (MB)',
    'max server memory (MB)',
    'max degree of parallelism',
    'cost threshold for parallelism'
)
ORDER BY name;

---------------------------------------------------------------
-- 6. Database status
---------------------------------------------------------------
SELECT
    name AS database_name,
    state_desc,
    recovery_model_desc,
    compatibility_level,
    user_access_desc,
    is_read_only
FROM sys.databases
ORDER BY name;

---------------------------------------------------------------
-- 7. Instant File Initialization (IFI)
---------------------------------------------------------------
SELECT
    servicename,
    instant_file_initialization_enabled
FROM sys.dm_server_services
WHERE servicename LIKE 'SQL Server (%'
   OR servicename = 'SQL Server (MSSQLSERVER)';

---------------------------------------------------------------
-- 8. Lock Pages in Memory (LPIM)
---------------------------------------------------------------
SELECT
    CASE
        WHEN locked_page_allocations_kb > 0
            THEN 'ENABLED / IN USE'
        ELSE 'NOT IN USE'
    END AS lpim_status,
    locked_page_allocations_kb / 1024 AS locked_pages_mb,
    large_page_allocations_kb / 1024 AS large_pages_mb,
    physical_memory_in_use_kb / 1024 AS sql_memory_in_use_mb
FROM sys.dm_os_process_memory;
