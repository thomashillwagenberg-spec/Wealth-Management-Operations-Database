
/*
  15_master_demo.sql
  Purpose: Guided demonstration of CRUD, reporting, procedures, transactions,
           error handling, temporary objects, and auditing.
  Database context: WealthManagementOperations.
  Safety: Demonstration changes are wrapped in outer transactions and rolled
          back. The read-only reports remain available after completion.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'=== DEMO 1: Core SELECT, WHERE, ORDER BY, string and date functions ===';

SELECT TOP (10)
    c.ClientCode,
    CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
    UPPER(c.StateCode) AS StateCode,
    DATEDIFF(YEAR, c.ClientSince, CONVERT(date, SYSUTCDATETIME())) AS ApproximateClientTenureYears,
    reporting.fn_MaskEmail(c.Email) AS MaskedEmail
FROM core.Client AS c
WHERE c.IsActive = 1
ORDER BY c.ClientSince;
GO

PRINT N'=== DEMO 2: INSERT, UPDATE, DELETE, COMMIT/ROLLBACK pattern ===';

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO core.Client
    (
        ClientCode, FirstName, LastName, Email,
        StateCode, AdvisorID, ClientSince
    )
    VALUES
    (
        'CL-DEMO-CRUD', N'Demo', N'Client',
        'demo.client@example.test', 'FL', 1, '2026-07-11'
    );

    UPDATE core.Client
    SET
        LastName = N'Client Updated',
        ModifiedAt = SYSUTCDATETIME()
    WHERE ClientCode = 'CL-DEMO-CRUD';

    SELECT
        ClientCode, FirstName, LastName, Email
    FROM core.Client
    WHERE ClientCode = 'CL-DEMO-CRUD';

    DELETE FROM core.Client
    WHERE ClientCode = 'CL-DEMO-CRUD';

    -- Use COMMIT only when a business change should persist.
    -- This teaching demo deliberately uses ROLLBACK.
    ROLLBACK TRANSACTION;

    PRINT N'CRUD demonstration completed and rolled back.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

PRINT N'=== DEMO 3: Client portfolio stored procedure ===';

EXEC reporting.usp_ClientPortfolioReport
    @ClientID = 1,
    @AsOfDate = '2026-07-10';
GO

PRINT N'=== DEMO 4: Advisor monthly activity stored procedure ===';

EXEC reporting.usp_AdvisorMonthlyActivity
    @AdvisorID = 1,
    @StartDate = '2026-01-01',
    @EndDate = '2026-07-10';
GO

PRINT N'=== DEMO 5: Record a trade, inspect audit log, then roll it back ===';

DECLARE @DemoReference varchar(30) =
    CONCAT('DEMO-', REPLACE(CONVERT(varchar(36), NEWID()), '-', ''));

BEGIN TRY
    BEGIN TRANSACTION;

    EXEC trading.usp_RecordTrade
        @AccountID = 1,
        @TransactionTypeCode = 'BUY',
        @SecurityID = 6,
        @TradeDate = '2026-07-10',
        @SettlementDate = '2026-07-11',
        @Quantity = 2.000000,
        @Price = 55.000000,
        @FeeAmount = 1.00,
        @ExternalReference = @DemoReference,
        @Notes = N'Rolled-back master demonstration trade';

    SELECT TOP (5)
        EventTime, DatabaseUser, ActionName, ObjectName, RecordKey, Details
    FROM audit.ActivityLog
    ORDER BY ActivityLogID DESC;

    ROLLBACK TRANSACTION;

    PRINT N'Trade and related audit row were rolled back by the outer transaction.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

PRINT N'=== DEMO 6: Temporary table for review prioritization ===';

IF OBJECT_ID('tempdb..#ReviewQueue') IS NOT NULL
    DROP TABLE #ReviewQueue;

SELECT
    cd.ClientID,
    cd.ClientCode,
    cd.ClientName,
    cd.OverdueReviewCount,
    cd.OpenAlertCount,
    ra.AlignmentStatus,
    CASE
        WHEN cd.MaximumAlertSeverity IN ('CRITICAL','HIGH') THEN 1
        WHEN cd.OverdueReviewCount > 0 THEN 2
        WHEN ra.AlignmentStatus <> 'ALIGNED' THEN 3
        ELSE 4
    END AS ReviewPriority
INTO #ReviewQueue
FROM reporting.vw_ComplianceDashboard AS cd
INNER JOIN reporting.vw_RiskAlignment AS ra
    ON ra.ClientID = cd.ClientID
WHERE cd.RequiresReview = 1
   OR ra.AlignmentStatus <> 'ALIGNED';

SELECT *
FROM #ReviewQueue
ORDER BY ReviewPriority, ClientCode;
GO

PRINT N'=== DEMO 7: Read-only portfolio and compliance reports ===';

SELECT TOP (10) *
FROM reporting.vw_ClientPortfolioSummary
ORDER BY TotalPortfolioValue DESC;

SELECT *
FROM reporting.vw_RiskAlignment
WHERE AlignmentStatus <> 'ALIGNED'
ORDER BY DeviationPctPoints DESC;

SELECT *
FROM reporting.vw_ComplianceDashboard
WHERE RequiresReview = 1
ORDER BY OverdueReviewCount DESC, OpenAlertCount DESC;
GO

PRINT N'Master demonstration completed. No demonstration data changes were retained.';
GO
