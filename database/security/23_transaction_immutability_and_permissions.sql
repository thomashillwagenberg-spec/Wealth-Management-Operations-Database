/*
  23_transaction_immutability_and_permissions.sql
  Purpose: Prevent silent mutation of posted transactions and grant the application only curated access.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER TRIGGER trading.trg_AccountTransaction_Immutable
ON trading.AccountTransaction
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    THROW 52160, 'Posted transactions are immutable. Record a documented reversing transaction instead.', 1;
END;
GO

IF DATABASE_PRINCIPAL_ID(N'WealthManagementApplication') IS NULL CREATE ROLE WealthManagementApplication AUTHORIZATION dbo;
GO

GRANT EXECUTE ON OBJECT::security.usp_SetExecutionContext TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::security.usp_CanAccessClient TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::security.usp_CanAccessAccount TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::security.usp_CanAccessAdvisor TO WealthManagementApplication;
GRANT SELECT ON OBJECT::reporting.vw_ClientPortfolioSummary TO WealthManagementApplication;
GRANT SELECT ON OBJECT::reporting.vw_AccountPortfolioValue TO WealthManagementApplication;
GRANT SELECT ON OBJECT::reporting.vw_PortfolioAllocation TO WealthManagementApplication;
GRANT SELECT ON OBJECT::reporting.vw_RiskAlignment TO WealthManagementApplication;
GRANT SELECT ON OBJECT::reporting.vw_ComplianceDashboard TO WealthManagementApplication;
GRANT SELECT ON OBJECT::reporting.vw_AdvisorMonthlyActivity TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::reporting.usp_GetConcentration TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::reporting.usp_GetAdvisorActivitySecure TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::trading.usp_SubmitTrade TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::compliance.usp_ListAlerts TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::compliance.usp_UpdateAlertStatusSecure TO WealthManagementApplication;
GRANT EXECUTE ON OBJECT::audit.usp_GetAuditEvents TO WealthManagementApplication;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core TO WealthManagementApplication;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::market TO WealthManagementApplication;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::trading TO WealthManagementApplication;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::compliance TO WealthManagementApplication;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::audit TO WealthManagementApplication;
GO

PRINT N'Application permissions and immutable transaction control created or confirmed.';
GO
