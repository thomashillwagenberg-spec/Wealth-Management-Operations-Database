
/*
  09_create_procedures.sql
  Purpose: Demonstrate reusable operations, temporary tables, transactions,
           TRY...CATCH, COMMIT, ROLLBACK, and audit logging.
  Database context: WealthManagementOperations.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE audit.usp_LogActivity
    @ActionName varchar(50),
    @SchemaName sysname = NULL,
    @ObjectName sysname = NULL,
    @RecordKey nvarchar(100) = NULL,
    @Details nvarchar(1000) = NULL,
    @CorrelationID uniqueidentifier = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.ActivityLog
    (
        ActionName, SchemaName, ObjectName, RecordKey, Details, CorrelationID
    )
    VALUES
    (
        @ActionName, @SchemaName, @ObjectName, @RecordKey, @Details,
        COALESCE(@CorrelationID, NEWID())
    );
END;
GO

CREATE OR ALTER PROCEDURE reporting.usp_ClientPortfolioReport
    @ClientID int,
    @AsOfDate date = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @AsOfDate = COALESCE(@AsOfDate, CONVERT(date, SYSUTCDATETIME()));

    IF NOT EXISTS (SELECT 1 FROM core.Client WHERE ClientID = @ClientID)
        THROW 51001, 'ClientID does not exist.', 1;

    CREATE TABLE #AccountValues
    (
        AccountID int NOT NULL PRIMARY KEY,
        RequestedAsOfDate date NOT NULL,
        PortfolioValue decimal(19,2) NOT NULL
    );

    INSERT INTO #AccountValues (AccountID, RequestedAsOfDate, PortfolioValue)
    SELECT
        ia.AccountID,
        @AsOfDate,
        COALESCE(av.PortfolioValue, 0)
    FROM core.InvestmentAccount AS ia
    OUTER APPLY reporting.fn_AccountValue(ia.AccountID, @AsOfDate) AS av
    WHERE ia.ClientID = @ClientID;

    SELECT
        c.ClientID,
        c.ClientCode,
        CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
        ia.AccountID,
        ia.AccountNumber,
        atp.AccountTypeName,
        av.RequestedAsOfDate,
        av.PortfolioValue,
        CAST(SUM(av.PortfolioValue) OVER () AS decimal(19,2)) AS ClientTotalPortfolioValue,
        DENSE_RANK() OVER (ORDER BY av.PortfolioValue DESC) AS AccountValueRank
    FROM #AccountValues AS av
    INNER JOIN core.InvestmentAccount AS ia ON ia.AccountID = av.AccountID
    INNER JOIN core.AccountType AS atp ON atp.AccountTypeID = ia.AccountTypeID
    INNER JOIN core.Client AS c ON c.ClientID = ia.ClientID
    ORDER BY av.PortfolioValue DESC, ia.AccountID;
END;
GO

CREATE OR ALTER PROCEDURE reporting.usp_AdvisorMonthlyActivity
    @AdvisorID int,
    @StartDate date,
    @EndDate date
AS
BEGIN
    SET NOCOUNT ON;

    IF @EndDate < @StartDate
        THROW 51002, 'End date must be on or after start date.', 1;

    DECLARE @Activity TABLE
    (
        ActivityMonth date NOT NULL,
        TransactionTypeCode varchar(20) NOT NULL,
        TransactionCount bigint NOT NULL,
        GrossAmount decimal(19,2) NOT NULL
    );

    INSERT INTO @Activity
    (
        ActivityMonth, TransactionTypeCode, TransactionCount, GrossAmount
    )
    SELECT
        DATEFROMPARTS(YEAR(atx.TradeDate), MONTH(atx.TradeDate), 1),
        tt.TransactionTypeCode,
        COUNT_BIG(*),
        CAST(SUM(atx.GrossAmount) AS decimal(19,2))
    FROM trading.AccountTransaction AS atx
    INNER JOIN trading.TransactionType AS tt
        ON tt.TransactionTypeID = atx.TransactionTypeID
    INNER JOIN core.InvestmentAccount AS ia
        ON ia.AccountID = atx.AccountID
    WHERE ia.AdvisorID = @AdvisorID
      AND atx.TradeDate >= @StartDate
      AND atx.TradeDate <= @EndDate
    GROUP BY
        DATEFROMPARTS(YEAR(atx.TradeDate), MONTH(atx.TradeDate), 1),
        tt.TransactionTypeCode;

    SELECT
        ActivityMonth,
        TransactionTypeCode,
        TransactionCount,
        GrossAmount,
        SUM(GrossAmount) OVER (PARTITION BY ActivityMonth) AS MonthlyGrossAmount
    FROM @Activity
    ORDER BY ActivityMonth, TransactionTypeCode;
END;
GO

CREATE OR ALTER PROCEDURE trading.usp_RecordTrade
    @AccountID int,
    @TransactionTypeCode varchar(20),
    @SecurityID int,
    @TradeDate date,
    @SettlementDate date,
    @Quantity decimal(19,6),
    @Price decimal(19,6),
    @FeeAmount decimal(19,2) = 0,
    @ExternalReference varchar(30),
    @Notes nvarchar(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @TransactionTypeID int,
        @GrossAmount decimal(19,2),
        @NewTransactionID bigint,
        @ExistingQuantity decimal(19,6),
        @CorrelationID uniqueidentifier = NEWID();

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @TransactionTypeID = TransactionTypeID
        FROM trading.TransactionType
        WHERE TransactionTypeCode = @TransactionTypeCode
          AND RequiresSecurity = 1;

        IF @TransactionTypeID IS NULL OR @TransactionTypeCode NOT IN ('BUY','SELL')
            THROW 51010, 'Transaction type must be BUY or SELL.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM core.InvestmentAccount
            WHERE AccountID = @AccountID
              AND AccountStatus = 'OPEN'
        )
            THROW 51011, 'Account does not exist or is not open.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM market.Security
            WHERE SecurityID = @SecurityID
              AND IsActive = 1
        )
            THROW 51012, 'Security does not exist or is inactive.', 1;

        IF @Quantity <= 0 OR @Price <= 0 OR @FeeAmount < 0
            THROW 51013, 'Quantity and price must be positive; fee cannot be negative.', 1;

        IF @SettlementDate < @TradeDate
            THROW 51014, 'Settlement date cannot be before trade date.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM trading.AccountTransaction
            WHERE ExternalReference = @ExternalReference
        )
            THROW 51015, 'External reference must be unique.', 1;

        IF @TransactionTypeCode = 'SELL'
        BEGIN
            SELECT @ExistingQuantity = Quantity
            FROM trading.CurrentHolding WITH (UPDLOCK, HOLDLOCK)
            WHERE AccountID = @AccountID
              AND SecurityID = @SecurityID;

            IF COALESCE(@ExistingQuantity, 0) < @Quantity
                THROW 51016, 'Sell quantity exceeds the current holding.', 1;
        END;

        SET @GrossAmount = ROUND(@Quantity * @Price, 2);

        INSERT INTO trading.AccountTransaction
        (
            AccountID, TransactionTypeID, SecurityID,
            TradeDate, SettlementDate, Quantity, Price,
            GrossAmount, FeeAmount, ExternalReference, Notes
        )
        VALUES
        (
            @AccountID, @TransactionTypeID, @SecurityID,
            @TradeDate, @SettlementDate, @Quantity, @Price,
            @GrossAmount, @FeeAmount, @ExternalReference, @Notes
        );

        SET @NewTransactionID = CONVERT(bigint, SCOPE_IDENTITY());

        IF @TransactionTypeCode = 'BUY'
        BEGIN
            UPDATE trading.CurrentHolding WITH (UPDLOCK, SERIALIZABLE)
            SET
                AverageCost =
                    ((Quantity * AverageCost) + (@Quantity * @Price))
                    / NULLIF(Quantity + @Quantity, 0),
                Quantity = Quantity + @Quantity,
                AsOfDate = @TradeDate,
                ModifiedAt = SYSUTCDATETIME()
            WHERE AccountID = @AccountID
              AND SecurityID = @SecurityID;

            IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO trading.CurrentHolding
                (
                    AccountID, SecurityID, Quantity, AverageCost, AsOfDate
                )
                VALUES
                (
                    @AccountID, @SecurityID, @Quantity, @Price, @TradeDate
                );
            END;
        END
        ELSE
        BEGIN
            UPDATE trading.CurrentHolding
            SET
                Quantity = Quantity - @Quantity,
                AsOfDate = @TradeDate,
                ModifiedAt = SYSUTCDATETIME()
            WHERE AccountID = @AccountID
              AND SecurityID = @SecurityID;

            DELETE FROM trading.CurrentHolding
            WHERE AccountID = @AccountID
              AND SecurityID = @SecurityID
              AND Quantity = 0;
        END;

        EXEC audit.usp_LogActivity
            @ActionName = 'RECORD_TRADE',
            @SchemaName = 'trading',
            @ObjectName = 'AccountTransaction',
            @RecordKey = CONVERT(nvarchar(100), @NewTransactionID),
            @Details = CONCAT(@TransactionTypeCode, ' ', @Quantity, ' units for account ', @AccountID),
            @CorrelationID = @CorrelationID;

        COMMIT TRANSACTION;

        SELECT
            @NewTransactionID AS TransactionID,
            @CorrelationID AS CorrelationID,
            N'Trade recorded and holding updated.' AS ResultMessage;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage nvarchar(2048) = ERROR_MESSAGE();
        THROW 51019, @ErrorMessage, 1;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE compliance.usp_UpdateAlertStatus
    @ComplianceAlertID bigint,
    @NewStatus varchar(20),
    @ResolutionNote nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @NewStatus NOT IN ('OPEN','IN_REVIEW','RESOLVED','DISMISSED')
        THROW 51020, 'Invalid alert status.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE compliance.ComplianceAlert
        SET
            AlertStatus = @NewStatus,
            ResolvedDate =
                CASE
                    WHEN @NewStatus IN ('RESOLVED','DISMISSED')
                    THEN CONVERT(date, SYSUTCDATETIME())
                    ELSE NULL
                END,
            Description =
                CASE
                    WHEN @ResolutionNote IS NULL THEN Description
                    ELSE CONCAT(Description, N' | Note: ', @ResolutionNote)
                END,
            ModifiedAt = SYSUTCDATETIME()
        WHERE ComplianceAlertID = @ComplianceAlertID;

        IF @@ROWCOUNT = 0
            THROW 51021, 'Compliance alert was not found.', 1;

        COMMIT TRANSACTION;

        SELECT
            ComplianceAlertID,
            AlertStatus,
            ResolvedDate,
            ModifiedAt
        FROM compliance.ComplianceAlert
        WHERE ComplianceAlertID = @ComplianceAlertID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER TRIGGER compliance.trg_ComplianceAlert_AuditStatus
ON compliance.ComplianceAlert
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.ActivityLog
    (
        ActionName, SchemaName, ObjectName, RecordKey, Details
    )
    SELECT
        'ALERT_STATUS_CHANGE',
        'compliance',
        'ComplianceAlert',
        CONVERT(nvarchar(100), i.ComplianceAlertID),
        CONCAT('Status changed from ', d.AlertStatus, ' to ', i.AlertStatus)
    FROM inserted AS i
    INNER JOIN deleted AS d
        ON d.ComplianceAlertID = i.ComplianceAlertID
    WHERE i.AlertStatus <> d.AlertStatus;
END;
GO

PRINT N'Created five stored procedures and one audit trigger.';
GO
