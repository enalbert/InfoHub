-- Espacio discos y  puntos de montaje
SELECT DISTINCT
    vs.volume_mount_point                                          AS [Punto de Montaje / Unidad],
    vs.logical_volume_name                                         AS [Nombre del Volumen],
    CAST(vs.total_bytes / 1024.0 / 1024.0 / 1024.0 AS NUMERIC(18,2))  AS [Espacio Total (GB)],
    CAST(vs.available_bytes / 1024.0 / 1024.0 / 1024.0 AS NUMERIC(18,2)) AS [Espacio Libre (GB)],
    CAST((vs.total_bytes - vs.available_bytes) / 1024.0 / 1024.0 / 1024.0 AS NUMERIC(18,2)) AS [Espacio Usado (GB)],
    CAST(vs.available_bytes * 100.0 / vs.total_bytes AS NUMERIC(5,2))   AS [% Libre],
    CAST((vs.total_bytes - vs.available_bytes) * 100.0 / vs.total_bytes AS NUMERIC(5,2)) AS [% Usado]
FROM sys.master_files AS mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) AS vs
ORDER BY [Punto de Montaje / Unidad];

PRINT '========== TOP FICHEROS POR ESPACIO REALMENTE USADO (Datos y Log) =============='
PRINT ''
 
IF OBJECT_ID('tempdb..#FileUsage') IS NOT NULL DROP TABLE #FileUsage
 
CREATE TABLE #FileUsage (
    BaseDatos       SYSNAME,
    NombreLogico    SYSNAME,
    RutaFisica      NVARCHAR(520),
    Tipo            VARCHAR(10),
    TamanioAsignadoMB NUMERIC(18,2),
    EspacioUsadoMB    NUMERIC(18,2),
    EspacioLibreMB    NUMERIC(18,2),
    PorcentajeUsado   NUMERIC(5,2)
)
 
EXEC sp_MSforeachdb '
USE [?];
INSERT INTO #FileUsage
SELECT
    DB_NAME() AS BaseDatos,
    name AS NombreLogico,
    physical_name AS RutaFisica,
    CASE type WHEN 0 THEN ''DATOS'' WHEN 1 THEN ''LOG'' ELSE ''OTRO'' END AS Tipo,
    CAST(size / 128.0 AS NUMERIC(18,2)) AS TamanioAsignadoMB,
    CAST(FILEPROPERTY(name, ''SpaceUsed'') / 128.0 AS NUMERIC(18,2)) AS EspacioUsadoMB,
    CAST((size - FILEPROPERTY(name, ''SpaceUsed'')) / 128.0 AS NUMERIC(18,2)) AS EspacioLibreMB,
    CAST(FILEPROPERTY(name, ''SpaceUsed'') * 100.0 / size AS NUMERIC(5,2)) AS PorcentajeUsado
FROM sys.database_files
WHERE type IN (0,1);
'
 
SELECT
    BaseDatos           AS [Base de Datos],
    NombreLogico         AS [Nombre Lógico],
    RutaFisica           AS [Ruta Física],
    Tipo                 AS [Tipo],
    TamanioAsignadoMB    AS [Tamaño Asignado (MB)],
    EspacioUsadoMB       AS [Espacio Usado (MB)],
    EspacioLibreMB       AS [Espacio Libre Interno (MB)],
    PorcentajeUsado      AS [% Usado]
FROM #FileUsage
ORDER BY EspacioUsadoMB DESC;
 
PRINT ''
PRINT '--- Top 10 con más espacio LIBRE interno (candidatos a SHRINK) ---'
 
SELECT TOP 10
    BaseDatos           AS [Base de Datos],
    NombreLogico         AS [Nombre Lógico],
    Tipo                 AS [Tipo],
    TamanioAsignadoMB    AS [Tamaño Asignado (MB)],
    EspacioUsadoMB       AS [Espacio Usado (MB)],
    EspacioLibreMB       AS [Espacio Libre Interno (MB)],
    PorcentajeUsado      AS [% Usado]
FROM #FileUsage
ORDER BY EspacioLibreMB DESC;
 
DROP TABLE #FileUsage
 
PRINT ''
PRINT ''
 
-- ============================================================================
-- OPCIÓN 3: Resumen rápido de espacio de LOG (método nativo DBCC)
-- ============================================================================
PRINT '========== RESUMEN DE ESPACIO DE LOG (DBCC SQLPERF) =============='
PRINT ''
 
DBCC SQLPERF(LOGSPACE);
 