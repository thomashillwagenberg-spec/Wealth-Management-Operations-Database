
/*
  10_create_indexes.sql
  Purpose: Add targeted nonclustered indexes and provide a repeatable
           execution-plan comparison.
  Database context: WealthManagementOperations.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'market.SecurityPrice')
      AND name = N'IX_SecurityPrice_Security_Date'
)
    CREATE INDEX IX_SecurityPrice_Security_Date
    ON market.SecurityPrice(SecurityID, PriceDate DESC)
    INCLUDE (ClosePrice, PriceSource);
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'trading.AccountTransaction')
      AND name = N'IX_AccountTransaction_Account_TradeDate'
)
    CREATE INDEX IX_AccountTransaction_Account_TradeDate
    ON trading.AccountTransaction(AccountID, TradeDate DESC)
    INCLUDE (TransactionTypeID, SecurityID, Quantity, Price, GrossAmount, FeeAmount);
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'trading.AccountTransaction')
      AND name = N'IX_AccountTransaction_TradeDate_Type'
)
    CREATE INDEX IX_AccountTransaction_TradeDate_Type
    ON trading.AccountTransaction(TradeDate, TransactionTypeID)
    INCLUDE (AccountID, GrossAmount);
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'trading.CurrentHolding')
      AND name = N'IX_CurrentHolding_Security'
)
    CREATE INDEX IX_CurrentHolding_Security
    ON trading.CurrentHolding(SecurityID)
    INCLUDE (AccountID, Quantity, AverageCost, AsOfDate);
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'compliance.ComplianceReview')
      AND name = N'IX_ComplianceReview_Status_DueDate'
)
    CREATE INDEX IX_ComplianceReview_Status_DueDate
    ON compliance.ComplianceReview(ReviewStatus, DueDate)
    INCLUDE (ClientID, AccountID, ReviewType, CompletedDate);
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'compliance.ComplianceAlert')
      AND name = N'IX_ComplianceAlert_Status_Severity'
)
    CREATE INDEX IX_ComplianceAlert_Status_Severity
    ON compliance.ComplianceAlert(AlertStatus, Severity, AlertDate)
    INCLUDE (ClientID, AccountID, TransactionID, AlertType);
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'audit.ActivityLog')
      AND name = N'IX_ActivityLog_EventTime'
)
    CREATE INDEX IX_ActivityLog_EventTime
    ON audit.ActivityLog(EventTime DESC)
    INCLUDE (DatabaseUser, ActionName, SchemaName, ObjectName, RecordKey);
GO

PRINT N'Created or confirmed seven targeted nonclustered indexes.';
GO

/*
  EXECUTION-PLAN EXERCISE

  1. In SSMS, open a new query and enable "Include Actual Execution Plan"
     with Ctrl+M.
  2. Run the query below with SET STATISTICS IO and TIME enabled.
  3. Inspect whether IX_AccountTransaction_Account_TradeDate is used.
  4. Record logical reads, elapsed time, and the main physical operators.
  5. Because the sample set is small, SQL Server may reasonably choose a scan.
     That is not automatically a problem. Compare estimated and actual rows.

  Do not publish a performance-improvement claim from this project unless you
  personally captured before-and-after measurements on your own machine.
*/
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    atx.AccountID,
    atx.TradeDate,
    tt.TransactionTypeCode,
    atx.GrossAmount
FROM trading.AccountTransaction AS atx
INNER JOIN trading.TransactionType AS tt
    ON tt.TransactionTypeID = atx.TransactionTypeID
WHERE atx.AccountID = 1
  AND atx.TradeDate >= '2026-01-01'
ORDER BY atx.TradeDate DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
