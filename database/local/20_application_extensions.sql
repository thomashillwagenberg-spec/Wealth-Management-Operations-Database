/*
  20_application_extensions.sql
  Purpose: Add application identity, concurrency, idempotency, and append-oriented audit objects.
  Apply after the original local scripts 02 through 11.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF SCHEMA_ID(N'security') IS NULL EXEC(N'CREATE SCHEMA security AUTHORIZATION dbo;');
GO

IF OBJECT_ID(N'security.AppUser', N'U') IS NULL
BEGIN
    CREATE TABLE security.AppUser
    (
        AppUserID          int IDENTITY(1,1) NOT NULL CONSTRAINT PK_AppUser PRIMARY KEY,
        EntraObjectID      uniqueidentifier NULL,
        UserPrincipalName  nvarchar(254) NOT NULL,
        DisplayName        nvarchar(150) NOT NULL,
        RoleName           varchar(40) NOT NULL,
        AdvisorID          int NULL,
        IsActive           bit NOT NULL CONSTRAINT DF_AppUser_IsActive DEFAULT (1),
        CreatedAt          datetime2(0) NOT NULL CONSTRAINT DF_AppUser_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ModifiedAt         datetime2(0) NOT NULL CONSTRAINT DF_AppUser_ModifiedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion         rowversion NOT NULL,
        CONSTRAINT UQ_AppUser_UserPrincipalName UNIQUE (UserPrincipalName),
        CONSTRAINT CK_AppUser_Role CHECK (RoleName IN ('DatabaseAdministrator','AdvisorUser','ComplianceReviewer','ReportingAnalyst','ReadOnlyAuditor')),
        CONSTRAINT CK_AppUser_AdvisorMapping CHECK ((RoleName = 'AdvisorUser' AND AdvisorID IS NOT NULL) OR RoleName <> 'AdvisorUser'),
        CONSTRAINT FK_AppUser_Advisor FOREIGN KEY (AdvisorID) REFERENCES core.Advisor(AdvisorID)
    );
    CREATE UNIQUE INDEX UX_AppUser_EntraObjectID ON security.AppUser(EntraObjectID) WHERE EntraObjectID IS NOT NULL;
END;
GO

IF OBJECT_ID(N'audit.IdempotencyRecord', N'U') IS NULL
BEGIN
    CREATE TABLE audit.IdempotencyRecord
    (
        IdempotencyKey  varchar(100) NOT NULL CONSTRAINT PK_IdempotencyRecord PRIMARY KEY,
        OperationName   varchar(80) NOT NULL,
        RequestHash     char(64) NOT NULL,
        OperationStatus varchar(20) NOT NULL,
        TransactionID   bigint NULL,
        CorrelationID   uniqueidentifier NOT NULL,
        ResponseMessage nvarchar(250) NULL,
        CreatedAt       datetime2(0) NOT NULL CONSTRAINT DF_IdempotencyRecord_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CompletedAt     datetime2(0) NULL,
        ExpiresAt       datetime2(0) NOT NULL,
        CONSTRAINT CK_IdempotencyRecord_Status CHECK (OperationStatus IN ('IN_PROGRESS','COMPLETED','FAILED')),
        CONSTRAINT FK_IdempotencyRecord_Transaction FOREIGN KEY (TransactionID) REFERENCES trading.AccountTransaction(TransactionID)
    );
    CREATE INDEX IX_IdempotencyRecord_ExpiresAt ON audit.IdempotencyRecord(ExpiresAt) INCLUDE (OperationStatus);
END;
GO

IF OBJECT_ID(N'audit.AuditEvent', N'U') IS NULL
BEGIN
    CREATE TABLE audit.AuditEvent
    (
        AuditEventID   bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditEvent PRIMARY KEY,
        EventTime      datetime2(3) NOT NULL CONSTRAINT DF_AuditEvent_EventTime DEFAULT (SYSUTCDATETIME()),
        ActorID        nvarchar(254) NOT NULL,
        ActionName     varchar(80) NOT NULL,
        EntityType     varchar(80) NOT NULL,
        EntityID       nvarchar(100) NULL,
        Outcome        varchar(20) NOT NULL,
        CorrelationID  uniqueidentifier NOT NULL,
        MetadataJson   nvarchar(2000) NULL,
        PreviousHash   varbinary(32) NULL,
        EventHash      varbinary(32) NOT NULL,
        CONSTRAINT CK_AuditEvent_Outcome CHECK (Outcome IN ('SUCCESS','DENIED','FAILED')),
        CONSTRAINT CK_AuditEvent_MetadataJson CHECK (MetadataJson IS NULL OR ISJSON(MetadataJson) = 1)
    );
    CREATE INDEX IX_AuditEvent_EventTime ON audit.AuditEvent(EventTime DESC) INCLUDE (ActorID, ActionName, EntityType, Outcome, CorrelationID);
    CREATE INDEX IX_AuditEvent_CorrelationID ON audit.AuditEvent(CorrelationID);
END;
GO

CREATE OR ALTER PROCEDURE audit.usp_AppendAuditEvent
    @ActorID nvarchar(254),
    @ActionName varchar(80),
    @EntityType varchar(80),
    @EntityID nvarchar(100) = NULL,
    @Outcome varchar(20),
    @CorrelationID uniqueidentifier,
    @MetadataJson nvarchar(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Outcome NOT IN ('SUCCESS','DENIED','FAILED') THROW 52130, 'Invalid audit outcome.', 1;
    IF @MetadataJson IS NOT NULL AND ISJSON(@MetadataJson) <> 1 THROW 52131, 'Audit metadata must be valid JSON.', 1;

    DECLARE @PreviousHash varbinary(32), @EventHash varbinary(32), @EventTime datetime2(3) = SYSUTCDATETIME();
    DECLARE @Payload nvarchar(max);

    DECLARE @LockResult int;
    BEGIN TRANSACTION;
    EXEC @LockResult = sys.sp_getapplock @Resource = N'WM_AUDIT_HASH_CHAIN', @LockMode = N'Exclusive', @LockOwner = N'Transaction', @LockTimeout = 10000;
    IF @LockResult < 0
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 52133, 'The audit hash-chain lock could not be acquired.', 1;
    END;
    SELECT TOP (1) @PreviousHash = EventHash FROM audit.AuditEvent WITH (UPDLOCK, HOLDLOCK) ORDER BY AuditEventID DESC;
    SET @Payload = CONCAT(CONVERT(varchar(64), @PreviousHash, 2), N'|', CONVERT(nvarchar(33), @EventTime, 126), N'|', @ActorID, N'|', @ActionName, N'|', @EntityType, N'|', COALESCE(@EntityID,N''), N'|', @Outcome, N'|', CONVERT(nvarchar(36), @CorrelationID), N'|', COALESCE(@MetadataJson,N''));
    SET @EventHash = HASHBYTES('SHA2_256', CONVERT(varbinary(max), @Payload));

    INSERT INTO audit.AuditEvent(EventTime, ActorID, ActionName, EntityType, EntityID, Outcome, CorrelationID, MetadataJson, PreviousHash, EventHash)
    VALUES(@EventTime, @ActorID, @ActionName, @EntityType, @EntityID, @Outcome, @CorrelationID, @MetadataJson, @PreviousHash, @EventHash);
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER TRIGGER audit.trg_AuditEvent_AppendOnly
ON audit.AuditEvent
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    THROW 52132, 'Audit events are append-only and cannot be updated or deleted.', 1;
END;
GO

IF COL_LENGTH(N'core.ClientRiskProfile', N'RowVersion') IS NULL ALTER TABLE core.ClientRiskProfile ADD RowVersion rowversion;
IF COL_LENGTH(N'compliance.ComplianceReview', N'RowVersion') IS NULL ALTER TABLE compliance.ComplianceReview ADD RowVersion rowversion;
IF COL_LENGTH(N'compliance.ComplianceAlert', N'RowVersion') IS NULL ALTER TABLE compliance.ComplianceAlert ADD RowVersion rowversion;
GO

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_Client_ClientID_AdvisorID')
    ALTER TABLE core.Client ADD CONSTRAINT UQ_Client_ClientID_AdvisorID UNIQUE (ClientID, AdvisorID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvestmentAccount_ClientAdvisor')
    ALTER TABLE core.InvestmentAccount WITH CHECK ADD CONSTRAINT FK_InvestmentAccount_ClientAdvisor FOREIGN KEY (ClientID, AdvisorID) REFERENCES core.Client(ClientID, AdvisorID);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_InvestmentAccount_AccountID_ClientID')
    ALTER TABLE core.InvestmentAccount ADD CONSTRAINT UQ_InvestmentAccount_AccountID_ClientID UNIQUE (AccountID, ClientID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ComplianceReview_AccountClient')
    ALTER TABLE compliance.ComplianceReview WITH CHECK ADD CONSTRAINT FK_ComplianceReview_AccountClient FOREIGN KEY (AccountID, ClientID) REFERENCES core.InvestmentAccount(AccountID, ClientID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ComplianceAlert_AccountClient')
    ALTER TABLE compliance.ComplianceAlert WITH CHECK ADD CONSTRAINT FK_ComplianceAlert_AccountClient FOREIGN KEY (AccountID, ClientID) REFERENCES core.InvestmentAccount(AccountID, ClientID);
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_AccountTransaction_TransactionID_AccountID')
    ALTER TABLE trading.AccountTransaction ADD CONSTRAINT UQ_AccountTransaction_TransactionID_AccountID UNIQUE (TransactionID, AccountID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ComplianceAlert_TransactionAccount')
    ALTER TABLE compliance.ComplianceAlert WITH CHECK ADD CONSTRAINT FK_ComplianceAlert_TransactionAccount FOREIGN KEY (TransactionID, AccountID) REFERENCES trading.AccountTransaction(TransactionID, AccountID);
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ComplianceAlert_TransactionRequiresAccount')
    ALTER TABLE compliance.ComplianceAlert WITH CHECK ADD CONSTRAINT CK_ComplianceAlert_TransactionRequiresAccount CHECK (TransactionID IS NULL OR AccountID IS NOT NULL);
GO

MERGE security.AppUser AS target
USING (VALUES
    (N'admin@local.test', N'Local Database Administrator', 'DatabaseAdministrator', NULL),
    (N'advisor1@local.test', N'Local Advisor One', 'AdvisorUser', 1),
    (N'compliance@local.test', N'Local Compliance Reviewer', 'ComplianceReviewer', NULL),
    (N'reporting@local.test', N'Local Reporting Analyst', 'ReportingAnalyst', NULL),
    (N'auditor@local.test', N'Local Read-Only Auditor', 'ReadOnlyAuditor', NULL)
) AS source(UserPrincipalName, DisplayName, RoleName, AdvisorID)
ON target.UserPrincipalName = source.UserPrincipalName
WHEN MATCHED THEN UPDATE SET DisplayName = source.DisplayName, RoleName = source.RoleName, AdvisorID = source.AdvisorID, IsActive = 1, ModifiedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT(UserPrincipalName, DisplayName, RoleName, AdvisorID) VALUES(source.UserPrincipalName, source.DisplayName, source.RoleName, source.AdvisorID);
GO

PRINT N'Application extension objects created or confirmed.';
GO
