
/*
  07_create_views.sql
  Purpose: Create reusable reporting layers over normalized tables.
  Database context: WealthManagementOperations.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER VIEW reporting.vw_AccountPortfolioValue
AS
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
PositionValues AS
(
    SELECT
        ch.AccountID,
        ch.SecurityID,
        ch.Quantity,
        ch.AverageCost,
        sp.PriceDate,
        sp.ClosePrice,
        CAST(ch.Quantity * ch.AverageCost AS decimal(19,2)) AS CostBasis,
        CAST(ch.Quantity * sp.ClosePrice AS decimal(19,2)) AS MarketValue
    FROM trading.CurrentHolding AS ch
    INNER JOIN LatestPriceDate AS lpd
        ON lpd.AccountID = ch.AccountID
       AND lpd.SecurityID = ch.SecurityID
    INNER JOIN market.SecurityPrice AS sp
        ON sp.SecurityID = lpd.SecurityID
       AND sp.PriceDate = lpd.PriceDate
)
SELECT
    ia.AccountID,
    ia.AccountNumber,
    ia.ClientID,
    c.ClientCode,
    CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
    ia.AdvisorID,
    CONCAT(a.FirstName, N' ', a.LastName) AS AdvisorName,
    CAST(COALESCE(SUM(pv.CostBasis), 0) AS decimal(19,2)) AS TotalCostBasis,
    CAST(COALESCE(SUM(pv.MarketValue), 0) AS decimal(19,2)) AS PortfolioValue,
    CAST(COALESCE(SUM(pv.MarketValue - pv.CostBasis), 0) AS decimal(19,2)) AS UnrealizedGainLoss,
    CAST
    (
        CASE
            WHEN COALESCE(SUM(pv.CostBasis), 0) = 0 THEN 0
            ELSE 100.0 * SUM(pv.MarketValue - pv.CostBasis) / SUM(pv.CostBasis)
        END
        AS decimal(9,2)
    ) AS UnrealizedReturnPct,
    MAX(pv.PriceDate) AS ValuationDate
FROM core.InvestmentAccount AS ia
INNER JOIN core.Client AS c ON c.ClientID = ia.ClientID
INNER JOIN core.Advisor AS a ON a.AdvisorID = ia.AdvisorID
LEFT JOIN PositionValues AS pv ON pv.AccountID = ia.AccountID
GROUP BY
    ia.AccountID, ia.AccountNumber, ia.ClientID, c.ClientCode,
    c.FirstName, c.LastName, ia.AdvisorID, a.FirstName, a.LastName;
GO

CREATE OR ALTER VIEW reporting.vw_ClientPortfolioSummary
AS
SELECT
    c.ClientID,
    c.ClientCode,
    CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
    c.AdvisorID,
    CONCAT(a.FirstName, N' ', a.LastName) AS AdvisorName,
    COUNT(apv.AccountID) AS AccountCount,
    CAST(COALESCE(SUM(apv.TotalCostBasis), 0) AS decimal(19,2)) AS TotalCostBasis,
    CAST(COALESCE(SUM(apv.PortfolioValue), 0) AS decimal(19,2)) AS TotalPortfolioValue,
    CAST(COALESCE(SUM(apv.UnrealizedGainLoss), 0) AS decimal(19,2)) AS UnrealizedGainLoss,
    CAST
    (
        CASE
            WHEN COALESCE(SUM(apv.TotalCostBasis), 0) = 0 THEN 0
            ELSE 100.0 * SUM(apv.UnrealizedGainLoss) / SUM(apv.TotalCostBasis)
        END
        AS decimal(9,2)
    ) AS UnrealizedReturnPct
FROM core.Client AS c
INNER JOIN core.Advisor AS a ON a.AdvisorID = c.AdvisorID
LEFT JOIN reporting.vw_AccountPortfolioValue AS apv ON apv.ClientID = c.ClientID
GROUP BY c.ClientID, c.ClientCode, c.FirstName, c.LastName, c.AdvisorID, a.FirstName, a.LastName;
GO

CREATE OR ALTER VIEW reporting.vw_PortfolioAllocation
AS
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
PositionValues AS
(
    SELECT
        ch.AccountID,
        s.AssetClassID,
        CAST(ch.Quantity * sp.ClosePrice AS decimal(19,2)) AS MarketValue
    FROM trading.CurrentHolding AS ch
    INNER JOIN LatestPriceDate AS lpd
        ON lpd.AccountID = ch.AccountID
       AND lpd.SecurityID = ch.SecurityID
    INNER JOIN market.SecurityPrice AS sp
        ON sp.SecurityID = lpd.SecurityID
       AND sp.PriceDate = lpd.PriceDate
    INNER JOIN market.Security AS s ON s.SecurityID = ch.SecurityID
),
ClassValues AS
(
    SELECT AccountID, AssetClassID, SUM(MarketValue) AS AssetClassValue
    FROM PositionValues
    GROUP BY AccountID, AssetClassID
)
SELECT
    cv.AccountID,
    ia.AccountNumber,
    ia.ClientID,
    ac.AssetClassID,
    ac.AssetClassCode,
    ac.AssetClassName,
    ac.IsEquityLike,
    CAST(cv.AssetClassValue AS decimal(19,2)) AS AssetClassValue,
    CAST
    (
        100.0 * cv.AssetClassValue
        / NULLIF(SUM(cv.AssetClassValue) OVER (PARTITION BY cv.AccountID), 0)
        AS decimal(9,2)
    ) AS AllocationPct
FROM ClassValues AS cv
INNER JOIN core.InvestmentAccount AS ia ON ia.AccountID = cv.AccountID
INNER JOIN market.AssetClass AS ac ON ac.AssetClassID = cv.AssetClassID;
GO

CREATE OR ALTER VIEW reporting.vw_RiskAlignment
AS
WITH ClientAllocation AS
(
    SELECT
        pa.ClientID,
        CAST
        (
            SUM(CASE WHEN pa.IsEquityLike = 1 THEN pa.AssetClassValue ELSE 0 END)
            * 100.0
            / NULLIF(SUM(pa.AssetClassValue), 0)
            AS decimal(9,2)
        ) AS EquityAllocationPct
    FROM reporting.vw_PortfolioAllocation AS pa
    GROUP BY pa.ClientID
)
SELECT
    c.ClientID,
    c.ClientCode,
    CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
    rpt.RiskCode,
    rpt.RiskName,
    rpt.MinEquityPct,
    rpt.MaxEquityPct,
    COALESCE(ca.EquityAllocationPct, 0) AS EquityAllocationPct,
    CASE
        WHEN ca.EquityAllocationPct IS NULL THEN 'NO HOLDINGS'
        WHEN ca.EquityAllocationPct < rpt.MinEquityPct THEN 'BELOW RANGE'
        WHEN ca.EquityAllocationPct > rpt.MaxEquityPct THEN 'ABOVE RANGE'
        ELSE 'ALIGNED'
    END AS AlignmentStatus,
    CAST
    (
        CASE
            WHEN ca.EquityAllocationPct IS NULL THEN NULL
            WHEN ca.EquityAllocationPct < rpt.MinEquityPct THEN rpt.MinEquityPct - ca.EquityAllocationPct
            WHEN ca.EquityAllocationPct > rpt.MaxEquityPct THEN ca.EquityAllocationPct - rpt.MaxEquityPct
            ELSE 0
        END
        AS decimal(9,2)
    ) AS DeviationPctPoints
FROM core.Client AS c
INNER JOIN core.ClientRiskProfile AS crp
    ON crp.ClientID = c.ClientID
   AND crp.IsCurrent = 1
INNER JOIN core.RiskProfileType AS rpt ON rpt.RiskProfileTypeID = crp.RiskProfileTypeID
LEFT JOIN ClientAllocation AS ca ON ca.ClientID = c.ClientID;
GO

CREATE OR ALTER VIEW reporting.vw_ComplianceDashboard
AS
WITH ReviewStats AS
(
    SELECT
        cr.ClientID,
        COUNT_BIG(*) AS ReviewCount,
        SUM
        (
            CASE
                WHEN cr.ReviewStatus <> 'COMPLETED'
                 AND cr.ReviewStatus <> 'WAIVED'
                 AND cr.DueDate < CONVERT(date, SYSUTCDATETIME())
                THEN 1 ELSE 0
            END
        ) AS OverdueReviewCount,
        MIN
        (
            CASE
                WHEN cr.ReviewStatus NOT IN ('COMPLETED','WAIVED')
                THEN cr.DueDate
            END
        ) AS NextOpenReviewDueDate
    FROM compliance.ComplianceReview AS cr
    GROUP BY cr.ClientID
),
AlertStats AS
(
    SELECT
        ca.ClientID,
        COUNT_BIG(*) AS AlertCount,
        SUM(CASE WHEN ca.AlertStatus IN ('OPEN','IN_REVIEW') THEN 1 ELSE 0 END) AS OpenAlertCount,
        MAX
        (
            CASE ca.Severity
                WHEN 'CRITICAL' THEN 4
                WHEN 'HIGH' THEN 3
                WHEN 'MEDIUM' THEN 2
                WHEN 'LOW' THEN 1
                ELSE 0
            END
        ) AS MaximumSeverityRank
    FROM compliance.ComplianceAlert AS ca
    GROUP BY ca.ClientID
)
SELECT
    c.ClientID,
    c.ClientCode,
    CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
    COALESCE(rs.ReviewCount, 0) AS ReviewCount,
    COALESCE(rs.OverdueReviewCount, 0) AS OverdueReviewCount,
    rs.NextOpenReviewDueDate,
    COALESCE(als.AlertCount, 0) AS AlertCount,
    COALESCE(als.OpenAlertCount, 0) AS OpenAlertCount,
    CASE COALESCE(als.MaximumSeverityRank, 0)
        WHEN 4 THEN 'CRITICAL'
        WHEN 3 THEN 'HIGH'
        WHEN 2 THEN 'MEDIUM'
        WHEN 1 THEN 'LOW'
        ELSE 'NONE'
    END AS MaximumAlertSeverity,
    CASE
        WHEN COALESCE(rs.OverdueReviewCount, 0) > 0
          OR COALESCE(als.OpenAlertCount, 0) > 0
        THEN 1 ELSE 0
    END AS RequiresReview
FROM core.Client AS c
LEFT JOIN ReviewStats AS rs ON rs.ClientID = c.ClientID
LEFT JOIN AlertStats AS als ON als.ClientID = c.ClientID;
GO

CREATE OR ALTER VIEW reporting.vw_AdvisorMonthlyActivity
AS
SELECT
    ia.AdvisorID,
    CONCAT(a.FirstName, N' ', a.LastName) AS AdvisorName,
    DATEFROMPARTS(YEAR(atx.TradeDate), MONTH(atx.TradeDate), 1) AS ActivityMonth,
    tt.TransactionTypeCode,
    COUNT_BIG(*) AS TransactionCount,
    CAST(SUM(atx.GrossAmount) AS decimal(19,2)) AS GrossAmount
FROM trading.AccountTransaction AS atx
INNER JOIN trading.TransactionType AS tt ON tt.TransactionTypeID = atx.TransactionTypeID
INNER JOIN core.InvestmentAccount AS ia ON ia.AccountID = atx.AccountID
INNER JOIN core.Advisor AS a ON a.AdvisorID = ia.AdvisorID
GROUP BY
    ia.AdvisorID, a.FirstName, a.LastName,
    DATEFROMPARTS(YEAR(atx.TradeDate), MONTH(atx.TradeDate), 1),
    tt.TransactionTypeCode;
GO

CREATE OR ALTER VIEW reporting.vw_AccountLastActivity
AS
SELECT
    ia.AccountID,
    ia.AccountNumber,
    ia.ClientID,
    CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
    MAX(atx.TradeDate) AS LastTransactionDate,
    DATEDIFF(DAY, MAX(atx.TradeDate), CONVERT(date, SYSUTCDATETIME())) AS DaysSinceLastTransaction
FROM core.InvestmentAccount AS ia
INNER JOIN core.Client AS c ON c.ClientID = ia.ClientID
LEFT JOIN trading.AccountTransaction AS atx ON atx.AccountID = ia.AccountID
GROUP BY ia.AccountID, ia.AccountNumber, ia.ClientID, c.FirstName, c.LastName;
GO

PRINT N'Created seven reporting views.';
GO
