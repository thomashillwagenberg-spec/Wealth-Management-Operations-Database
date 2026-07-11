/*
  22_application_procedures.sql
  Purpose: Add parameterized, policy-aware procedures used by the Dapper application layer.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE trading.usp_SubmitTrade
    @IdempotencyKey varchar(100),
    @RequestHash char(64),
    @AccountID int,
    @TransactionTypeCode varchar(20),
    @SecurityID int,
    @TradeDate date,
    @SettlementDate date,
    @Quantity decimal(19,6),
    @Price decimal(19,6),
    @FeeAmount decimal(19,2),
    @ExternalReference varchar(30),
    @Notes nvarchar(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ActorID nvarchar(254) = TRY_CONVERT(nvarchar(254), SESSION_CONTEXT(N'ActorId'));
    DECLARE @RoleName varchar(40) = TRY_CONVERT(varchar(40), SESSION_CONTEXT(N'RoleName'));
    DECLARE @CorrelationID uniqueidentifier = COALESCE(TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'CorrelationId')), NEWID());
    DECLARE @ExistingHash char(64), @ExistingStatus varchar(20), @ExistingTransactionID bigint, @ExistingMessage nvarchar(250), @ExistingCorrelationID uniqueidentifier;

    IF @ActorID IS NULL THROW 52102, 'Application execution context is missing.', 1;
    IF @RoleName NOT IN ('DatabaseAdministrator','AdvisorUser') THROW 52103, 'The current role cannot submit trades.', 1;
    IF LEN(@IdempotencyKey) < 12 OR LEN(@RequestHash) <> 64 THROW 52104, 'Invalid idempotency metadata.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ExistingHash = RequestHash, @ExistingStatus = OperationStatus, @ExistingTransactionID = TransactionID, @ExistingMessage = ResponseMessage, @ExistingCorrelationID = CorrelationID
        FROM audit.IdempotencyRecord WITH (UPDLOCK, HOLDLOCK)
        WHERE IdempotencyKey = @IdempotencyKey AND OperationName = 'SUBMIT_TRADE';

        IF @ExistingHash IS NOT NULL
        BEGIN
            IF @ExistingHash <> @RequestHash THROW 52104, 'The idempotency key was reused with a different request.', 1;
            IF @ExistingStatus = 'COMPLETED'
            BEGIN
                COMMIT TRANSACTION;
                SELECT @ExistingTransactionID AS TransactionID, @ExistingCorrelationID AS CorrelationID, CONVERT(bit,1) AS WasReplay, COALESCE(@ExistingMessage,N'Previously completed trade returned.') AS ResultMessage;
                RETURN;
            END;
            THROW 52105, 'An operation with this idempotency key is already in progress.', 1;
        END;

        IF NOT EXISTS (SELECT 1 FROM core.InvestmentAccount WHERE AccountID = @AccountID AND AccountStatus = 'OPEN')
            THROW 52106, 'Account is not open or is outside the authorized scope.', 1;

        INSERT INTO audit.IdempotencyRecord(IdempotencyKey, OperationName, RequestHash, OperationStatus, CorrelationID, ExpiresAt)
        VALUES(@IdempotencyKey, 'SUBMIT_TRADE', @RequestHash, 'IN_PROGRESS', @CorrelationID, DATEADD(DAY, 7, SYSUTCDATETIME()));

        DECLARE @TradeResult TABLE(TransactionID bigint, CorrelationID uniqueidentifier, ResultMessage nvarchar(250));
        INSERT INTO @TradeResult
        EXEC trading.usp_RecordTrade
            @AccountID=@AccountID,
            @TransactionTypeCode=@TransactionTypeCode,
            @SecurityID=@SecurityID,
            @TradeDate=@TradeDate,
            @SettlementDate=@SettlementDate,
            @Quantity=@Quantity,
            @Price=@Price,
            @FeeAmount=@FeeAmount,
            @ExternalReference=@ExternalReference,
            @Notes=@Notes;

        SELECT TOP (1) @ExistingTransactionID = TransactionID, @ExistingMessage = ResultMessage FROM @TradeResult;
        UPDATE audit.IdempotencyRecord
        SET OperationStatus='COMPLETED', TransactionID=@ExistingTransactionID, ResponseMessage=@ExistingMessage, CompletedAt=SYSUTCDATETIME()
        WHERE IdempotencyKey=@IdempotencyKey;

        EXEC audit.usp_AppendAuditEvent @ActorID=@ActorID, @ActionName='SUBMIT_TRADE', @EntityType='AccountTransaction', @EntityID=CONVERT(nvarchar(100),@ExistingTransactionID), @Outcome='SUCCESS', @CorrelationID=@CorrelationID, @MetadataJson=NULL;
        COMMIT TRANSACTION;

        SELECT @ExistingTransactionID AS TransactionID, @CorrelationID AS CorrelationID, CONVERT(bit,0) AS WasReplay, @ExistingMessage AS ResultMessage;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        BEGIN TRY
            EXEC audit.usp_AppendAuditEvent @ActorID=COALESCE(@ActorID,N'unknown'), @ActionName='SUBMIT_TRADE', @EntityType='AccountTransaction', @EntityID=NULL, @Outcome='FAILED', @CorrelationID=@CorrelationID, @MetadataJson=NULL;
        END TRY
        BEGIN CATCH
            -- Audit failure must not replace the original exception.
        END CATCH;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE compliance.usp_ListAlerts
    @Page int = 1,
    @PageSize int = 25,
    @Status varchar(20) = NULL,
    @Severity varchar(10) = NULL,
    @ClientID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 OR @PageSize NOT BETWEEN 1 AND 100 THROW 52120, 'Invalid pagination values.', 1;

    SELECT
        ca.ComplianceAlertID,
        ca.ClientID,
        c.ClientCode,
        CONCAT(c.FirstName,N' ',c.LastName) AS ClientName,
        ca.AccountID,
        ia.AccountNumber,
        ca.TransactionID,
        ca.AlertType,
        ca.Severity,
        ca.AlertStatus,
        ca.AlertDate,
        ca.ResolvedDate,
        ca.Description,
        ca.ModifiedAt,
        ca.RowVersion,
        COUNT_BIG(*) OVER () AS TotalCount
    FROM compliance.ComplianceAlert AS ca
    INNER JOIN core.Client AS c ON c.ClientID=ca.ClientID
    LEFT JOIN core.InvestmentAccount AS ia ON ia.AccountID=ca.AccountID
    WHERE (@Status IS NULL OR ca.AlertStatus=@Status)
      AND (@Severity IS NULL OR ca.Severity=@Severity)
      AND (@ClientID IS NULL OR ca.ClientID=@ClientID)
    ORDER BY ca.AlertDate DESC, ca.ComplianceAlertID DESC
    OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE compliance.usp_UpdateAlertStatusSecure
    @ComplianceAlertID bigint,
    @NewStatus varchar(20),
    @ResolutionNote nvarchar(500) = NULL,
    @ExpectedRowVersion binary(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @ActorID nvarchar(254)=TRY_CONVERT(nvarchar(254),SESSION_CONTEXT(N'ActorId'));
    DECLARE @RoleName varchar(40)=TRY_CONVERT(varchar(40),SESSION_CONTEXT(N'RoleName'));
    DECLARE @CorrelationID uniqueidentifier=COALESCE(TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'CorrelationId')),NEWID());

    IF @RoleName NOT IN ('DatabaseAdministrator','ComplianceReviewer') THROW 52123, 'The current role cannot update compliance alerts.', 1;
    IF @NewStatus NOT IN ('OPEN','IN_REVIEW','RESOLVED','DISMISSED') THROW 52124, 'Invalid alert status.', 1;

    BEGIN TRANSACTION;
    UPDATE compliance.ComplianceAlert
    SET AlertStatus=@NewStatus,
        ResolvedDate=CASE WHEN @NewStatus IN ('RESOLVED','DISMISSED') THEN CONVERT(date,SYSUTCDATETIME()) ELSE NULL END,
        Description=CASE WHEN @ResolutionNote IS NULL THEN Description ELSE CONCAT(Description,N' | Note: ',@ResolutionNote) END,
        ModifiedAt=SYSUTCDATETIME()
    WHERE ComplianceAlertID=@ComplianceAlertID AND RowVersion=@ExpectedRowVersion;

    IF @@ROWCOUNT=0
    BEGIN
        IF EXISTS(SELECT 1 FROM compliance.ComplianceAlert WHERE ComplianceAlertID=@ComplianceAlertID) THROW 52122, 'The compliance alert changed after it was read.', 1;
        THROW 52121, 'Compliance alert was not found.', 1;
    END;

    EXEC audit.usp_AppendAuditEvent @ActorID=@ActorID, @ActionName='UPDATE_ALERT_STATUS', @EntityType='ComplianceAlert', @EntityID=CONVERT(nvarchar(100),@ComplianceAlertID), @Outcome='SUCCESS', @CorrelationID=@CorrelationID, @MetadataJson=NULL;
    COMMIT TRANSACTION;

    SELECT ComplianceAlertID, AlertStatus, ResolvedDate, ModifiedAt, RowVersion, @CorrelationID AS CorrelationID
    FROM compliance.ComplianceAlert WHERE ComplianceAlertID=@ComplianceAlertID;
END;
GO

CREATE OR ALTER PROCEDURE reporting.usp_GetConcentration
    @AccountID int = NULL,
    @MinimumPct decimal(9,2) = 10.00
AS
BEGIN
    SET NOCOUNT ON;
    IF @MinimumPct <= 0 OR @MinimumPct > 100 THROW 52140, 'Minimum concentration must be greater than zero and no more than 100.', 1;

    WITH LatestPrice AS
    (
        SELECT ch.AccountID,ch.SecurityID,ch.Quantity,sp.ClosePrice,
               ROW_NUMBER() OVER(PARTITION BY ch.AccountID,ch.SecurityID ORDER BY sp.PriceDate DESC) AS rn
        FROM trading.CurrentHolding AS ch
        INNER JOIN market.SecurityPrice AS sp ON sp.SecurityID=ch.SecurityID AND sp.PriceDate<=ch.AsOfDate
        WHERE @AccountID IS NULL OR ch.AccountID=@AccountID
    ), ValuesByPosition AS
    (
        SELECT lp.AccountID,lp.SecurityID,CAST(lp.Quantity*lp.ClosePrice AS decimal(19,2)) AS MarketValue
        FROM LatestPrice AS lp WHERE lp.rn=1
    ), Concentration AS
    (
        SELECT v.AccountID,v.SecurityID,v.MarketValue,
               CAST(SUM(v.MarketValue) OVER(PARTITION BY v.AccountID) AS decimal(19,2)) AS AccountValue
        FROM ValuesByPosition AS v
    )
    SELECT ia.AccountID,ia.AccountNumber,s.SecurityID,s.Symbol,s.SecurityName,c.MarketValue,c.AccountValue,
           CAST(100.0*c.MarketValue/NULLIF(c.AccountValue,0) AS decimal(9,2)) AS ConcentrationPct
    FROM Concentration AS c
    INNER JOIN core.InvestmentAccount AS ia ON ia.AccountID=c.AccountID
    INNER JOIN market.Security AS s ON s.SecurityID=c.SecurityID
    WHERE 100.0*c.MarketValue/NULLIF(c.AccountValue,0)>=@MinimumPct
    ORDER BY ConcentrationPct DESC, ia.AccountID;
END;
GO

CREATE OR ALTER PROCEDURE reporting.usp_GetAdvisorActivitySecure
    @AdvisorID int,
    @StartDate date,
    @EndDate date
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @RoleName varchar(40)=TRY_CONVERT(varchar(40),SESSION_CONTEXT(N'RoleName'));
    DECLARE @SessionAdvisorID int=TRY_CONVERT(int,SESSION_CONTEXT(N'AdvisorId'));
    IF @AdvisorID<=0 OR @EndDate<@StartDate OR DATEDIFF(DAY,@StartDate,@EndDate)>366 THROW 52142, 'Advisor activity parameters are invalid.', 1;
    IF @RoleName='AdvisorUser' AND @AdvisorID<>@SessionAdvisorID THROW 52141, 'Advisor activity is outside the authorized scope.', 1;
    SELECT AdvisorID,AdvisorName,ActivityMonth,TransactionTypeCode,TransactionCount,GrossAmount
    FROM reporting.vw_AdvisorMonthlyActivity
    WHERE AdvisorID=@AdvisorID AND ActivityMonth>=DATEFROMPARTS(YEAR(@StartDate),MONTH(@StartDate),1) AND ActivityMonth<=@EndDate
    ORDER BY ActivityMonth,TransactionTypeCode;
END;
GO

CREATE OR ALTER PROCEDURE audit.usp_GetAuditEvents
    @Page int=1,
    @PageSize int=50,
    @ActorID nvarchar(254)=NULL,
    @ActionName varchar(80)=NULL,
    @EntityType varchar(80)=NULL,
    @FromUtc datetime2(3)=NULL,
    @ToUtc datetime2(3)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF TRY_CONVERT(varchar(40),SESSION_CONTEXT(N'RoleName')) NOT IN ('DatabaseAdministrator','ReadOnlyAuditor') THROW 52150, 'The current role cannot read audit evidence.', 1;
    IF @Page<1 OR @PageSize NOT BETWEEN 1 AND 100 THROW 52151, 'Invalid pagination values.', 1;

    SELECT AuditEventID,EventTime,ActorID,ActionName,EntityType,EntityID,Outcome,CorrelationID,MetadataJson,COUNT_BIG(*) OVER() AS TotalCount
    FROM audit.AuditEvent
    WHERE (@ActorID IS NULL OR ActorID=@ActorID)
      AND (@ActionName IS NULL OR ActionName=@ActionName)
      AND (@EntityType IS NULL OR EntityType=@EntityType)
      AND (@FromUtc IS NULL OR EventTime>=@FromUtc)
      AND (@ToUtc IS NULL OR EventTime<=@ToUtc)
    ORDER BY EventTime DESC,AuditEventID DESC
    OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

PRINT N'Application procedures created or confirmed.';
GO
