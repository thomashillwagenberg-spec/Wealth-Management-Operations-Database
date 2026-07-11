
/*
  05_load_reference_data.sql
  Purpose: Load controlled reference values used by the business tables.
  Database context: WealthManagementOperations.
  Rerun behavior: Existing seed sets are skipped.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM core.RiskProfileType WHERE [RiskProfileTypeID] = 1)
    BEGIN
    SET IDENTITY_INSERT core.RiskProfileType ON;

    INSERT INTO core.RiskProfileType ([RiskProfileTypeID], [RiskCode], [RiskName], [MinEquityPct], [MaxEquityPct], [Description])
    VALUES
        (1, N'CONSERVATIVE', N'Conservative', 10.0, 35.0, N'Prioritizes capital preservation and lower volatility.'),
        (2, N'MODERATE', N'Moderate', 40.0, 65.0, N'Balances growth and stability.'),
        (3, N'GROWTH', N'Growth', 65.0, 85.0, N'Accepts higher volatility for long-term growth.'),
        (4, N'AGGRESSIVE', N'Aggressive', 80.0, 100.0, N'Seeks maximum long-term growth and accepts substantial volatility.');

    SET IDENTITY_INSERT core.RiskProfileType OFF;
        PRINT N'Loaded 4 rows into core.RiskProfileType.';
    END
    ELSE
    BEGIN
        PRINT N'Skipped core.RiskProfileType; sample rows already exist.';
    END;

    IF NOT EXISTS (SELECT 1 FROM core.AccountType WHERE [AccountTypeID] = 1)
    BEGIN
    SET IDENTITY_INSERT core.AccountType ON;

    INSERT INTO core.AccountType ([AccountTypeID], [AccountTypeCode], [AccountTypeName], [IsTaxDeferred])
    VALUES
        (1, N'BROKERAGE', N'Taxable Brokerage', 0),
        (2, N'TRAD_IRA', N'Traditional IRA', 1),
        (3, N'ROTH_IRA', N'Roth IRA', 1),
        (4, N'TRUST', N'Revocable Trust', 0);

    SET IDENTITY_INSERT core.AccountType OFF;
        PRINT N'Loaded 4 rows into core.AccountType.';
    END
    ELSE
    BEGIN
        PRINT N'Skipped core.AccountType; sample rows already exist.';
    END;

    IF NOT EXISTS (SELECT 1 FROM market.AssetClass WHERE [AssetClassID] = 1)
    BEGIN
    SET IDENTITY_INSERT market.AssetClass ON;

    INSERT INTO market.AssetClass ([AssetClassID], [AssetClassCode], [AssetClassName], [IsEquityLike])
    VALUES
        (1, N'US_EQ', N'U.S. Equity', 1),
        (2, N'INTL_EQ', N'International Equity', 1),
        (3, N'FIXED', N'Fixed Income', 0),
        (4, N'CASH', N'Cash Equivalent', 0),
        (5, N'REAL_ASSET', N'Real Assets', 0),
        (6, N'ALTERNATIVE', N'Alternatives', 0),
        (7, N'COMMODITY', N'Commodities', 0);

    SET IDENTITY_INSERT market.AssetClass OFF;
        PRINT N'Loaded 7 rows into market.AssetClass.';
    END
    ELSE
    BEGIN
        PRINT N'Skipped market.AssetClass; sample rows already exist.';
    END;

    IF NOT EXISTS (SELECT 1 FROM trading.TransactionType WHERE [TransactionTypeID] = 1)
    BEGIN
    SET IDENTITY_INSERT trading.TransactionType ON;

    INSERT INTO trading.TransactionType ([TransactionTypeID], [TransactionTypeCode], [TransactionTypeName], [CashDirection], [RequiresSecurity])
    VALUES
        (1, N'DEPOSIT', N'Cash Deposit', 1, 0),
        (2, N'BUY', N'Security Purchase', -1, 1),
        (3, N'SELL', N'Security Sale', 1, 1),
        (4, N'DIVIDEND', N'Dividend Income', 1, 0),
        (5, N'FEE', N'Advisory Fee', -1, 0),
        (6, N'WITHDRAWAL', N'Cash Withdrawal', -1, 0);

    SET IDENTITY_INSERT trading.TransactionType OFF;
        PRINT N'Loaded 6 rows into trading.TransactionType.';
    END
    ELSE
    BEGIN
        PRINT N'Skipped trading.TransactionType; sample rows already exist.';
    END;


    COMMIT TRANSACTION;
    PRINT N'Reference data load completed.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
