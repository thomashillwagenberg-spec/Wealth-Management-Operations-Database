# Setup guide

## 1. Confirm the computer can run the tools

Use a supported 64-bit Windows version. Check Microsoft’s current SSMS system requirements before installing. At the July 11, 2026 verification, Microsoft listed an x64 processor, at least 4 GB of RAM, and 4 GB to 50 GB of available disk space depending on selected components. More memory and SSD storage improve the experience.

Official requirements:  
https://learn.microsoft.com/en-us/ssms/system-requirements

## 2. Install SQL Server Developer Edition

1. Open the official SQL Server downloads page:  
   https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2. Select SQL Server 2025 Developer.
3. Choose a basic installation for the simplest local setup, or custom installation to choose features and paths.
4. Accept the license terms.
5. Record the instance name. A default instance is commonly reached with `localhost`; a named instance uses a name such as `localhost\SQLEXPRESS`.
6. Confirm that Database Engine Services is installed.
7. For a student laptop, Windows authentication is the simplest local option.
8. Do not expose the local SQL Server instance to the public internet.

Developer Edition is licensed for non-production development and testing. Do not deploy it as a production database.

## 3. Install SSMS 22

1. Open the official installation page:  
   https://learn.microsoft.com/en-us/ssms/install/install
2. Download the SSMS 22 installer.
3. Run `vs_SSMS.exe`.
4. Allow the Visual Studio Installer to open.
5. Select SQL Server Management Studio and install it.
6. Restart if the installer requests it.
7. Open SSMS.

At the verification date, SSMS 22 is installed through the Visual Studio Installer rather than a standalone MSI.

## 4. Connect to the Database Engine

1. In SSMS, select **Database Engine**.
2. Try `localhost` as the server name for a default local instance.
3. For a named instance, use `localhost\InstanceName`.
4. Select Windows Authentication unless you intentionally configured another method.
5. Select **Connect**.
6. Run:

```sql
SELECT
    @@SERVERNAME AS ServerName,
    @@VERSION AS SqlServerVersion,
    ORIGINAL_LOGIN() AS LoginName;
```

Save a screenshot of the result only if it does not expose sensitive machine information you do not want public.

## 5. Extract and open the project

1. Extract `Wealth-Management-Operations-Database.zip`.
2. Keep the folder structure unchanged.
3. In SSMS, open the `sql` folder.
4. Choose either the numbered-script method or SQLCMD method.
5. Read the warning in `00_reset_database.sql`.

## 6. Build with numbered scripts

Run scripts `00` through `11`, then `13`, in order. Watch the **Messages** tab for success statements and the **Results** tab for validation output.

Do not run `00_reset_database.sql` against any database that contains information you need. It is intentionally destructive for this named training database.

## 7. Build with SQLCMD mode

1. Open `sql/run_all.sql` from inside the `sql` folder.
2. Select **Query > SQLCMD Mode**.
3. Run the script.
4. If an `:r` include cannot be found, confirm the working folder and use the numbered method instead.

## 8. Verify the database

In Object Explorer:

1. Refresh **Databases**.
2. Expand `WealthManagementOperations`.
3. Expand **Tables** and confirm the six schemas are visible.
4. Expand **Views**, **Programmability**, and **Security**.
5. Run `sql/13_validation_tests.sql`.
6. Do not describe the project as successfully executed until the validation suite has no `FAIL` rows.

## 9. Run reports and demonstration

- `12_analysis_queries.sql`: read-only business questions
- `15_master_demo.sql`: safe demonstrations that roll back teaching changes
- `10_create_indexes.sql`: includes a statistics and execution-plan exercise
- `14_backup_restore_examples.sql`: manual backup step
- `16_import_csv_examples.sql`: manual import-path step

## 10. Common connection problems

### Local server not listed

The browse list can be incomplete. Enter the known instance name directly.

### “A network-related or instance-specific error”

- Confirm SQL Server service is running.
- Confirm the instance name.
- Use `localhost`, `.`, or `localhost\InstanceName`.
- Confirm you installed Database Engine Services, not only SSMS.

### Login failed

- Use Windows Authentication for the local setup.
- Confirm the Windows account is authorized.
- If SQL authentication was configured, never store that password in this project.

### SSL or certificate warning

A local development connection can show certificate-related options depending on the installed versions. Follow current Microsoft connection guidance. Do not weaken production certificate validation merely to copy a local tutorial setting.

## Completion check

Setup is complete when:

- SSMS connects to the Database Engine.
- `SELECT @@VERSION` returns the installed server version.
- `WealthManagementOperations` appears in Object Explorer.
- The validation script can be opened and executed.
