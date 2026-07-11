/*
  Application-mode SQL Server validation suite.
  Execute after database/local/run_application_extensions.sql and
  database/local/25_create_local_application_login.sql.
  These are engine tests. Their presence is not evidence that they passed.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
SET XACT_ABORT OFF;
GO

CREATE TABLE #Results
(
    TestName nvarchar(180) NOT NULL,
    TestStatus varchar(12) NOT NULL,
    Evidence nvarchar(1000) NOT NULL
);

/* 1. Required objects */
INSERT #Results
SELECT N'Application objects',
       CASE WHEN OBJECT_ID(N'security.AppUser',N'U') IS NOT NULL
              AND OBJECT_ID(N'trading.usp_SubmitTrade',N'P') IS NOT NULL
              AND OBJECT_ID(N'audit.AuditEvent',N'U') IS NOT NULL
              AND EXISTS(SELECT 1 FROM sys.security_policies WHERE name=N'WealthManagementRowIsolation' AND is_enabled=1)
            THEN 'PASS' ELSE 'FAIL' END,
       N'Identity, trade, audit, and enabled row-security objects checked.';

/* 2. Original seed counts remain intact */
DECLARE @ClientCount int=(SELECT COUNT(*) FROM core.Client);
DECLARE @HoldingCount int=(SELECT COUNT(*) FROM trading.CurrentHolding);
INSERT #Results VALUES
(N'Original seed counts', CASE WHEN @ClientCount=30 AND @HoldingCount=300 THEN 'PASS' ELSE 'FAIL' END,
 CONCAT(N'Clients=',@ClientCount,N'; holdings=',@HoldingCount,N'.'));

/* 3. Holdings reconcile to posted buys and sells */
DECLARE @HoldingMismatchCount int;
WITH TransactionQuantity AS
(
    SELECT atx.AccountID,atx.SecurityID,
           SUM(CASE tt.TransactionTypeCode WHEN 'BUY' THEN atx.Quantity WHEN 'SELL' THEN -atx.Quantity ELSE 0 END) AS Quantity
    FROM trading.AccountTransaction atx
    JOIN trading.TransactionType tt ON tt.TransactionTypeID=atx.TransactionTypeID
    WHERE atx.SecurityID IS NOT NULL
    GROUP BY atx.AccountID,atx.SecurityID
)
SELECT @HoldingMismatchCount=COUNT(*)
FROM TransactionQuantity tq
FULL JOIN trading.CurrentHolding h ON h.AccountID=tq.AccountID AND h.SecurityID=tq.SecurityID
WHERE ABS(COALESCE(tq.Quantity,0)-COALESCE(h.Quantity,0))>0.000001;
INSERT #Results VALUES
(N'Holdings reconciliation',CASE WHEN @HoldingMismatchCount=0 THEN 'PASS' ELSE 'FAIL' END,
 CONCAT(N'Mismatched account/security positions=',@HoldingMismatchCount,N'.'));

/* 4-5. Advisor isolation */
EXEC security.usp_SetExecutionContext @UserPrincipalName=N'advisor1@local.test', @CorrelationID='11111111-1111-1111-1111-111111111111';
DECLARE @AdvisorClientCount int=(SELECT COUNT(*) FROM core.Client);
DECLARE @UnrelatedClientVisible bit=CASE WHEN EXISTS(SELECT 1 FROM core.Client WHERE AdvisorID<>1) THEN 1 ELSE 0 END;
INSERT #Results VALUES
(N'Advisor row isolation',CASE WHEN @AdvisorClientCount>0 AND @AdvisorClientCount<30 THEN 'PASS' ELSE 'FAIL' END,
 CONCAT(N'Advisor-visible clients=',@AdvisorClientCount,N'.'));
INSERT #Results VALUES
(N'Advisor unrelated-client denial',CASE WHEN @UnrelatedClientVisible=0 THEN 'PASS' ELSE 'FAIL' END,
 N'RLS must hide clients assigned to other advisors.');

DECLARE @OwnAdvisorAllowed bit,@OtherAdvisorAllowed bit;
DECLARE @AdvisorAccessResult TABLE(IsAllowed bit);
INSERT @AdvisorAccessResult EXEC security.usp_CanAccessAdvisor @AdvisorID=1;
SELECT @OwnAdvisorAllowed=IsAllowed FROM @AdvisorAccessResult;
DELETE FROM @AdvisorAccessResult;
INSERT @AdvisorAccessResult EXEC security.usp_CanAccessAdvisor @AdvisorID=2;
SELECT @OtherAdvisorAllowed=IsAllowed FROM @AdvisorAccessResult;
INSERT #Results VALUES
(N'Advisor object-level activity scope',CASE WHEN @OwnAdvisorAllowed=1 AND COALESCE(@OtherAdvisorAllowed,0)=0 THEN 'PASS' ELSE 'FAIL' END,
 N'Advisor 1 can request advisor 1 activity but cannot request advisor 2 activity.');

/* 6. Physical application principal cannot query raw client PII */
DECLARE @RawClientDenied bit=0;
BEGIN TRY
    EXECUTE AS USER=N'wm_application';
    SELECT TOP(1) ClientID FROM core.Client;
    REVERT;
END TRY
BEGIN CATCH
    IF USER_NAME()=N'wm_application' REVERT;
    SET @RawClientDenied=1;
END CATCH;
INSERT #Results VALUES
(N'Application raw-client denial',CASE WHEN @RawClientDenied=1 THEN 'PASS' ELSE 'FAIL' END,
 N'The application principal must use curated views and procedures, not raw core.Client access.');

/* 7. Curated advisor reporting remains available */
DECLARE @CuratedViewAllowed bit=0;
BEGIN TRY
    EXECUTE AS USER=N'wm_application';
    IF EXISTS(SELECT 1 FROM reporting.vw_ClientPortfolioSummary) SET @CuratedViewAllowed=1;
    REVERT;
END TRY
BEGIN CATCH
    IF USER_NAME()=N'wm_application' REVERT;
END CATCH;
INSERT #Results VALUES
(N'Curated reporting access',CASE WHEN @CuratedViewAllowed=1 THEN 'PASS' ELSE 'FAIL' END,
 N'The least-privilege application principal can read an RLS-filtered reporting view.');

/* 8. Oversell prevention */
DECLARE @OversellRejected bit=0;
BEGIN TRY
    EXEC trading.usp_SubmitTrade
        @IdempotencyKey='validation-oversell-0001',
        @RequestHash='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        @AccountID=1,@TransactionTypeCode='SELL',@SecurityID=1,
        @TradeDate='2026-07-10',@SettlementDate='2026-07-11',
        @Quantity=999999,@Price=100,@FeeAmount=0,
        @ExternalReference='VALID-OVERSELL-APP',@Notes=N'Expected rejection';
END TRY
BEGIN CATCH
    SET @OversellRejected=1;
END CATCH;
INSERT #Results VALUES
(N'Oversell rejection',CASE WHEN @OversellRejected=1 THEN 'PASS' ELSE 'FAIL' END,
 N'An excessive fictional sell must be rejected without changing holdings.');

/* 9. Idempotent replay returns the original transaction */
DECLARE @ReplaySucceeded bit=0,@FirstTransactionID bigint,@ReplayTransactionID bigint,@WasReplay bit,@FirstCorrelationID uniqueidentifier,@ReplayCorrelationID uniqueidentifier;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @FirstResult TABLE(TransactionID bigint,CorrelationID uniqueidentifier,WasReplay bit,ResultMessage nvarchar(250));
    DECLARE @ReplayResult TABLE(TransactionID bigint,CorrelationID uniqueidentifier,WasReplay bit,ResultMessage nvarchar(250));
    INSERT @FirstResult EXEC trading.usp_SubmitTrade
        @IdempotencyKey='validation-replay-00001',@RequestHash='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
        @AccountID=1,@TransactionTypeCode='BUY',@SecurityID=1,@TradeDate='2026-07-10',@SettlementDate='2026-07-11',
        @Quantity=0.010000,@Price=100,@FeeAmount=0,@ExternalReference='VALID-REPLAY-APP',@Notes=N'Rollback validation';
    INSERT @ReplayResult EXEC trading.usp_SubmitTrade
        @IdempotencyKey='validation-replay-00001',@RequestHash='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
        @AccountID=1,@TransactionTypeCode='BUY',@SecurityID=1,@TradeDate='2026-07-10',@SettlementDate='2026-07-11',
        @Quantity=0.010000,@Price=100,@FeeAmount=0,@ExternalReference='VALID-REPLAY-APP',@Notes=N'Rollback validation';
    SELECT @FirstTransactionID=TransactionID,@FirstCorrelationID=CorrelationID FROM @FirstResult;
    SELECT @ReplayTransactionID=TransactionID,@ReplayCorrelationID=CorrelationID,@WasReplay=WasReplay FROM @ReplayResult;
    SET @ReplaySucceeded=CASE WHEN @FirstTransactionID=@ReplayTransactionID AND @FirstCorrelationID=@ReplayCorrelationID AND @WasReplay=1 THEN 1 ELSE 0 END;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
END CATCH;
INSERT #Results VALUES
(N'Idempotent trade replay',CASE WHEN @ReplaySucceeded=1 THEN 'PASS' ELSE 'FAIL' END,
 N'The same key and request hash must return the original transaction and original correlation identifier rather than posting twice.');

/* 10. Duplicate external references are rejected and the test transaction is rolled back */
DECLARE @DuplicateRejected bit=0;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC trading.usp_SubmitTrade
        @IdempotencyKey='validation-duplicate-001',@RequestHash='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
        @AccountID=1,@TransactionTypeCode='BUY',@SecurityID=1,@TradeDate='2026-07-10',@SettlementDate='2026-07-11',
        @Quantity=0.010000,@Price=100,@FeeAmount=0,@ExternalReference='VALID-DUPLICATE-APP',@Notes=N'Rollback validation';
    EXEC trading.usp_SubmitTrade
        @IdempotencyKey='validation-duplicate-002',@RequestHash='DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD',
        @AccountID=1,@TransactionTypeCode='BUY',@SecurityID=1,@TradeDate='2026-07-10',@SettlementDate='2026-07-11',
        @Quantity=0.010000,@Price=100,@FeeAmount=0,@ExternalReference='VALID-DUPLICATE-APP',@Notes=N'Expected rejection';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    SET @DuplicateRejected=1;
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
END CATCH;
INSERT #Results VALUES
(N'Duplicate transaction rejection',CASE WHEN @DuplicateRejected=1 THEN 'PASS' ELSE 'FAIL' END,
 N'A second fictional transaction with the same external reference must be rejected.');

/* 11. Trade rollback leaves no transaction behind */
DECLARE @RollbackReference varchar(30)='VALID-ROLLBACK-APP';
BEGIN TRANSACTION;
EXEC trading.usp_SubmitTrade
    @IdempotencyKey='validation-rollback-0001',@RequestHash='EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE',
    @AccountID=1,@TransactionTypeCode='BUY',@SecurityID=1,@TradeDate='2026-07-10',@SettlementDate='2026-07-11',
    @Quantity=0.010000,@Price=100,@FeeAmount=0,@ExternalReference=@RollbackReference,@Notes=N'Rollback validation';
ROLLBACK TRANSACTION;
DECLARE @RollbackPersisted bit=CASE WHEN EXISTS(SELECT 1 FROM trading.AccountTransaction WHERE ExternalReference=@RollbackReference) THEN 1 ELSE 0 END;
INSERT #Results VALUES
(N'Transaction rollback',CASE WHEN @RollbackPersisted=0 THEN 'PASS' ELSE 'FAIL' END,
 N'A caller-controlled outer rollback must remove the transaction, holding change, idempotency record, and audit event.');

/* 12. Posted transactions cannot be changed */
DECLARE @MutationRejected bit=0;
BEGIN TRY
    UPDATE trading.AccountTransaction SET Notes=N'Unauthorized mutation' WHERE TransactionID=1;
END TRY
BEGIN CATCH
    SET @MutationRejected=1;
END CATCH;
INSERT #Results VALUES
(N'Posted transaction immutability',CASE WHEN @MutationRejected=1 THEN 'PASS' ELSE 'FAIL' END,
 N'UPDATE on a posted financial transaction must be rejected.');

/* 13-14. Compliance role can update through procedure, but cannot delete history */
EXEC security.usp_SetExecutionContext @UserPrincipalName=N'compliance@local.test', @CorrelationID='22222222-2222-2222-2222-222222222222';
DECLARE @AlertID bigint,@RowVersion binary(8),@ComplianceUpdateWorked bit=0,@StaleVersionRejected bit=0;
SELECT TOP(1) @AlertID=ComplianceAlertID,@RowVersion=RowVersion FROM compliance.ComplianceAlert ORDER BY ComplianceAlertID;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC compliance.usp_UpdateAlertStatusSecure @ComplianceAlertID=@AlertID,@NewStatus='IN_REVIEW',@ResolutionNote=N'Validation only',@ExpectedRowVersion=@RowVersion;
    SET @ComplianceUpdateWorked=1;
    BEGIN TRY
        EXEC compliance.usp_UpdateAlertStatusSecure @ComplianceAlertID=@AlertID,@NewStatus='RESOLVED',@ResolutionNote=N'Stale row version',@ExpectedRowVersion=@RowVersion;
    END TRY
    BEGIN CATCH
        SET @StaleVersionRejected=1;
    END CATCH;
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
END CATCH;
INSERT #Results VALUES
(N'Compliance controlled update',CASE WHEN @ComplianceUpdateWorked=1 THEN 'PASS' ELSE 'FAIL' END,
 N'The compliance role can update alert status through the controlled optimistic-concurrency procedure.');
INSERT #Results VALUES
(N'Compliance concurrency conflict',CASE WHEN @StaleVersionRejected=1 THEN 'PASS' ELSE 'FAIL' END,
 N'A stale rowversion must be rejected.');

DECLARE @ComplianceDeleteRejected bit=0;
BEGIN TRY
    EXECUTE AS USER=N'wm_application';
    DELETE FROM compliance.ComplianceAlert WHERE ComplianceAlertID=@AlertID;
    REVERT;
END TRY
BEGIN CATCH
    IF USER_NAME()=N'wm_application' REVERT;
    SET @ComplianceDeleteRejected=1;
END CATCH;
INSERT #Results VALUES
(N'Compliance history deletion denied',CASE WHEN @ComplianceDeleteRejected=1 THEN 'PASS' ELSE 'FAIL' END,
 N'The application principal cannot directly delete compliance history.');

/* 15. Auditor is read-only */
EXEC security.usp_SetExecutionContext @UserPrincipalName=N'auditor@local.test', @CorrelationID='33333333-3333-3333-3333-333333333333';
DECLARE @AuditorWriteRejected bit=0;
BEGIN TRY
    EXEC compliance.usp_UpdateAlertStatusSecure @ComplianceAlertID=@AlertID,@NewStatus='RESOLVED',@ResolutionNote=NULL,@ExpectedRowVersion=@RowVersion;
END TRY
BEGIN CATCH
    SET @AuditorWriteRejected=1;
END CATCH;
INSERT #Results VALUES
(N'Auditor read-only enforcement',CASE WHEN @AuditorWriteRejected=1 THEN 'PASS' ELSE 'FAIL' END,
 N'The auditor application role cannot invoke a compliance mutation.');

/* 16-17. Audit events are created and append-only */
EXEC security.usp_SetExecutionContext @UserPrincipalName=N'admin@local.test', @CorrelationID='44444444-4444-4444-4444-444444444444';
DECLARE @AuditBefore bigint=(SELECT COUNT_BIG(*) FROM audit.AuditEvent),@AuditAfter bigint;
EXEC audit.usp_AppendAuditEvent @ActorID=N'validation',@ActionName='VALIDATE_AUDIT',@EntityType='Test',@EntityID=N'1',@Outcome='SUCCESS',@CorrelationID='44444444-4444-4444-4444-444444444444',@MetadataJson=N'{"synthetic":true}';
SET @AuditAfter=(SELECT COUNT_BIG(*) FROM audit.AuditEvent);
INSERT #Results VALUES
(N'Audit-event creation',CASE WHEN @AuditAfter=@AuditBefore+1 THEN 'PASS' ELSE 'FAIL' END,
 CONCAT(N'Before=',@AuditBefore,N'; after=',@AuditAfter,N'.'));

DECLARE @AuditUpdatesRejected bit=0;
BEGIN TRY
    UPDATE audit.AuditEvent SET Outcome='FAILED' WHERE CorrelationID='44444444-4444-4444-4444-444444444444';
END TRY
BEGIN CATCH
    SET @AuditUpdatesRejected=1;
END CATCH;
INSERT #Results VALUES
(N'Append-only audit',CASE WHEN @AuditUpdatesRejected=1 THEN 'PASS' ELSE 'FAIL' END,
 N'Audit UPDATE must be rejected by the append-only trigger.');

/* 18. Hash-chain continuity */
DECLARE @HashBreaks int;
WITH Events AS
(
    SELECT AuditEventID,PreviousHash,LAG(EventHash) OVER(ORDER BY AuditEventID) AS ExpectedPreviousHash
    FROM audit.AuditEvent
)
SELECT @HashBreaks=COUNT(*) FROM Events
WHERE (ExpectedPreviousHash IS NULL AND PreviousHash IS NOT NULL)
   OR (ExpectedPreviousHash IS NOT NULL AND (PreviousHash IS NULL OR PreviousHash<>ExpectedPreviousHash));
INSERT #Results VALUES
(N'Audit hash-chain continuity',CASE WHEN @HashBreaks=0 THEN 'PASS' ELSE 'FAIL' END,
 CONCAT(N'Broken links=',@HashBreaks,N'.'));

SELECT TestName,TestStatus,Evidence FROM #Results ORDER BY TestName;
IF EXISTS(SELECT 1 FROM #Results WHERE TestStatus='FAIL')
    THROW 52200,'Application validation failed.',1;
GO
