
/*
  16_import_csv_examples.sql
  Purpose: Demonstrate a SQL-based CSV import into a staging table, validate
           types, and preview clean rows before loading a target table.
  Database context: WealthManagementOperations.
  Manual step: Replace @ClientsCsvPath with the absolute path visible to the
               SQL Server service. The path is read by SQL Server, not SSMS.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

DECLARE @ClientsCsvPath nvarchar(4000) =
    N'C:\REPLACE_WITH_PROJECT_PATH\data\clients.csv';

IF OBJECT_ID('tempdb..#ClientsCsvStage') IS NOT NULL
    DROP TABLE #ClientsCsvStage;

CREATE TABLE #ClientsCsvStage
(
    ClientIDText       nvarchar(50) NULL,
    ClientCode         nvarchar(50) NULL,
    FirstName          nvarchar(100) NULL,
    LastName           nvarchar(100) NULL,
    Email              nvarchar(300) NULL,
    StateCode          nvarchar(20) NULL,
    AdvisorIDText      nvarchar(50) NULL,
    ClientSinceText    nvarchar(50) NULL,
    IsActiveText       nvarchar(50) NULL
);

DECLARE @BulkSql nvarchar(max) = N'
BULK INSERT #ClientsCsvStage
FROM ' + QUOTENAME(@ClientsCsvPath, '''') + N'
WITH
(
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDQUOTE = ''"'',
    CODEPAGE = ''65001'',
    TABLOCK
);';

PRINT N'Edit @ClientsCsvPath before executing the BULK INSERT.';
PRINT @BulkSql;

/*
  Remove the comment markers around EXEC only after editing the path.

  EXEC sys.sp_executesql @BulkSql;
*/

/* Validation preview after a successful BULK INSERT */
SELECT
    TRY_CONVERT(int, ClientIDText) AS ClientID,
    NULLIF(LTRIM(RTRIM(ClientCode)), N'') AS ClientCode,
    NULLIF(LTRIM(RTRIM(FirstName)), N'') AS FirstName,
    NULLIF(LTRIM(RTRIM(LastName)), N'') AS LastName,
    NULLIF(LTRIM(RTRIM(Email)), N'') AS Email,
    UPPER(NULLIF(LTRIM(RTRIM(StateCode)), N'')) AS StateCode,
    TRY_CONVERT(int, AdvisorIDText) AS AdvisorID,
    TRY_CONVERT(date, ClientSinceText) AS ClientSince,
    CASE
        WHEN LOWER(IsActiveText) IN ('1','true','yes') THEN CONVERT(bit, 1)
        WHEN LOWER(IsActiveText) IN ('0','false','no') THEN CONVERT(bit, 0)
        ELSE NULL
    END AS IsActive
FROM #ClientsCsvStage;

/* Invalid-row report */
SELECT *
FROM #ClientsCsvStage
WHERE TRY_CONVERT(int, ClientIDText) IS NULL
   OR NULLIF(LTRIM(RTRIM(ClientCode)), N'') IS NULL
   OR NULLIF(LTRIM(RTRIM(FirstName)), N'') IS NULL
   OR NULLIF(LTRIM(RTRIM(LastName)), N'') IS NULL
   OR LEN(LTRIM(RTRIM(StateCode))) <> 2
   OR TRY_CONVERT(int, AdvisorIDText) IS NULL
   OR TRY_CONVERT(date, ClientSinceText) IS NULL
   OR LOWER(IsActiveText) NOT IN ('1','0','true','false','yes','no');
GO

PRINT N'CSV staging demonstration prepared. BULK INSERT remains disabled until the path is reviewed and EXEC is enabled.';
GO
