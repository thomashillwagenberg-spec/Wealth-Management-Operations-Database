
/*
  01_create_database.sql
  Purpose: Create the local SQL Server database.
  Database context: master.
*/
USE master;
GO
SET NOCOUNT ON;
GO

IF DB_ID(N'WealthManagementOperations') IS NULL
BEGIN
    CREATE DATABASE WealthManagementOperations;
    PRINT N'Created WealthManagementOperations database.';
END
ELSE
BEGIN
    PRINT N'WealthManagementOperations already exists; no database was created.';
END;
GO

ALTER DATABASE WealthManagementOperations SET RECOVERY SIMPLE;
GO
PRINT N'Database recovery model set to SIMPLE for this local educational project.';
GO
