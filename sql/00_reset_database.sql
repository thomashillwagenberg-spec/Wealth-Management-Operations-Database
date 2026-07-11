
/*
  00_reset_database.sql
  Purpose: Intentionally remove the training database for a clean rebuild.
  Database context: master.
  Warning: This deletes WealthManagementOperations and all data inside it.
*/
USE master;
GO
SET NOCOUNT ON;
GO

IF DB_ID(N'WealthManagementOperations') IS NOT NULL
BEGIN
    ALTER DATABASE WealthManagementOperations SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE WealthManagementOperations;
    PRINT N'Dropped existing WealthManagementOperations database.';
END
ELSE
BEGIN
    PRINT N'No existing WealthManagementOperations database was found.';
END;
GO
