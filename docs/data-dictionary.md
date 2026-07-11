# Data dictionary

All content is fictional. Data types reflect the packaged SQL scripts. “Key or constraint” summarizes the most relevant rule; complete definitions are in scripts 03 and 04.

## `core.Advisor`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `AdvisorID` | `int IDENTITY(1,1)` | No | PK | Surrogate identifier for the advisor. |
| `AdvisorCode` | `varchar(20)` | No | UNIQUE | Stable fictional advisor code. |
| `FirstName` | `nvarchar(50)` | No | — | Advisor first name. |
| `LastName` | `nvarchar(50)` | No | — | Advisor last name. |
| `Email` | `varchar(254)` | No | UNIQUE | Synthetic business email. |
| `HireDate` | `date` | No | — | Advisor hire date. |
| `IsActive` | `bit` | No | DEFAULT 1 | Whether the advisor is active. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `ModifiedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC last-modified timestamp. |

## `core.Client`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `ClientID` | `int IDENTITY(1,1)` | No | PK | Surrogate identifier for a fictional client. |
| `ClientCode` | `varchar(20)` | No | UNIQUE | Stable synthetic client code. |
| `FirstName` | `nvarchar(50)` | No | — | Fictional client first name. |
| `LastName` | `nvarchar(50)` | No | — | Fictional client last name. |
| `Email` | `varchar(254)` | Yes | — | Synthetic email; nullable by design. |
| `StateCode` | `char(2)` | No | — | Two-character U.S. state code used in the sample. |
| `AdvisorID` | `int` | No | FK → core.Advisor | Assigned advisor. |
| `ClientSince` | `date` | No | — | Date the fictional relationship began. |
| `IsActive` | `bit` | No | DEFAULT 1 | Whether the client record is active. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `ModifiedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC last-modified timestamp. |

## `core.RiskProfileType`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `RiskProfileTypeID` | `int IDENTITY(1,1)` | No | PK | Surrogate risk-type identifier. |
| `RiskCode` | `varchar(20)` | No | UNIQUE | Stable risk classification code. |
| `RiskName` | `nvarchar(50)` | No | — | Display name. |
| `MinEquityPct` | `decimal(5,2)` | No | CHECK 0–100 | Lower equity-like allocation bound. |
| `MaxEquityPct` | `decimal(5,2)` | No | CHECK 0–100 and ≥ minimum | Upper equity-like allocation bound. |
| `Description` | `nvarchar(250)` | No | — | Plain-language profile description. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |

## `core.ClientRiskProfile`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `ClientRiskProfileID` | `int IDENTITY(1,1)` | No | PK | Surrogate risk-profile history identifier. |
| `ClientID` | `int` | No | FK → core.Client | Client being assessed. |
| `RiskProfileTypeID` | `int` | No | FK → core.RiskProfileType | Assigned classification. |
| `RiskScore` | `tinyint` | No | CHECK 1–100 | Synthetic assessment score. |
| `InvestmentObjective` | `nvarchar(100)` | No | — | Primary fictional objective. |
| `TimeHorizonYears` | `tinyint` | No | CHECK 1–75 | Expected investment horizon. |
| `EffectiveFrom` | `date` | No | — | Start date for this profile. |
| `EffectiveTo` | `date` | Yes | CHECK ≥ EffectiveFrom | End date; NULL for open-ended. |
| `IsCurrent` | `bit` | No | DEFAULT 1; filtered UNIQUE | Marks the single current profile per client. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `ModifiedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC last-modified timestamp. |

## `core.AccountType`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `AccountTypeID` | `int IDENTITY(1,1)` | No | PK | Surrogate account-type identifier. |
| `AccountTypeCode` | `varchar(20)` | No | UNIQUE | Stable account-type code. |
| `AccountTypeName` | `nvarchar(75)` | No | — | Display name. |
| `IsTaxDeferred` | `bit` | No | — | Simplified tax-deferral indicator. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |

## `core.InvestmentAccount`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `AccountID` | `int IDENTITY(1,1)` | No | PK | Surrogate account identifier. |
| `AccountNumber` | `varchar(25)` | No | UNIQUE | Synthetic account number. |
| `ClientID` | `int` | No | FK → core.Client | Owning fictional client. |
| `AccountTypeID` | `int` | No | FK → core.AccountType | Account classification. |
| `AdvisorID` | `int` | No | FK → core.Advisor | Assigned advisor. |
| `OpenDate` | `date` | No | — | Account opening date. |
| `CloseDate` | `date` | Yes | CHECK ≥ OpenDate | Optional closing date. |
| `AccountStatus` | `varchar(15)` | No | DEFAULT OPEN; CHECK list | OPEN, CLOSED, or RESTRICTED. |
| `BaseCurrency` | `char(3)` | No | DEFAULT USD | ISO-style base currency code. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `ModifiedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC last-modified timestamp. |

## `market.AssetClass`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `AssetClassID` | `int IDENTITY(1,1)` | No | PK | Surrogate asset-class identifier. |
| `AssetClassCode` | `varchar(20)` | No | UNIQUE | Stable asset-class code. |
| `AssetClassName` | `nvarchar(75)` | No | — | Display name. |
| `IsEquityLike` | `bit` | No | — | Whether the class counts toward equity allocation. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |

## `market.Security`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `SecurityID` | `int IDENTITY(1,1)` | No | PK | Surrogate security identifier. |
| `Symbol` | `varchar(15)` | No | UNIQUE | Invented portfolio symbol. |
| `SecurityName` | `nvarchar(100)` | No | — | Fictional security name. |
| `AssetClassID` | `int` | No | FK → market.AssetClass | Asset-class classification. |
| `SecurityType` | `varchar(25)` | No | CHECK list | STOCK, ETF, MUTUAL_FUND, BOND, MONEY_MARKET, or REIT. |
| `CurrencyCode` | `char(3)` | No | DEFAULT USD | Trading currency. |
| `IsActive` | `bit` | No | DEFAULT 1 | Whether the security is active. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `ModifiedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC last-modified timestamp. |

## `market.SecurityPrice`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `SecurityPriceID` | `bigint IDENTITY(1,1)` | No | PK | Surrogate price-row identifier. |
| `SecurityID` | `int` | No | FK → market.Security; UNIQUE with date | Priced security. |
| `PriceDate` | `date` | No | UNIQUE with SecurityID | Business date for the synthetic close. |
| `ClosePrice` | `decimal(19,6)` | No | CHECK > 0 | Synthetic closing price. |
| `PriceSource` | `nvarchar(75)` | No | — | Synthetic source label. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |

## `trading.TransactionType`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `TransactionTypeID` | `int IDENTITY(1,1)` | No | PK | Surrogate transaction-type identifier. |
| `TransactionTypeCode` | `varchar(20)` | No | UNIQUE | DEPOSIT, BUY, SELL, DIVIDEND, FEE, or WITHDRAWAL. |
| `TransactionTypeName` | `nvarchar(75)` | No | — | Display name. |
| `CashDirection` | `smallint` | No | CHECK -1 or 1 | Simplified cash-flow direction. |
| `RequiresSecurity` | `bit` | No | — | Whether security, quantity, and price are required. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |

## `trading.AccountTransaction`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `TransactionID` | `bigint IDENTITY(1,1)` | No | PK | Surrogate transaction identifier. |
| `AccountID` | `int` | No | FK → core.InvestmentAccount | Account receiving the activity. |
| `TransactionTypeID` | `int` | No | FK → trading.TransactionType | Activity classification. |
| `SecurityID` | `int` | Yes | FK → market.Security | Security for BUY/SELL; NULL for cash-only rows. |
| `TradeDate` | `date` | No | — | Trade or activity date. |
| `SettlementDate` | `date` | No | CHECK ≥ TradeDate | Settlement date. |
| `Quantity` | `decimal(19,6)` | Yes | CHECK security-field rule | Positive units for security activity. |
| `Price` | `decimal(19,6)` | Yes | CHECK security-field rule | Positive unit price for security activity. |
| `GrossAmount` | `decimal(19,2)` | No | CHECK ≥ 0 | Absolute gross dollar amount. |
| `FeeAmount` | `decimal(19,2)` | No | DEFAULT 0; CHECK ≥ 0 | Associated fee. |
| `ExternalReference` | `varchar(30)` | No | UNIQUE | Synthetic idempotency/reference value. |
| `Notes` | `nvarchar(250)` | Yes | — | Optional explanation. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `CreatedBy` | `sysname` | No | DEFAULT ORIGINAL_LOGIN | Originating SQL Server login name. |

## `trading.CurrentHolding`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `CurrentHoldingID` | `bigint IDENTITY(1,1)` | No | PK | Surrogate holding identifier. |
| `AccountID` | `int` | No | FK → core.InvestmentAccount; UNIQUE with security | Holding account. |
| `SecurityID` | `int` | No | FK → market.Security; UNIQUE with account | Held security. |
| `Quantity` | `decimal(19,6)` | No | CHECK > 0 | Current synthetic units. |
| `AverageCost` | `decimal(19,6)` | No | CHECK ≥ 0 | Weighted-average purchase cost. |
| `AsOfDate` | `date` | No | — | Date through which the holding is represented. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `ModifiedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC last-modified timestamp. |

## `compliance.ComplianceReview`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `ComplianceReviewID` | `bigint IDENTITY(1,1)` | No | PK | Surrogate review identifier. |
| `ClientID` | `int` | No | FK → core.Client | Reviewed client. |
| `AccountID` | `int` | Yes | FK → core.InvestmentAccount | Optional account-specific scope. |
| `ReviewType` | `varchar(30)` | No | — | Synthetic review category. |
| `DueDate` | `date` | No | — | Required review date. |
| `ReviewStatus` | `varchar(20)` | No | CHECK list | SCHEDULED, IN_PROGRESS, COMPLETED, or WAIVED. |
| `CompletedDate` | `date` | Yes | CHECK with status | Required only for completed reviews. |
| `ReviewerName` | `nvarchar(100)` | Yes | — | Synthetic reviewer display name. |
| `Notes` | `nvarchar(500)` | Yes | — | Optional review note. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `ModifiedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC last-modified timestamp. |

## `compliance.ComplianceAlert`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `ComplianceAlertID` | `bigint IDENTITY(1,1)` | No | PK | Surrogate alert identifier. |
| `ClientID` | `int` | No | FK → core.Client | Client associated with the alert. |
| `AccountID` | `int` | Yes | FK → core.InvestmentAccount | Optional account scope. |
| `TransactionID` | `bigint` | Yes | FK → trading.AccountTransaction | Optional triggering transaction. |
| `AlertType` | `varchar(40)` | No | — | Synthetic alert category. |
| `Severity` | `varchar(10)` | No | CHECK list | LOW, MEDIUM, HIGH, or CRITICAL. |
| `AlertStatus` | `varchar(20)` | No | CHECK list | OPEN, IN_REVIEW, RESOLVED, or DISMISSED. |
| `AlertDate` | `date` | No | — | Date the synthetic alert was created. |
| `ResolvedDate` | `date` | Yes | CHECK with status | Required for resolved or dismissed alerts. |
| `Description` | `nvarchar(500)` | No | — | Synthetic alert explanation. |
| `CreatedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC row creation timestamp. |
| `ModifiedAt` | `datetime2(0)` | No | DEFAULT UTC | UTC last-modified timestamp. |

## `audit.ActivityLog`

| Column | Data type | Nullable | Key or constraint | Business meaning |
|---|---|---:|---|---|
| `ActivityLogID` | `bigint IDENTITY(1,1)` | No | PK | Surrogate audit-event identifier. |
| `EventTime` | `datetime2(0)` | No | DEFAULT UTC | UTC event timestamp. |
| `DatabaseUser` | `sysname` | No | DEFAULT USER_NAME | Effective database principal. |
| `LoginName` | `sysname` | No | DEFAULT ORIGINAL_LOGIN | Original server login. |
| `ActionName` | `varchar(50)` | No | — | Controlled action label. |
| `SchemaName` | `sysname` | Yes | — | Affected schema. |
| `ObjectName` | `sysname` | Yes | — | Affected object. |
| `RecordKey` | `nvarchar(100)` | Yes | — | Text form of affected record identifier. |
| `Details` | `nvarchar(1000)` | Yes | — | Human-readable event detail. |
| `CorrelationID` | `uniqueidentifier` | No | DEFAULT NEWID | Identifier linking related actions. |
