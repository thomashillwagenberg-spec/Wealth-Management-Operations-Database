
/*
  13_validation_tests.sql
  Purpose: Run formal build, data, calculation, transaction, procedure,
           constraint, and security validation tests.
  Database context: WealthManagementOperations.
  Expected result: Every row in the final result set should show PASS.
  Important: This is the engine-level test suite. Run it in SSMS after all
             prior scripts. The packaged project was statically reviewed but
             was not executed against SQL Server in the generation environment.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('tempdb..#ValidationResults') IS NOT NULL
    DROP TABLE #ValidationResults;

CREATE TABLE #ValidationResults
(
    TestID          int IDENTITY(1,1) PRIMARY KEY,
    TestName        nvarchar(150) NOT NULL,
    ExpectedOutcome nvarchar(500) NOT NULL,
    ActualOutcome   nvarchar(500) NOT NULL,
    TestStatus      varchar(10) NOT NULL
);

/* 1. Expected tables */
DECLARE @ExpectedTables TABLE (SchemaName sysname, TableName sysname);
INSERT INTO @ExpectedTables (SchemaName, TableName)
VALUES
('core','Advisor'),
('core','Client'),
('core','RiskProfileType'),
('core','ClientRiskProfile'),
('core','AccountType'),
('core','InvestmentAccount'),
('market','AssetClass'),
('market','Security'),
('market','SecurityPrice'),
('trading','TransactionType'),
('trading','AccountTransaction'),
('trading','CurrentHolding'),
('compliance','ComplianceReview'),
('compliance','ComplianceAlert'),
('audit','ActivityLog');

DECLARE @MissingTableCount int =
(
    SELECT COUNT(*)
    FROM @ExpectedTables AS et
    WHERE OBJECT_ID(QUOTENAME(et.SchemaName) + '.' + QUOTENAME(et.TableName), 'U') IS NULL
);

INSERT INTO #ValidationResults
SELECT
    N'Expected table creation',
    N'All 15 expected base tables exist.',
    CONCAT(15 - @MissingTableCount, N' of 15 expected tables found.'),
    CASE WHEN @MissingTableCount = 0 THEN 'PASS' ELSE 'FAIL' END;

/* 2. Expected row counts */
DECLARE @CountFailures int = 0;
DECLARE @ActualCounts nvarchar(500);

SELECT @CountFailures =
      CASE WHEN (SELECT COUNT(*) FROM core.Advisor) = 5 THEN 0 ELSE 1 END
    + CASE WHEN (SELECT COUNT(*) FROM core.Client) = 30 THEN 0 ELSE 1 END
    + CASE WHEN (SELECT COUNT(*) FROM core.InvestmentAccount) = 50 THEN 0 ELSE 1 END
    + CASE WHEN (SELECT COUNT(*) FROM market.Security) = 25 THEN 0 ELSE 1 END
    + CASE WHEN (SELECT COUNT(*) FROM market.SecurityPrice) = 175 THEN 0 ELSE 1 END
    + CASE WHEN (SELECT COUNT(*) FROM trading.AccountTransaction) = 403 THEN 0 ELSE 1 END
    + CASE WHEN (SELECT COUNT(*) FROM trading.CurrentHolding) = 300 THEN 0 ELSE 1 END
    + CASE WHEN (SELECT COUNT(*) FROM compliance.ComplianceReview) = 40 THEN 0 ELSE 1 END
    + CASE WHEN (SELECT COUNT(*) FROM compliance.ComplianceAlert) = 25 THEN 0 ELSE 1 END;

SET @ActualCounts = CONCAT
(
    N'Advisors=', (SELECT COUNT(*) FROM core.Advisor),
    N'; Clients=', (SELECT COUNT(*) FROM core.Client),
    N'; Accounts=', (SELECT COUNT(*) FROM core.InvestmentAccount),
    N'; Securities=', (SELECT COUNT(*) FROM market.Security),
    N'; Prices=', (SELECT COUNT(*) FROM market.SecurityPrice),
    N'; Transactions=', (SELECT COUNT(*) FROM trading.AccountTransaction),
    N'; Holdings=', (SELECT COUNT(*) FROM trading.CurrentHolding),
    N'; Reviews=', (SELECT COUNT(*) FROM compliance.ComplianceReview),
    N'; Alerts=', (SELECT COUNT(*) FROM compliance.ComplianceAlert)
);

INSERT INTO #ValidationResults
VALUES
(
    N'Expected synthetic row counts',
    N'5 advisors; 30 clients; 50 accounts; 25 securities; 175 prices; 403 transactions; 300 holdings; 40 reviews; 25 alerts.',
    @ActualCounts,
    CASE WHEN @CountFailures = 0 THEN 'PASS' ELSE 'FAIL' END
);

/* 3. Foreign-key health and trust */
DECLARE @UntrustedForeignKeys int =
(
    SELECT COUNT(*)
    FROM sys.foreign_keys
    WHERE is_disabled = 1 OR is_not_trusted = 1
);

DECLARE @OrphanCount int =
      (SELECT COUNT(*) FROM core.Client AS c LEFT JOIN core.Advisor AS a ON a.AdvisorID = c.AdvisorID WHERE a.AdvisorID IS NULL)
    + (SELECT COUNT(*) FROM core.InvestmentAccount AS ia LEFT JOIN core.Client AS c ON c.ClientID = ia.ClientID WHERE c.ClientID IS NULL)
    + (SELECT COUNT(*) FROM core.InvestmentAccount AS ia LEFT JOIN core.Advisor AS a ON a.AdvisorID = ia.AdvisorID WHERE a.AdvisorID IS NULL)
    + (SELECT COUNT(*) FROM market.SecurityPrice AS sp LEFT JOIN market.Security AS s ON s.SecurityID = sp.SecurityID WHERE s.SecurityID IS NULL)
    + (SELECT COUNT(*) FROM trading.AccountTransaction AS atx LEFT JOIN core.InvestmentAccount AS ia ON ia.AccountID = atx.AccountID WHERE ia.AccountID IS NULL)
    + (SELECT COUNT(*) FROM trading.CurrentHolding AS ch LEFT JOIN market.Security AS s ON s.SecurityID = ch.SecurityID WHERE s.SecurityID IS NULL)
    + (SELECT COUNT(*) FROM compliance.ComplianceReview AS cr LEFT JOIN core.Client AS c ON c.ClientID = cr.ClientID WHERE c.ClientID IS NULL)
    + (SELECT COUNT(*) FROM compliance.ComplianceAlert AS ca LEFT JOIN core.Client AS c ON c.ClientID = ca.ClientID WHERE c.ClientID IS NULL);

INSERT INTO #ValidationResults
VALUES
(
    N'Foreign-key integrity',
    N'No orphaned rows; all foreign keys enabled and trusted.',
    CONCAT(N'Orphans=', @OrphanCount, N'; disabled/untrusted foreign keys=', @UntrustedForeignKeys, N'.'),
    CASE WHEN @OrphanCount = 0 AND @UntrustedForeignKeys = 0 THEN 'PASS' ELSE 'FAIL' END
);

/* 4. Duplicate prevention */
BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO core.Client
    (
        ClientCode, FirstName, LastName, Email, StateCode,
        AdvisorID, ClientSince
    )
    VALUES
    (
        'CL-0001', N'Duplicate', N'Test', NULL, 'FL',
        1, '2026-01-01'
    );

    ROLLBACK TRANSACTION;

    INSERT INTO #ValidationResults
    VALUES
    (
        N'Duplicate business-key rejection',
        N'A duplicate ClientCode is rejected by UQ_Client_ClientCode.',
        N'Duplicate insert unexpectedly succeeded.',
        'FAIL'
    );
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

    INSERT INTO #ValidationResults
    VALUES
    (
        N'Duplicate business-key rejection',
        N'A duplicate ClientCode is rejected by UQ_Client_ClientCode.',
        CONCAT(N'Rejected as expected: ', ERROR_MESSAGE()),
        'PASS'
    );
END CATCH;

/* 5. Invalid transaction rejection */
BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO trading.AccountTransaction
    (
        AccountID, TransactionTypeID, SecurityID, TradeDate,
        SettlementDate, Quantity, Price, GrossAmount,
        FeeAmount, ExternalReference
    )
    VALUES
    (
        1, 2, 1, '2026-07-10',
        '2026-07-11', -1, 10, 10,
        0, 'VALIDATION-INVALID-QTY'
    );

    ROLLBACK TRANSACTION;

    INSERT INTO #ValidationResults
    VALUES
    (
        N'Invalid quantity rejection',
        N'A security transaction with a negative quantity is rejected.',
        N'Invalid insert unexpectedly succeeded.',
        'FAIL'
    );
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

    INSERT INTO #ValidationResults
    VALUES
    (
        N'Invalid quantity rejection',
        N'A security transaction with a negative quantity is rejected.',
        CONCAT(N'Rejected as expected: ', ERROR_MESSAGE()),
        'PASS'
    );
END CATCH;

/* 6. Intended NULL handling */
DECLARE @NullTestPassed bit = 0;
BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO core.Client
    (
        ClientCode, FirstName, LastName, Email, StateCode,
        AdvisorID, ClientSince
    )
    VALUES
    (
        'CL-NULL-TEST', N'Null', N'Allowed', NULL, 'OH',
        1, '2026-01-01'
    );

    IF EXISTS
    (
        SELECT 1 FROM core.Client
        WHERE ClientCode = 'CL-NULL-TEST'
          AND Email IS NULL
    )
        SET @NullTestPassed = 1;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SET @NullTestPassed = 0;
END CATCH;

INSERT INTO #ValidationResults
VALUES
(
    N'Nullable email handling',
    N'Client.Email accepts NULL while required fields remain populated.',
    CASE WHEN @NullTestPassed = 1 THEN N'NULL email accepted inside a rolled-back test transaction.' ELSE N'NULL email was not handled as expected.' END,
    CASE WHEN @NullTestPassed = 1 THEN 'PASS' ELSE 'FAIL' END
);

/* 7. Explicit rollback behavior */
DECLARE @OriginalLastName nvarchar(50) =
(
    SELECT LastName FROM core.Client WHERE ClientID = 1
);

BEGIN TRANSACTION;
UPDATE core.Client
SET LastName = N'ROLLBACK_TEST',
    ModifiedAt = SYSUTCDATETIME()
WHERE ClientID = 1;
ROLLBACK TRANSACTION;

DECLARE @RollbackPassed bit =
(
    SELECT CASE WHEN LastName = @OriginalLastName THEN 1 ELSE 0 END
    FROM core.Client
    WHERE ClientID = 1
);

INSERT INTO #ValidationResults
VALUES
(
    N'Transaction ROLLBACK behavior',
    N'A test UPDATE is fully reversed.',
    CASE WHEN @RollbackPassed = 1 THEN N'Original value restored after ROLLBACK.' ELSE N'Value was not restored.' END,
    CASE WHEN @RollbackPassed = 1 THEN 'PASS' ELSE 'FAIL' END
);

/* 8. Stored procedure output */
CREATE TABLE #ProcedureOutput
(
    ClientID int,
    ClientCode varchar(20),
    ClientName nvarchar(101),
    AccountID int,
    AccountNumber varchar(25),
    AccountTypeName nvarchar(75),
    RequestedAsOfDate date,
    PortfolioValue decimal(19,2),
    ClientTotalPortfolioValue decimal(19,2),
    AccountValueRank bigint
);

BEGIN TRY
    INSERT INTO #ProcedureOutput
    EXEC reporting.usp_ClientPortfolioReport
        @ClientID = 1,
        @AsOfDate = '2026-07-10';

    INSERT INTO #ValidationResults
    VALUES
    (
        N'Stored procedure execution',
        N'usp_ClientPortfolioReport returns at least one account row for ClientID 1.',
        CONCAT(N'Rows returned=', (SELECT COUNT(*) FROM #ProcedureOutput), N'.'),
        CASE WHEN EXISTS (SELECT 1 FROM #ProcedureOutput) THEN 'PASS' ELSE 'FAIL' END
    );
END TRY
BEGIN CATCH
    INSERT INTO #ValidationResults
    VALUES
    (
        N'Stored procedure execution',
        N'usp_ClientPortfolioReport returns at least one account row for ClientID 1.',
        CONCAT(N'Procedure failed: ', ERROR_MESSAGE()),
        'FAIL'
    );
END CATCH;

/* 9. View output */
DECLARE @PortfolioViewRows int =
(
    SELECT COUNT(*) FROM reporting.vw_AccountPortfolioValue
);
DECLARE @RiskViewRows int =
(
    SELECT COUNT(*) FROM reporting.vw_RiskAlignment
);

INSERT INTO #ValidationResults
VALUES
(
    N'Reporting view output',
    N'Portfolio view returns 50 accounts and risk view returns 30 clients.',
    CONCAT(N'Portfolio rows=', @PortfolioViewRows, N'; risk rows=', @RiskViewRows, N'.'),
    CASE WHEN @PortfolioViewRows = 50 AND @RiskViewRows = 30 THEN 'PASS' ELSE 'FAIL' END
);

/* 10. Independent portfolio-value calculation */
DECLARE @ViewAccountValue decimal(19,2) =
(
    SELECT PortfolioValue
    FROM reporting.vw_AccountPortfolioValue
    WHERE AccountID = 1
);

DECLARE @IndependentAccountValue decimal(19,2) =
(
    SELECT CAST(SUM(ch.Quantity * price.ClosePrice) AS decimal(19,2))
    FROM trading.CurrentHolding AS ch
    CROSS APPLY
    (
        SELECT TOP (1) sp.ClosePrice
        FROM market.SecurityPrice AS sp
        WHERE sp.SecurityID = ch.SecurityID
          AND sp.PriceDate <= ch.AsOfDate
        ORDER BY sp.PriceDate DESC
    ) AS price
    WHERE ch.AccountID = 1
);

INSERT INTO #ValidationResults
VALUES
(
    N'Portfolio-value calculation',
    N'The reporting view and an independent latest-price calculation agree within $0.05.',
    CONCAT(N'View=', @ViewAccountValue, N'; independent=', @IndependentAccountValue, N'.'),
    CASE WHEN ABS(@ViewAccountValue - @IndependentAccountValue) <= 0.05 THEN 'PASS' ELSE 'FAIL' END
);

/* 11. Holdings reconcile to BUY minus SELL quantities */
WITH TransactionQuantity AS
(
    SELECT
        atx.AccountID,
        atx.SecurityID,
        SUM
        (
            CASE tt.TransactionTypeCode
                WHEN 'BUY' THEN atx.Quantity
                WHEN 'SELL' THEN -atx.Quantity
                ELSE 0
            END
        ) AS ExpectedQuantity
    FROM trading.AccountTransaction AS atx
    INNER JOIN trading.TransactionType AS tt
        ON tt.TransactionTypeID = atx.TransactionTypeID
    WHERE atx.SecurityID IS NOT NULL
    GROUP BY atx.AccountID, atx.SecurityID
),
QuantityComparison AS
(
    SELECT
        COALESCE(tq.AccountID, ch.AccountID) AS AccountID,
        COALESCE(tq.SecurityID, ch.SecurityID) AS SecurityID,
        COALESCE(tq.ExpectedQuantity, 0) AS ExpectedQuantity,
        COALESCE(ch.Quantity, 0) AS HoldingQuantity
    FROM TransactionQuantity AS tq
    FULL OUTER JOIN trading.CurrentHolding AS ch
        ON ch.AccountID = tq.AccountID
       AND ch.SecurityID = tq.SecurityID
)
SELECT *
INTO #HoldingMismatches
FROM QuantityComparison
WHERE ABS(ExpectedQuantity - HoldingQuantity) > 0.000001;

INSERT INTO #ValidationResults
VALUES
(
    N'Holdings reconciliation',
    N'Every current holding quantity equals cumulative BUY quantity minus cumulative SELL quantity.',
    CONCAT(N'Mismatched account/security positions=', (SELECT COUNT(*) FROM #HoldingMismatches), N'.'),
    CASE WHEN NOT EXISTS (SELECT 1 FROM #HoldingMismatches) THEN 'PASS' ELSE 'FAIL' END
);

/* 12. Compliance calculations */
DECLARE @OverdueCalculated int =
(
    SELECT COUNT(*)
    FROM compliance.ComplianceReview
    WHERE compliance.fn_IsReviewOverdue
    (
        DueDate,
        ReviewStatus,
        CONVERT(date, SYSUTCDATETIME())
    ) = 1
);
DECLARE @OverdueDashboard int =
(
    SELECT COALESCE(SUM(OverdueReviewCount), 0)
    FROM reporting.vw_ComplianceDashboard
);

INSERT INTO #ValidationResults
VALUES
(
    N'Compliance overdue calculation',
    N'The compliance dashboard overdue total equals the independent function-based count.',
    CONCAT(N'Independent=', @OverdueCalculated, N'; dashboard=', @OverdueDashboard, N'.'),
    CASE WHEN @OverdueCalculated = @OverdueDashboard THEN 'PASS' ELSE 'FAIL' END
);

/* 13. Reporting role can use an approved view */
DECLARE @ReportingViewAllowed bit = 0;
BEGIN TRY
    EXECUTE AS USER = 'demo_reporting';
    IF EXISTS (SELECT TOP (1) 1 FROM reporting.vw_ClientPortfolioSummary)
        SET @ReportingViewAllowed = 1;
    REVERT;
END TRY
BEGIN CATCH
    IF USER_NAME() = N'demo_reporting' REVERT;
    SET @ReportingViewAllowed = 0;
END CATCH;

INSERT INTO #ValidationResults
VALUES
(
    N'Reporting role approved-view access',
    N'demo_reporting can SELECT from the reporting schema.',
    CASE WHEN @ReportingViewAllowed = 1 THEN N'Approved view access succeeded.' ELSE N'Approved view access failed.' END,
    CASE WHEN @ReportingViewAllowed = 1 THEN 'PASS' ELSE 'FAIL' END
);

/* 14. Reporting role is denied raw client-table access */
DECLARE @RawClientDenied bit = 0;
BEGIN TRY
    EXECUTE AS USER = 'demo_reporting';
    DECLARE @RestrictedCount int;
    SELECT @RestrictedCount = COUNT(*) FROM core.Client;
    REVERT;
    SET @RawClientDenied = 0;
END TRY
BEGIN CATCH
    IF USER_NAME() = N'demo_reporting' REVERT;
    SET @RawClientDenied = 1;
END CATCH;

INSERT INTO #ValidationResults
VALUES
(
    N'Reporting role raw-table denial',
    N'demo_reporting is denied direct SELECT on core.Client.',
    CASE WHEN @RawClientDenied = 1 THEN N'Raw client-table access was denied.' ELSE N'Raw client-table access unexpectedly succeeded.' END,
    CASE WHEN @RawClientDenied = 1 THEN 'PASS' ELSE 'FAIL' END
);

/* 15. Backup command preparation */
DECLARE @DefaultBackupPath nvarchar(4000) =
    CONVERT(nvarchar(4000), SERVERPROPERTY('InstanceDefaultBackupPath'));

INSERT INTO #ValidationResults
VALUES
(
    N'Backup command readiness',
    N'SQL Server exposes a default backup path, or the user supplies one manually as documented.',
    COALESCE(CONCAT(N'Default backup path: ', @DefaultBackupPath), N'No default path returned; set @BackupDirectory manually in script 14.'),
    CASE WHEN @DefaultBackupPath IS NOT NULL THEN 'PASS' ELSE 'MANUAL' END
);

/* Final results */
SELECT
    TestID,
    TestName,
    ExpectedOutcome,
    ActualOutcome,
    TestStatus
FROM #ValidationResults
ORDER BY TestID;

DECLARE @FailedTests int =
(
    SELECT COUNT(*)
    FROM #ValidationResults
    WHERE TestStatus = 'FAIL'
);

IF @FailedTests > 0
BEGIN
    THROW 52000, 'One or more validation tests failed. Review the result set above.', 1;
END
ELSE
BEGIN
    PRINT N'Validation completed with no FAIL results. Review any MANUAL item separately.';
END;
GO
