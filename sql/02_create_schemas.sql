
/*
  02_create_schemas.sql
  Purpose: Separate business domains into understandable schemas.
  Database context: WealthManagementOperations.
*/
USE WealthManagementOperations;
GO
SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'core')
    EXEC(N'CREATE SCHEMA core AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'market')
    EXEC(N'CREATE SCHEMA market AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'trading')
    EXEC(N'CREATE SCHEMA trading AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'compliance')
    EXEC(N'CREATE SCHEMA compliance AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'audit')
    EXEC(N'CREATE SCHEMA audit AUTHORIZATION dbo;');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'reporting')
    EXEC(N'CREATE SCHEMA reporting AUTHORIZATION dbo;');
GO

PRINT N'Created or confirmed core, market, trading, compliance, audit, and reporting schemas.';
GO
