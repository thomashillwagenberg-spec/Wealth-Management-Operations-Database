
/*
  14_backup_restore_examples.sql
  Purpose: Create and verify a local full backup, then show a safe restore
           template without overwriting the active training database.
  Database context: master for backup/restore operations.
  Manual requirement: SQL Server service account needs write access to the
                      chosen backup directory.
  Azure note: Azure SQL Database uses managed automated backups rather than
              this local BACKUP DATABASE command.
*/
USE master;
GO
SET NOCOUNT ON;
GO

DECLARE @BackupDirectory nvarchar(4000) =
    CONVERT(nvarchar(4000), SERVERPROPERTY('InstanceDefaultBackupPath'));

-- If the property returns NULL, replace this with a directory writable by
-- the SQL Server service account, such as N'C:\SQLBackups\'.
IF @BackupDirectory IS NULL
    THROW 53000, 'No default backup path was returned. Set @BackupDirectory manually.', 1;

IF RIGHT(@BackupDirectory, 1) NOT IN (N'\', N'/')
    SET @BackupDirectory += N'\';

DECLARE @Timestamp varchar(20) =
    REPLACE(REPLACE(REPLACE(CONVERT(varchar(19), GETDATE(), 120), '-', ''), ':', ''), ' ', '_');

DECLARE @BackupFile nvarchar(4000) =
    CONCAT(@BackupDirectory, N'WealthManagementOperations_', @Timestamp, N'.bak');

BACKUP DATABASE WealthManagementOperations
TO DISK = @BackupFile
WITH
    COPY_ONLY,
    INIT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;

RESTORE VERIFYONLY
FROM DISK = @BackupFile
WITH CHECKSUM;

SELECT
    @BackupFile AS BackupFile,
    N'Backup created and RESTORE VERIFYONLY completed.' AS ResultMessage;
GO

/*
  SAFE RESTORE TEMPLATE

  Do not run this against the active project database without understanding
  the consequences. Restore to a new database name for practice.

  1. Find logical file names:
     RESTORE FILELISTONLY
     FROM DISK = N'C:\SQLBackups\WealthManagementOperations_YYYYMMDD_HHMMSS.bak';

  2. Replace the three paths below with real paths returned by your instance:

     USE master;
     GO
     RESTORE DATABASE WealthManagementOperations_Restored
     FROM DISK = N'C:\SQLBackups\WealthManagementOperations_YYYYMMDD_HHMMSS.bak'
     WITH
         MOVE N'WealthManagementOperations'
           TO N'C:\SQLData\WealthManagementOperations_Restored.mdf',
         MOVE N'WealthManagementOperations_log'
           TO N'C:\SQLData\WealthManagementOperations_Restored_log.ldf',
         RECOVERY,
         STATS = 10;
     GO

  3. Validate:
     SELECT name, state_desc
     FROM sys.databases
     WHERE name = N'WealthManagementOperations_Restored';
*/
