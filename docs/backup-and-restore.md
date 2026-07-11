# Backup and restore

## Why this matters

A backup is useful only when it can be restored. Microsoft’s SQL Server guidance recommends a planned backup-and-restore strategy and test restores. This project demonstrates the mechanics but does not replace an organization’s recovery policy.

Official overview:  
https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/back-up-and-restore-of-sql-server-databases

## Local project configuration

The database is set to the `SIMPLE` recovery model for a straightforward student lab. Under SIMPLE recovery, transaction-log backup chains and point-in-time recovery are not the focus.

A production recovery model should be selected from business requirements for:

- Recovery point objective
- Recovery time objective
- Data-change rate
- Backup storage
- Operational complexity
- Required point-in-time recovery

## Packaged backup script

`sql/14_backup_restore_examples.sql`:

1. Switches to `master`.
2. Reads the instance default backup path.
3. Builds a timestamped `.bak` filename.
4. Runs a copy-only full database backup.
5. Requests backup checksum and compression.
6. Runs `RESTORE VERIFYONLY`.
7. Returns the backup path.

A copy-only backup avoids changing the normal differential base. This is appropriate for an ad hoc portfolio demonstration.

## Required permissions

The SQL Server service account, not merely the person running SSMS, must be able to write to the backup directory. Use a controlled folder. Do not grant broad file-system access as a shortcut.

## Run steps

1. Read the full script.
2. Confirm the database exists.
3. Confirm the instance default backup path is appropriate.
4. If no path is returned, set `@BackupDirectory` manually.
5. Run the script as an authorized SQL Server login.
6. Confirm `BACKUP DATABASE` completes.
7. Confirm `RESTORE VERIFYONLY` completes.
8. Record the generated filename.
9. Practice a restore to `WealthManagementOperations_Restored`, not over the active database.
10. Run validation queries against the restored copy.

## What `RESTORE VERIFYONLY` does not prove

It checks that the backup set is readable and complete enough for a restore operation, but it is not a substitute for an actual test restore and application-level validation.

## Restore practice

The script contains a commented template:

1. Run `RESTORE FILELISTONLY`.
2. Record logical data and log names.
3. Choose new physical file paths.
4. Restore under a new database name with `MOVE`.
5. Confirm `ONLINE` state.
6. Run integrity and project validation checks.
7. Remove the practice database when finished.

Do not overwrite a needed database.

## Storage and repository safety

- Do not commit backup files to GitHub.
- Keep at least one protected copy separate from the database host for meaningful recovery planning.
- Encrypt and control access to backups containing real data.
- Define retention and secure deletion.
- Monitor failed backup jobs.
- Periodically restore, not merely verify.

## Azure SQL difference

Azure SQL Database creates and manages automated backups for point-in-time restore. The local `BACKUP DATABASE ... TO DISK` workflow does not transfer directly to Azure SQL Database. Microsoft documents managed full, differential, and transaction-log backups and configurable retention.

Official Azure backup overview:  
https://learn.microsoft.com/en-us/azure/azure-sql/database/automated-backups-overview

For portability or archive scenarios, review current BACPAC guidance separately. A BACPAC is not the same as a transactional backup.
