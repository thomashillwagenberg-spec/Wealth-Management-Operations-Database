/*
  21_identity_and_row_level_security.sql
  Purpose: Resolve application users from a server-side identity map and apply advisor row isolation.
  Security note: Azure users do not connect directly as end users. The App Service managed identity is the database caller.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE security.usp_SetExecutionContext
    @EntraObjectID uniqueidentifier = NULL,
    @UserPrincipalName nvarchar(254) = NULL,
    @CorrelationID uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ActorID nvarchar(254), @RoleName varchar(40), @AdvisorID int, @BypassRls bit;

    SELECT TOP (1)
        @ActorID = COALESCE(CONVERT(nvarchar(36), EntraObjectID), UserPrincipalName),
        @RoleName = RoleName,
        @AdvisorID = AdvisorID
    FROM security.AppUser
    WHERE IsActive = 1
      AND ((@EntraObjectID IS NOT NULL AND EntraObjectID = @EntraObjectID)
        OR (@UserPrincipalName IS NOT NULL AND UserPrincipalName = @UserPrincipalName));

    IF @ActorID IS NULL THROW 52100, 'The authenticated identity is not mapped to an active application user.', 1;
    IF @RoleName = 'AdvisorUser' AND @AdvisorID IS NULL THROW 52101, 'Advisor users require an advisor mapping.', 1;

    SET @BypassRls = CASE WHEN @RoleName IN ('DatabaseAdministrator','ComplianceReviewer','ReportingAnalyst','ReadOnlyAuditor') THEN 1 ELSE 0 END;
    EXEC sys.sp_set_session_context @key=N'ActorId', @value=@ActorID, @read_only=0;
    EXEC sys.sp_set_session_context @key=N'RoleName', @value=@RoleName, @read_only=0;
    EXEC sys.sp_set_session_context @key=N'AdvisorId', @value=@AdvisorID, @read_only=0;
    EXEC sys.sp_set_session_context @key=N'BypassRls', @value=@BypassRls, @read_only=0;
    EXEC sys.sp_set_session_context @key=N'CorrelationId', @value=@CorrelationID, @read_only=0;
END;
GO

CREATE OR ALTER FUNCTION security.fn_AdvisorAccessPredicate(@AdvisorID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS AccessAllowed
    WHERE TRY_CONVERT(bit, SESSION_CONTEXT(N'BypassRls')) = 1
       OR @AdvisorID = TRY_CONVERT(int, SESSION_CONTEXT(N'AdvisorId'))
);
GO

CREATE OR ALTER FUNCTION security.fn_ClientAccessPredicate(@ClientID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS AccessAllowed
    WHERE TRY_CONVERT(bit, SESSION_CONTEXT(N'BypassRls')) = 1
       OR EXISTS
       (
           SELECT 1
           FROM core.Client AS c
           WHERE c.ClientID = @ClientID
             AND c.AdvisorID = TRY_CONVERT(int, SESSION_CONTEXT(N'AdvisorId'))
       )
);
GO

CREATE OR ALTER FUNCTION security.fn_AccountAccessPredicate(@AccountID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS AccessAllowed
    WHERE TRY_CONVERT(bit, SESSION_CONTEXT(N'BypassRls')) = 1
       OR EXISTS
       (
           SELECT 1
           FROM core.InvestmentAccount AS ia
           WHERE ia.AccountID = @AccountID
             AND ia.AdvisorID = TRY_CONVERT(int, SESSION_CONTEXT(N'AdvisorId'))
       )
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.security_policies WHERE name = N'WealthManagementRowIsolation')
BEGIN
    CREATE SECURITY POLICY security.WealthManagementRowIsolation
        ADD FILTER PREDICATE security.fn_AdvisorAccessPredicate(AdvisorID) ON core.Client,
        ADD FILTER PREDICATE security.fn_AdvisorAccessPredicate(AdvisorID) ON core.InvestmentAccount,
        ADD FILTER PREDICATE security.fn_AccountAccessPredicate(AccountID) ON trading.AccountTransaction,
        ADD FILTER PREDICATE security.fn_AccountAccessPredicate(AccountID) ON trading.CurrentHolding,
        ADD FILTER PREDICATE security.fn_ClientAccessPredicate(ClientID) ON compliance.ComplianceReview,
        ADD FILTER PREDICATE security.fn_ClientAccessPredicate(ClientID) ON compliance.ComplianceAlert,
        ADD BLOCK PREDICATE security.fn_AdvisorAccessPredicate(AdvisorID) ON core.InvestmentAccount AFTER INSERT,
        ADD BLOCK PREDICATE security.fn_AdvisorAccessPredicate(AdvisorID) ON core.InvestmentAccount AFTER UPDATE,
        ADD BLOCK PREDICATE security.fn_AccountAccessPredicate(AccountID) ON trading.AccountTransaction AFTER INSERT,
        ADD BLOCK PREDICATE security.fn_AccountAccessPredicate(AccountID) ON trading.CurrentHolding AFTER INSERT,
        ADD BLOCK PREDICATE security.fn_AccountAccessPredicate(AccountID) ON trading.CurrentHolding AFTER UPDATE
    WITH (STATE = ON, SCHEMABINDING = ON);
END;
GO

CREATE OR ALTER PROCEDURE security.usp_CanAccessClient @ClientID int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM core.Client WHERE ClientID = @ClientID) THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER PROCEDURE security.usp_CanAccessAccount @AccountID int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM core.InvestmentAccount WHERE AccountID = @AccountID) THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER PROCEDURE security.usp_CanAccessAdvisor @AdvisorID int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @RoleName varchar(40)=TRY_CONVERT(varchar(40),SESSION_CONTEXT(N'RoleName'));
    DECLARE @SessionAdvisorID int=TRY_CONVERT(int,SESSION_CONTEXT(N'AdvisorId'));
    SELECT CONVERT(bit, CASE
        WHEN NOT EXISTS (SELECT 1 FROM core.Advisor WHERE AdvisorID=@AdvisorID) THEN 0
        WHEN @RoleName='AdvisorUser' AND @SessionAdvisorID=@AdvisorID THEN 1
        WHEN @RoleName IN ('DatabaseAdministrator','ComplianceReviewer','ReportingAnalyst','ReadOnlyAuditor') THEN 1
        ELSE 0
    END);
END;
GO

PRINT N'Identity context and row-level security created or confirmed.';
GO
