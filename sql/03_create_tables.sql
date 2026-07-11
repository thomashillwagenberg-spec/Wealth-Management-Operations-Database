
/*
  03_create_tables.sql
  Purpose: Create the normalized base tables.
  Database context: WealthManagementOperations.
  Notes: Relationships and most named constraints are added in script 04.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'core.Advisor', N'U') IS NULL
BEGIN
    CREATE TABLE core.Advisor
    (
        AdvisorID      int IDENTITY(1,1) NOT NULL,
        AdvisorCode    varchar(20) NOT NULL,
        FirstName      nvarchar(50) NOT NULL,
        LastName       nvarchar(50) NOT NULL,
        Email          varchar(254) NOT NULL,
        HireDate       date NOT NULL,
        IsActive       bit NOT NULL CONSTRAINT DF_Advisor_IsActive DEFAULT (1),
        CreatedAt      datetime2(0) NOT NULL CONSTRAINT DF_Advisor_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt     datetime2(0) NOT NULL CONSTRAINT DF_Advisor_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_Advisor PRIMARY KEY CLUSTERED (AdvisorID)
    );
END;
GO

IF OBJECT_ID(N'core.Client', N'U') IS NULL
BEGIN
    CREATE TABLE core.Client
    (
        ClientID       int IDENTITY(1,1) NOT NULL,
        ClientCode     varchar(20) NOT NULL,
        FirstName      nvarchar(50) NOT NULL,
        LastName       nvarchar(50) NOT NULL,
        Email          varchar(254) NULL,
        StateCode      char(2) NOT NULL,
        AdvisorID      int NOT NULL,
        ClientSince    date NOT NULL,
        IsActive       bit NOT NULL CONSTRAINT DF_Client_IsActive DEFAULT (1),
        CreatedAt      datetime2(0) NOT NULL CONSTRAINT DF_Client_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt     datetime2(0) NOT NULL CONSTRAINT DF_Client_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_Client PRIMARY KEY CLUSTERED (ClientID)
    );
END;
GO

IF OBJECT_ID(N'core.RiskProfileType', N'U') IS NULL
BEGIN
    CREATE TABLE core.RiskProfileType
    (
        RiskProfileTypeID int IDENTITY(1,1) NOT NULL,
        RiskCode          varchar(20) NOT NULL,
        RiskName          nvarchar(50) NOT NULL,
        MinEquityPct      decimal(5,2) NOT NULL,
        MaxEquityPct      decimal(5,2) NOT NULL,
        Description       nvarchar(250) NOT NULL,
        CreatedAt         datetime2(0) NOT NULL CONSTRAINT DF_RiskProfileType_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_RiskProfileType PRIMARY KEY CLUSTERED (RiskProfileTypeID)
    );
END;
GO

IF OBJECT_ID(N'core.ClientRiskProfile', N'U') IS NULL
BEGIN
    CREATE TABLE core.ClientRiskProfile
    (
        ClientRiskProfileID int IDENTITY(1,1) NOT NULL,
        ClientID             int NOT NULL,
        RiskProfileTypeID    int NOT NULL,
        RiskScore            tinyint NOT NULL,
        InvestmentObjective  nvarchar(100) NOT NULL,
        TimeHorizonYears      tinyint NOT NULL,
        EffectiveFrom        date NOT NULL,
        EffectiveTo          date NULL,
        IsCurrent            bit NOT NULL CONSTRAINT DF_ClientRiskProfile_IsCurrent DEFAULT (1),
        CreatedAt            datetime2(0) NOT NULL CONSTRAINT DF_ClientRiskProfile_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt           datetime2(0) NOT NULL CONSTRAINT DF_ClientRiskProfile_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_ClientRiskProfile PRIMARY KEY CLUSTERED (ClientRiskProfileID)
    );
END;
GO

IF OBJECT_ID(N'core.AccountType', N'U') IS NULL
BEGIN
    CREATE TABLE core.AccountType
    (
        AccountTypeID    int IDENTITY(1,1) NOT NULL,
        AccountTypeCode  varchar(20) NOT NULL,
        AccountTypeName  nvarchar(75) NOT NULL,
        IsTaxDeferred    bit NOT NULL,
        CreatedAt        datetime2(0) NOT NULL CONSTRAINT DF_AccountType_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_AccountType PRIMARY KEY CLUSTERED (AccountTypeID)
    );
END;
GO

IF OBJECT_ID(N'core.InvestmentAccount', N'U') IS NULL
BEGIN
    CREATE TABLE core.InvestmentAccount
    (
        AccountID        int IDENTITY(1,1) NOT NULL,
        AccountNumber    varchar(25) NOT NULL,
        ClientID         int NOT NULL,
        AccountTypeID    int NOT NULL,
        AdvisorID        int NOT NULL,
        OpenDate         date NOT NULL,
        CloseDate        date NULL,
        AccountStatus    varchar(15) NOT NULL CONSTRAINT DF_InvestmentAccount_Status DEFAULT ('OPEN'),
        BaseCurrency     char(3) NOT NULL CONSTRAINT DF_InvestmentAccount_Currency DEFAULT ('USD'),
        CreatedAt        datetime2(0) NOT NULL CONSTRAINT DF_InvestmentAccount_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt       datetime2(0) NOT NULL CONSTRAINT DF_InvestmentAccount_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_InvestmentAccount PRIMARY KEY CLUSTERED (AccountID)
    );
END;
GO

IF OBJECT_ID(N'market.AssetClass', N'U') IS NULL
BEGIN
    CREATE TABLE market.AssetClass
    (
        AssetClassID     int IDENTITY(1,1) NOT NULL,
        AssetClassCode   varchar(20) NOT NULL,
        AssetClassName   nvarchar(75) NOT NULL,
        IsEquityLike     bit NOT NULL,
        CreatedAt        datetime2(0) NOT NULL CONSTRAINT DF_AssetClass_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_AssetClass PRIMARY KEY CLUSTERED (AssetClassID)
    );
END;
GO

IF OBJECT_ID(N'market.Security', N'U') IS NULL
BEGIN
    CREATE TABLE market.Security
    (
        SecurityID       int IDENTITY(1,1) NOT NULL,
        Symbol           varchar(15) NOT NULL,
        SecurityName     nvarchar(100) NOT NULL,
        AssetClassID     int NOT NULL,
        SecurityType     varchar(25) NOT NULL,
        CurrencyCode     char(3) NOT NULL CONSTRAINT DF_Security_Currency DEFAULT ('USD'),
        IsActive         bit NOT NULL CONSTRAINT DF_Security_IsActive DEFAULT (1),
        CreatedAt        datetime2(0) NOT NULL CONSTRAINT DF_Security_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt       datetime2(0) NOT NULL CONSTRAINT DF_Security_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_Security PRIMARY KEY CLUSTERED (SecurityID)
    );
END;
GO

IF OBJECT_ID(N'market.SecurityPrice', N'U') IS NULL
BEGIN
    CREATE TABLE market.SecurityPrice
    (
        SecurityPriceID  bigint IDENTITY(1,1) NOT NULL,
        SecurityID       int NOT NULL,
        PriceDate        date NOT NULL,
        ClosePrice       decimal(19,6) NOT NULL,
        PriceSource      nvarchar(75) NOT NULL,
        CreatedAt        datetime2(0) NOT NULL CONSTRAINT DF_SecurityPrice_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_SecurityPrice PRIMARY KEY CLUSTERED (SecurityPriceID)
    );
END;
GO

IF OBJECT_ID(N'trading.TransactionType', N'U') IS NULL
BEGIN
    CREATE TABLE trading.TransactionType
    (
        TransactionTypeID    int IDENTITY(1,1) NOT NULL,
        TransactionTypeCode  varchar(20) NOT NULL,
        TransactionTypeName  nvarchar(75) NOT NULL,
        CashDirection        smallint NOT NULL,
        RequiresSecurity     bit NOT NULL,
        CreatedAt            datetime2(0) NOT NULL CONSTRAINT DF_TransactionType_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_TransactionType PRIMARY KEY CLUSTERED (TransactionTypeID)
    );
END;
GO

IF OBJECT_ID(N'trading.AccountTransaction', N'U') IS NULL
BEGIN
    CREATE TABLE trading.AccountTransaction
    (
        TransactionID      bigint IDENTITY(1,1) NOT NULL,
        AccountID          int NOT NULL,
        TransactionTypeID  int NOT NULL,
        SecurityID         int NULL,
        TradeDate          date NOT NULL,
        SettlementDate     date NOT NULL,
        Quantity           decimal(19,6) NULL,
        Price              decimal(19,6) NULL,
        GrossAmount        decimal(19,2) NOT NULL,
        FeeAmount          decimal(19,2) NOT NULL CONSTRAINT DF_AccountTransaction_Fee DEFAULT (0),
        ExternalReference  varchar(30) NOT NULL,
        Notes              nvarchar(250) NULL,
        CreatedAt          datetime2(0) NOT NULL CONSTRAINT DF_AccountTransaction_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CreatedBy          sysname NOT NULL CONSTRAINT DF_AccountTransaction_CreatedBy DEFAULT (ORIGINAL_LOGIN()),
        CONSTRAINT PK_AccountTransaction PRIMARY KEY CLUSTERED (TransactionID)
    );
END;
GO

IF OBJECT_ID(N'trading.CurrentHolding', N'U') IS NULL
BEGIN
    CREATE TABLE trading.CurrentHolding
    (
        CurrentHoldingID  bigint IDENTITY(1,1) NOT NULL,
        AccountID         int NOT NULL,
        SecurityID        int NOT NULL,
        Quantity          decimal(19,6) NOT NULL,
        AverageCost       decimal(19,6) NOT NULL,
        AsOfDate          date NOT NULL,
        CreatedAt         datetime2(0) NOT NULL CONSTRAINT DF_CurrentHolding_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt        datetime2(0) NOT NULL CONSTRAINT DF_CurrentHolding_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_CurrentHolding PRIMARY KEY CLUSTERED (CurrentHoldingID)
    );
END;
GO

IF OBJECT_ID(N'compliance.ComplianceReview', N'U') IS NULL
BEGIN
    CREATE TABLE compliance.ComplianceReview
    (
        ComplianceReviewID bigint IDENTITY(1,1) NOT NULL,
        ClientID            int NOT NULL,
        AccountID           int NULL,
        ReviewType          varchar(30) NOT NULL,
        DueDate             date NOT NULL,
        ReviewStatus        varchar(20) NOT NULL,
        CompletedDate       date NULL,
        ReviewerName        nvarchar(100) NULL,
        Notes               nvarchar(500) NULL,
        CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_ComplianceReview_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt          datetime2(0) NOT NULL CONSTRAINT DF_ComplianceReview_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_ComplianceReview PRIMARY KEY CLUSTERED (ComplianceReviewID)
    );
END;
GO

IF OBJECT_ID(N'compliance.ComplianceAlert', N'U') IS NULL
BEGIN
    CREATE TABLE compliance.ComplianceAlert
    (
        ComplianceAlertID bigint IDENTITY(1,1) NOT NULL,
        ClientID           int NOT NULL,
        AccountID          int NULL,
        TransactionID      bigint NULL,
        AlertType           varchar(40) NOT NULL,
        Severity            varchar(10) NOT NULL,
        AlertStatus         varchar(20) NOT NULL,
        AlertDate           date NOT NULL,
        ResolvedDate        date NULL,
        Description         nvarchar(500) NOT NULL,
        CreatedAt           datetime2(0) NOT NULL CONSTRAINT DF_ComplianceAlert_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt          datetime2(0) NOT NULL CONSTRAINT DF_ComplianceAlert_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_ComplianceAlert PRIMARY KEY CLUSTERED (ComplianceAlertID)
    );
END;
GO

IF OBJECT_ID(N'audit.ActivityLog', N'U') IS NULL
BEGIN
    CREATE TABLE audit.ActivityLog
    (
        ActivityLogID   bigint IDENTITY(1,1) NOT NULL,
        EventTime       datetime2(0) NOT NULL CONSTRAINT DF_ActivityLog_EventTime DEFAULT (SYSUTCDATETIME()),
        DatabaseUser    sysname NOT NULL CONSTRAINT DF_ActivityLog_DatabaseUser DEFAULT (USER_NAME()),
        LoginName       sysname NOT NULL CONSTRAINT DF_ActivityLog_LoginName DEFAULT (ORIGINAL_LOGIN()),
        ActionName      varchar(50) NOT NULL,
        SchemaName      sysname NULL,
        ObjectName      sysname NULL,
        RecordKey       nvarchar(100) NULL,
        Details         nvarchar(1000) NULL,
        CorrelationID   uniqueidentifier NOT NULL CONSTRAINT DF_ActivityLog_CorrelationID DEFAULT (NEWID()),
        CONSTRAINT PK_ActivityLog PRIMARY KEY CLUSTERED (ActivityLogID)
    );
END;
GO

PRINT N'Created or confirmed all 15 base tables.';
GO
