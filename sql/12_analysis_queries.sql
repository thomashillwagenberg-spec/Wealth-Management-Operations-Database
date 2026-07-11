
/*
  12_analysis_queries.sql
  Purpose: Answer practical wealth-management business questions.
  Database context: WealthManagementOperations.
  Safety: Read-only analytical queries.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

/* Q1. What is each client's total portfolio value? */
SELECT
    ClientCode,
    ClientName,
    AccountCount,
    TotalPortfolioValue,
    UnrealizedGainLoss,
    UnrealizedReturnPct
FROM reporting.vw_ClientPortfolioSummary
ORDER BY TotalPortfolioValue DESC;
GO

/* Q2. Which accounts have the largest gains or losses? */
SELECT
    AccountNumber,
    ClientName,
    TotalCostBasis,
    PortfolioValue,
    UnrealizedGainLoss,
    UnrealizedReturnPct,
    CASE
        WHEN UnrealizedGainLoss > 0 THEN 'GAIN'
        WHEN UnrealizedGainLoss < 0 THEN 'LOSS'
        ELSE 'FLAT'
    END AS PerformanceDirection
FROM reporting.vw_AccountPortfolioValue
ORDER BY ABS(UnrealizedGainLoss) DESC;
GO

/* Q3. What percentage of each account is held in each asset class? */
SELECT
    AccountNumber,
    AssetClassName,
    AssetClassValue,
    AllocationPct
FROM reporting.vw_PortfolioAllocation
ORDER BY AccountNumber, AllocationPct DESC;
GO

/* Q4. Which clients have portfolios inconsistent with their risk profiles? */
SELECT
    ClientCode,
    ClientName,
    RiskName,
    MinEquityPct,
    MaxEquityPct,
    EquityAllocationPct,
    AlignmentStatus,
    DeviationPctPoints
FROM reporting.vw_RiskAlignment
WHERE AlignmentStatus <> 'ALIGNED'
ORDER BY DeviationPctPoints DESC, ClientCode;
GO

/* Q5. Which securities create the largest position concentration?
   CTE + window function compare each position with its account total. */
WITH LatestPriceDate AS
(
    SELECT
        ch.AccountID,
        ch.SecurityID,
        MAX(sp.PriceDate) AS PriceDate
    FROM trading.CurrentHolding AS ch
    INNER JOIN market.SecurityPrice AS sp
        ON sp.SecurityID = ch.SecurityID
       AND sp.PriceDate <= ch.AsOfDate
    GROUP BY ch.AccountID, ch.SecurityID
),
PositionValue AS
(
    SELECT
        ch.AccountID,
        ch.SecurityID,
        CAST(ch.Quantity * sp.ClosePrice AS decimal(19,2)) AS MarketValue
    FROM trading.CurrentHolding AS ch
    INNER JOIN LatestPriceDate AS lpd
        ON lpd.AccountID = ch.AccountID
       AND lpd.SecurityID = ch.SecurityID
    INNER JOIN market.SecurityPrice AS sp
        ON sp.SecurityID = lpd.SecurityID
       AND sp.PriceDate = lpd.PriceDate
),
Concentration AS
(
    SELECT
        pv.AccountID,
        pv.SecurityID,
        pv.MarketValue,
        CAST
        (
            100.0 * pv.MarketValue
            / NULLIF(SUM(pv.MarketValue) OVER (PARTITION BY pv.AccountID), 0)
            AS decimal(9,2)
        ) AS PositionPct,
        ROW_NUMBER() OVER
        (
            PARTITION BY pv.AccountID
            ORDER BY pv.MarketValue DESC
        ) AS PositionRank
    FROM PositionValue AS pv
)
SELECT
    ia.AccountNumber,
    s.Symbol,
    s.SecurityName,
    c.MarketValue,
    c.PositionPct,
    CASE WHEN c.PositionPct >= 25 THEN 'REVIEW CONCENTRATION' ELSE 'WITHIN DEMO LIMIT' END AS ConcentrationFlag
FROM Concentration AS c
INNER JOIN core.InvestmentAccount AS ia ON ia.AccountID = c.AccountID
INNER JOIN market.Security AS s ON s.SecurityID = c.SecurityID
WHERE c.PositionRank = 1
ORDER BY c.PositionPct DESC;
GO

/* Q6. Which accounts have had no transactions in the last 90 days?
   Uses a date function and a LEFT JOIN-derived reporting view. */
SELECT
    AccountNumber,
    ClientName,
    LastTransactionDate,
    DaysSinceLastTransaction
FROM reporting.vw_AccountLastActivity
WHERE LastTransactionDate IS NULL
   OR LastTransactionDate < DATEADD(DAY, -90, CONVERT(date, SYSUTCDATETIME()))
ORDER BY DaysSinceLastTransaction DESC;
GO

/* Q7. Which compliance reviews are overdue? */
SELECT
    cr.ComplianceReviewID,
    c.ClientCode,
    CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
    ia.AccountNumber,
    cr.ReviewType,
    cr.DueDate,
    cr.ReviewStatus,
    DATEDIFF(DAY, cr.DueDate, CONVERT(date, SYSUTCDATETIME())) AS DaysOverdue
FROM compliance.ComplianceReview AS cr
INNER JOIN core.Client AS c ON c.ClientID = cr.ClientID
LEFT JOIN core.InvestmentAccount AS ia ON ia.AccountID = cr.AccountID
WHERE compliance.fn_IsReviewOverdue
(
    cr.DueDate,
    cr.ReviewStatus,
    CONVERT(date, SYSUTCDATETIME())
) = 1
ORDER BY DaysOverdue DESC;
GO

/* Q8. Which transactions exceed a chosen dollar threshold? */
DECLARE @DollarThreshold decimal(19,2) = 25000.00;

SELECT
    atx.TransactionID,
    ia.AccountNumber,
    UPPER(tt.TransactionTypeCode) AS TransactionType,
    atx.TradeDate,
    atx.GrossAmount,
    FORMAT(atx.GrossAmount, 'C', 'en-US') AS DisplayAmount,
    atx.ExternalReference
FROM trading.AccountTransaction AS atx
INNER JOIN trading.TransactionType AS tt
    ON tt.TransactionTypeID = atx.TransactionTypeID
INNER JOIN core.InvestmentAccount AS ia
    ON ia.AccountID = atx.AccountID
WHERE atx.GrossAmount >= @DollarThreshold
ORDER BY atx.GrossAmount DESC;
GO

/* Q9. What are monthly purchases and sales by advisor? */
SELECT
    AdvisorName,
    ActivityMonth,
    TransactionTypeCode,
    TransactionCount,
    GrossAmount
FROM reporting.vw_AdvisorMonthlyActivity
WHERE TransactionTypeCode IN ('BUY','SELL')
ORDER BY ActivityMonth, AdvisorName, TransactionTypeCode;
GO

/* Q10. Which clients or accounts require additional review?
   Includes a correlated subquery for the most recent transaction date. */
SELECT
    cd.ClientCode,
    cd.ClientName,
    cd.OverdueReviewCount,
    cd.OpenAlertCount,
    cd.MaximumAlertSeverity,
    ra.AlignmentStatus,
    ra.DeviationPctPoints,
    (
        SELECT MAX(atx.TradeDate)
        FROM trading.AccountTransaction AS atx
        INNER JOIN core.InvestmentAccount AS ia
            ON ia.AccountID = atx.AccountID
        WHERE ia.ClientID = cd.ClientID
    ) AS MostRecentTransactionDate,
    CASE
        WHEN cd.MaximumAlertSeverity IN ('CRITICAL','HIGH') THEN 1
        WHEN cd.OverdueReviewCount > 0 THEN 2
        WHEN ra.AlignmentStatus <> 'ALIGNED' THEN 3
        WHEN cd.OpenAlertCount > 0 THEN 4
        ELSE 5
    END AS ReviewPriority
FROM reporting.vw_ComplianceDashboard AS cd
INNER JOIN reporting.vw_RiskAlignment AS ra ON ra.ClientID = cd.ClientID
WHERE cd.RequiresReview = 1
   OR ra.AlignmentStatus <> 'ALIGNED'
ORDER BY ReviewPriority, ra.DeviationPctPoints DESC, cd.ClientCode;
GO

/* Bonus: advisor rollup with GROUP BY and HAVING. */
SELECT
    a.AdvisorCode,
    CONCAT(a.FirstName, N' ', a.LastName) AS AdvisorName,
    COUNT(DISTINCT ia.AccountID) AS AccountCount,
    CAST(SUM(apv.PortfolioValue) AS decimal(19,2)) AS AssetsInDemo
FROM core.Advisor AS a
INNER JOIN core.InvestmentAccount AS ia ON ia.AdvisorID = a.AdvisorID
INNER JOIN reporting.vw_AccountPortfolioValue AS apv ON apv.AccountID = ia.AccountID
GROUP BY a.AdvisorCode, a.FirstName, a.LastName
HAVING SUM(apv.PortfolioValue) > 0
ORDER BY AssetsInDemo DESC;
GO

PRINT N'Analysis query package completed.';
GO
