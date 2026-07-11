
/*
  11_security_setup.sql
  Purpose: Demonstrate least-privilege roles, contained database users,
           GRANT, DENY, REVOKE, and access through reporting views.
  Database context: WealthManagementOperations.
  Important: These NOLOGIN users are test principals only. No passwords or
             production credentials belong in this repository.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER VIEW reporting.vw_AdvisorClientDirectory
AS
SELECT
    c.ClientID,
    c.ClientCode,
    CONCAT(c.FirstName, N' ', c.LastName) AS ClientName,
    reporting.fn_MaskEmail(c.Email) AS MaskedEmail,
    c.StateCode,
    c.AdvisorID,
    CONCAT(a.FirstName, N' ', a.LastName) AS AdvisorName,
    c.ClientSince,
    c.IsActive
FROM core.Client AS c
INNER JOIN core.Advisor AS a ON a.AdvisorID = c.AdvisorID;
GO

/* Database roles */
IF DATABASE_PRINCIPAL_ID(N'DatabaseAdministrator') IS NULL
    CREATE ROLE DatabaseAdministrator AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'AdvisorUser') IS NULL
    CREATE ROLE AdvisorUser AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'ComplianceReviewer') IS NULL
    CREATE ROLE ComplianceReviewer AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'ReportingAnalyst') IS NULL
    CREATE ROLE ReportingAnalyst AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'ReadOnlyAuditor') IS NULL
    CREATE ROLE ReadOnlyAuditor AUTHORIZATION dbo;
GO

/* Test users without server logins */
IF DATABASE_PRINCIPAL_ID(N'demo_database_admin') IS NULL
    CREATE USER demo_database_admin WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'demo_advisor') IS NULL
    CREATE USER demo_advisor WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'demo_compliance') IS NULL
    CREATE USER demo_compliance WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'demo_reporting') IS NULL
    CREATE USER demo_reporting WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'demo_auditor') IS NULL
    CREATE USER demo_auditor WITHOUT LOGIN;
GO

/* Add members only when the membership does not already exist. */
IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS m ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'DatabaseAdministrator' AND m.name = N'demo_database_admin'
)
    ALTER ROLE DatabaseAdministrator ADD MEMBER demo_database_admin;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS m ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'AdvisorUser' AND m.name = N'demo_advisor'
)
    ALTER ROLE AdvisorUser ADD MEMBER demo_advisor;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS m ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'ComplianceReviewer' AND m.name = N'demo_compliance'
)
    ALTER ROLE ComplianceReviewer ADD MEMBER demo_compliance;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS m ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'ReportingAnalyst' AND m.name = N'demo_reporting'
)
    ALTER ROLE ReportingAnalyst ADD MEMBER demo_reporting;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS m ON m.principal_id = drm.member_principal_id
    WHERE r.name = N'ReadOnlyAuditor' AND m.name = N'demo_auditor'
)
    ALTER ROLE ReadOnlyAuditor ADD MEMBER demo_auditor;
GO

/* Database administrator */
GRANT CONTROL ON DATABASE::WealthManagementOperations TO DatabaseAdministrator;
GO

/* Advisor: curated outputs and approved procedures, not raw PII or compliance data. */
GRANT SELECT ON OBJECT::reporting.vw_AdvisorClientDirectory TO AdvisorUser;
GRANT SELECT ON OBJECT::reporting.vw_AccountPortfolioValue TO AdvisorUser;
GRANT SELECT ON OBJECT::reporting.vw_PortfolioAllocation TO AdvisorUser;
GRANT EXECUTE ON OBJECT::reporting.usp_ClientPortfolioReport TO AdvisorUser;
GRANT EXECUTE ON OBJECT::trading.usp_RecordTrade TO AdvisorUser;
REVOKE SELECT ON OBJECT::core.Client FROM AdvisorUser;
DENY SELECT ON OBJECT::core.Client TO AdvisorUser;
DENY SELECT ON SCHEMA::compliance TO AdvisorUser;
DENY SELECT ON SCHEMA::audit TO AdvisorUser;
GO

/* Compliance reviewer: compliance records plus the minimum client context. */
GRANT SELECT, INSERT, UPDATE ON SCHEMA::compliance TO ComplianceReviewer;
GRANT SELECT ON OBJECT::reporting.vw_AdvisorClientDirectory TO ComplianceReviewer;
GRANT SELECT ON OBJECT::reporting.vw_RiskAlignment TO ComplianceReviewer;
GRANT SELECT ON OBJECT::reporting.vw_ComplianceDashboard TO ComplianceReviewer;
GRANT EXECUTE ON OBJECT::compliance.usp_UpdateAlertStatus TO ComplianceReviewer;
DENY SELECT ON OBJECT::core.Client TO ComplianceReviewer;
DENY DELETE ON SCHEMA::compliance TO ComplianceReviewer;
DENY SELECT ON SCHEMA::audit TO ComplianceReviewer;
GO

/* Reporting analyst: reporting layer only, with no raw client or audit access. */
GRANT SELECT ON SCHEMA::reporting TO ReportingAnalyst;
GRANT EXECUTE ON SCHEMA::reporting TO ReportingAnalyst;
DENY SELECT ON OBJECT::core.Client TO ReportingAnalyst;
DENY SELECT ON SCHEMA::audit TO ReportingAnalyst;
DENY INSERT, UPDATE, DELETE ON SCHEMA::core TO ReportingAnalyst;
DENY INSERT, UPDATE, DELETE ON SCHEMA::market TO ReportingAnalyst;
DENY INSERT, UPDATE, DELETE ON SCHEMA::trading TO ReportingAnalyst;
DENY INSERT, UPDATE, DELETE ON SCHEMA::compliance TO ReportingAnalyst;
GO

/* Read-only auditor: broad visibility with explicit write prohibitions. */
GRANT SELECT ON SCHEMA::core TO ReadOnlyAuditor;
GRANT SELECT ON SCHEMA::market TO ReadOnlyAuditor;
GRANT SELECT ON SCHEMA::trading TO ReadOnlyAuditor;
GRANT SELECT ON SCHEMA::compliance TO ReadOnlyAuditor;
GRANT SELECT ON SCHEMA::audit TO ReadOnlyAuditor;
GRANT SELECT ON SCHEMA::reporting TO ReadOnlyAuditor;
DENY INSERT, UPDATE, DELETE ON SCHEMA::core TO ReadOnlyAuditor;
DENY INSERT, UPDATE, DELETE ON SCHEMA::market TO ReadOnlyAuditor;
DENY INSERT, UPDATE, DELETE ON SCHEMA::trading TO ReadOnlyAuditor;
DENY INSERT, UPDATE, DELETE ON SCHEMA::compliance TO ReadOnlyAuditor;
DENY INSERT, UPDATE, DELETE ON SCHEMA::audit TO ReadOnlyAuditor;
GO

PRINT N'Created five least-privilege roles, five NOLOGIN test users, and role permissions.';
GO
