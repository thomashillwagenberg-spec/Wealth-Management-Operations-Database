
/*
  04_create_constraints.sql
  Purpose: Add alternate keys, validation checks, and referential integrity.
  Database context: WealthManagementOperations.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

/* Unique business keys */
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_Advisor_AdvisorCode')
    ALTER TABLE core.Advisor ADD CONSTRAINT UQ_Advisor_AdvisorCode UNIQUE (AdvisorCode);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_Advisor_Email')
    ALTER TABLE core.Advisor ADD CONSTRAINT UQ_Advisor_Email UNIQUE (Email);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_Client_ClientCode')
    ALTER TABLE core.Client ADD CONSTRAINT UQ_Client_ClientCode UNIQUE (ClientCode);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_RiskProfileType_RiskCode')
    ALTER TABLE core.RiskProfileType ADD CONSTRAINT UQ_RiskProfileType_RiskCode UNIQUE (RiskCode);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_AccountType_Code')
    ALTER TABLE core.AccountType ADD CONSTRAINT UQ_AccountType_Code UNIQUE (AccountTypeCode);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_InvestmentAccount_Number')
    ALTER TABLE core.InvestmentAccount ADD CONSTRAINT UQ_InvestmentAccount_Number UNIQUE (AccountNumber);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_AssetClass_Code')
    ALTER TABLE market.AssetClass ADD CONSTRAINT UQ_AssetClass_Code UNIQUE (AssetClassCode);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_Security_Symbol')
    ALTER TABLE market.Security ADD CONSTRAINT UQ_Security_Symbol UNIQUE (Symbol);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_SecurityPrice_Security_Date')
    ALTER TABLE market.SecurityPrice ADD CONSTRAINT UQ_SecurityPrice_Security_Date UNIQUE (SecurityID, PriceDate);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_TransactionType_Code')
    ALTER TABLE trading.TransactionType ADD CONSTRAINT UQ_TransactionType_Code UNIQUE (TransactionTypeCode);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_AccountTransaction_ExternalReference')
    ALTER TABLE trading.AccountTransaction ADD CONSTRAINT UQ_AccountTransaction_ExternalReference UNIQUE (ExternalReference);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_CurrentHolding_Account_Security')
    ALTER TABLE trading.CurrentHolding ADD CONSTRAINT UQ_CurrentHolding_Account_Security UNIQUE (AccountID, SecurityID);
GO

/* Check constraints */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_RiskProfileType_Range')
    ALTER TABLE core.RiskProfileType ADD CONSTRAINT CK_RiskProfileType_Range
    CHECK (MinEquityPct BETWEEN 0 AND 100 AND MaxEquityPct BETWEEN 0 AND 100 AND MinEquityPct <= MaxEquityPct);

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ClientRiskProfile_Score')
    ALTER TABLE core.ClientRiskProfile ADD CONSTRAINT CK_ClientRiskProfile_Score CHECK (RiskScore BETWEEN 1 AND 100);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ClientRiskProfile_Horizon')
    ALTER TABLE core.ClientRiskProfile ADD CONSTRAINT CK_ClientRiskProfile_Horizon CHECK (TimeHorizonYears BETWEEN 1 AND 75);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ClientRiskProfile_Dates')
    ALTER TABLE core.ClientRiskProfile ADD CONSTRAINT CK_ClientRiskProfile_Dates CHECK (EffectiveTo IS NULL OR EffectiveTo >= EffectiveFrom);

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_InvestmentAccount_Status')
    ALTER TABLE core.InvestmentAccount ADD CONSTRAINT CK_InvestmentAccount_Status CHECK (AccountStatus IN ('OPEN','CLOSED','RESTRICTED'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_InvestmentAccount_Dates')
    ALTER TABLE core.InvestmentAccount ADD CONSTRAINT CK_InvestmentAccount_Dates CHECK (CloseDate IS NULL OR CloseDate >= OpenDate);

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Security_Type')
    ALTER TABLE market.Security ADD CONSTRAINT CK_Security_Type CHECK (SecurityType IN ('STOCK','ETF','MUTUAL_FUND','BOND','MONEY_MARKET','REIT'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_SecurityPrice_Positive')
    ALTER TABLE market.SecurityPrice ADD CONSTRAINT CK_SecurityPrice_Positive CHECK (ClosePrice > 0);

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_TransactionType_CashDirection')
    ALTER TABLE trading.TransactionType ADD CONSTRAINT CK_TransactionType_CashDirection CHECK (CashDirection IN (-1, 1));

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_AccountTransaction_Dates')
    ALTER TABLE trading.AccountTransaction ADD CONSTRAINT CK_AccountTransaction_Dates CHECK (SettlementDate >= TradeDate);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_AccountTransaction_Amounts')
    ALTER TABLE trading.AccountTransaction ADD CONSTRAINT CK_AccountTransaction_Amounts
    CHECK (GrossAmount >= 0 AND FeeAmount >= 0);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_AccountTransaction_SecurityFields')
    ALTER TABLE trading.AccountTransaction ADD CONSTRAINT CK_AccountTransaction_SecurityFields
    CHECK
    (
        (SecurityID IS NULL AND Quantity IS NULL AND Price IS NULL)
        OR
        (SecurityID IS NOT NULL AND Quantity > 0 AND Price > 0)
    );

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_CurrentHolding_Positive')
    ALTER TABLE trading.CurrentHolding ADD CONSTRAINT CK_CurrentHolding_Positive CHECK (Quantity > 0 AND AverageCost >= 0);

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ComplianceReview_Status')
    ALTER TABLE compliance.ComplianceReview ADD CONSTRAINT CK_ComplianceReview_Status
    CHECK (ReviewStatus IN ('SCHEDULED','IN_PROGRESS','COMPLETED','WAIVED'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ComplianceReview_Completed')
    ALTER TABLE compliance.ComplianceReview ADD CONSTRAINT CK_ComplianceReview_Completed
    CHECK
    (
        (ReviewStatus = 'COMPLETED' AND CompletedDate IS NOT NULL)
        OR
        (ReviewStatus <> 'COMPLETED' AND CompletedDate IS NULL)
    );

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ComplianceAlert_Severity')
    ALTER TABLE compliance.ComplianceAlert ADD CONSTRAINT CK_ComplianceAlert_Severity
    CHECK (Severity IN ('LOW','MEDIUM','HIGH','CRITICAL'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ComplianceAlert_Status')
    ALTER TABLE compliance.ComplianceAlert ADD CONSTRAINT CK_ComplianceAlert_Status
    CHECK (AlertStatus IN ('OPEN','IN_REVIEW','RESOLVED','DISMISSED'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ComplianceAlert_Resolved')
    ALTER TABLE compliance.ComplianceAlert ADD CONSTRAINT CK_ComplianceAlert_Resolved
    CHECK
    (
        (AlertStatus IN ('RESOLVED','DISMISSED') AND ResolvedDate IS NOT NULL)
        OR
        (AlertStatus IN ('OPEN','IN_REVIEW') AND ResolvedDate IS NULL)
    );
GO

/* Foreign keys */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Client_Advisor')
    ALTER TABLE core.Client WITH CHECK ADD CONSTRAINT FK_Client_Advisor
    FOREIGN KEY (AdvisorID) REFERENCES core.Advisor(AdvisorID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ClientRiskProfile_Client')
    ALTER TABLE core.ClientRiskProfile WITH CHECK ADD CONSTRAINT FK_ClientRiskProfile_Client
    FOREIGN KEY (ClientID) REFERENCES core.Client(ClientID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ClientRiskProfile_RiskProfileType')
    ALTER TABLE core.ClientRiskProfile WITH CHECK ADD CONSTRAINT FK_ClientRiskProfile_RiskProfileType
    FOREIGN KEY (RiskProfileTypeID) REFERENCES core.RiskProfileType(RiskProfileTypeID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvestmentAccount_Client')
    ALTER TABLE core.InvestmentAccount WITH CHECK ADD CONSTRAINT FK_InvestmentAccount_Client
    FOREIGN KEY (ClientID) REFERENCES core.Client(ClientID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvestmentAccount_AccountType')
    ALTER TABLE core.InvestmentAccount WITH CHECK ADD CONSTRAINT FK_InvestmentAccount_AccountType
    FOREIGN KEY (AccountTypeID) REFERENCES core.AccountType(AccountTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvestmentAccount_Advisor')
    ALTER TABLE core.InvestmentAccount WITH CHECK ADD CONSTRAINT FK_InvestmentAccount_Advisor
    FOREIGN KEY (AdvisorID) REFERENCES core.Advisor(AdvisorID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Security_AssetClass')
    ALTER TABLE market.Security WITH CHECK ADD CONSTRAINT FK_Security_AssetClass
    FOREIGN KEY (AssetClassID) REFERENCES market.AssetClass(AssetClassID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SecurityPrice_Security')
    ALTER TABLE market.SecurityPrice WITH CHECK ADD CONSTRAINT FK_SecurityPrice_Security
    FOREIGN KEY (SecurityID) REFERENCES market.Security(SecurityID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AccountTransaction_Account')
    ALTER TABLE trading.AccountTransaction WITH CHECK ADD CONSTRAINT FK_AccountTransaction_Account
    FOREIGN KEY (AccountID) REFERENCES core.InvestmentAccount(AccountID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AccountTransaction_TransactionType')
    ALTER TABLE trading.AccountTransaction WITH CHECK ADD CONSTRAINT FK_AccountTransaction_TransactionType
    FOREIGN KEY (TransactionTypeID) REFERENCES trading.TransactionType(TransactionTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AccountTransaction_Security')
    ALTER TABLE trading.AccountTransaction WITH CHECK ADD CONSTRAINT FK_AccountTransaction_Security
    FOREIGN KEY (SecurityID) REFERENCES market.Security(SecurityID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CurrentHolding_Account')
    ALTER TABLE trading.CurrentHolding WITH CHECK ADD CONSTRAINT FK_CurrentHolding_Account
    FOREIGN KEY (AccountID) REFERENCES core.InvestmentAccount(AccountID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CurrentHolding_Security')
    ALTER TABLE trading.CurrentHolding WITH CHECK ADD CONSTRAINT FK_CurrentHolding_Security
    FOREIGN KEY (SecurityID) REFERENCES market.Security(SecurityID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ComplianceReview_Client')
    ALTER TABLE compliance.ComplianceReview WITH CHECK ADD CONSTRAINT FK_ComplianceReview_Client
    FOREIGN KEY (ClientID) REFERENCES core.Client(ClientID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ComplianceReview_Account')
    ALTER TABLE compliance.ComplianceReview WITH CHECK ADD CONSTRAINT FK_ComplianceReview_Account
    FOREIGN KEY (AccountID) REFERENCES core.InvestmentAccount(AccountID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ComplianceAlert_Client')
    ALTER TABLE compliance.ComplianceAlert WITH CHECK ADD CONSTRAINT FK_ComplianceAlert_Client
    FOREIGN KEY (ClientID) REFERENCES core.Client(ClientID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ComplianceAlert_Account')
    ALTER TABLE compliance.ComplianceAlert WITH CHECK ADD CONSTRAINT FK_ComplianceAlert_Account
    FOREIGN KEY (AccountID) REFERENCES core.InvestmentAccount(AccountID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ComplianceAlert_Transaction')
    ALTER TABLE compliance.ComplianceAlert WITH CHECK ADD CONSTRAINT FK_ComplianceAlert_Transaction
    FOREIGN KEY (TransactionID) REFERENCES trading.AccountTransaction(TransactionID);
GO

/* One current risk profile per client. Filtered indexes can enforce this business rule. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_ClientRiskProfile_Current' AND object_id = OBJECT_ID(N'core.ClientRiskProfile'))
    CREATE UNIQUE INDEX UX_ClientRiskProfile_Current
    ON core.ClientRiskProfile(ClientID)
    WHERE IsCurrent = 1;
GO

PRINT N'Created or confirmed database constraints and relationships.';
GO
