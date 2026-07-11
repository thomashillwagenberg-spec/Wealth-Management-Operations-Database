# Optional Azure SQL deployment guide

## Recommended learning service

For this small educational project, start with **Azure SQL Database, single database**. It is a managed database service and avoids administering a full Windows or Linux server.

Use Azure SQL Managed Instance or SQL Server on an Azure virtual machine only when the project requires broader SQL Server instance compatibility. This project does not require those services for local operation.

Official quickstart:  
https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-create-quickstart

## Before spending money

- Review the current free offer, if available.
- Use the Azure pricing calculator.
- Set a budget and alerts.
- Choose the smallest practical dev/test compute and storage.
- Consider serverless auto-pause where appropriate.
- Delete unused databases, logical servers, public IP resources, and related services.
- Understand that retained backups or related resources can still affect cost.

Pricing calculator:  
https://azure.microsoft.com/en-us/pricing/calculator/

## Step 1: Create the database

1. Sign in to the Azure portal.
2. Create or select a resource group.
3. Create an Azure SQL Database.
4. Create or select a logical SQL server.
5. Name the database `WealthManagementOperations`.
6. Select a low-cost development configuration.
7. Choose an authentication method. Microsoft Entra authentication is preferred for managed identity and organizational access where available.
8. Review networking before deployment.
9. Create the resource.

## Step 2: Configure networking

Azure SQL Database blocks connections that are not allowed by network rules.

Options include:

- Private endpoint for a stronger private-network design
- Public endpoint with narrowly scoped firewall rules for a temporary lab
- “Allow Azure services” only when its broad implications are understood

For a student lab using SSMS from one computer:

1. Add only the current public client IP.
2. Do not use a broad `0.0.0.0` to `255.255.255.255` rule.
3. Remove the rule when no longer needed.
4. Expect the client IP to change on some home or campus networks.

Official firewall guidance:  
https://learn.microsoft.com/en-us/azure/azure-sql/database/firewall-configure

## Step 3: Connect through SSMS

1. Copy the fully qualified server name from Azure.
2. Open SSMS.
3. Choose **Database Engine**.
4. Enter the server name.
5. Select the configured authentication method.
6. Keep encryption enabled.
7. Confirm the server certificate options follow current Microsoft guidance.
8. Connect to the target database.

Official connection guide:  
https://learn.microsoft.com/en-us/azure/azure-sql/database/connect-query-ssms

## Step 4: Adapt the scripts

Azure SQL Database differs from local SQL Server at the instance level.

Do not run the local reset and database-creation scripts unchanged against Azure SQL Database. Instead:

- Create the Azure database through the portal, CLI, PowerShell, or supported T-SQL context.
- Connect directly to `WealthManagementOperations`.
- Run scripts `02` through `13`.
- Review any unsupported instance-level statements before execution.
- Skip local `BACKUP DATABASE ... TO DISK`.
- Create Azure users based on the chosen authentication design, not the local `WITHOUT LOGIN` demonstration alone.

The schema, table, constraint, data, view, function, procedure, index, analysis, and most validation logic are intended to be portable, but they still require actual Azure testing.

## Step 5: Load data

Options:

1. Run `05_load_reference_data.sql` and `06_load_sample_data.sql`.
2. Use SSMS import tools with careful staging and validation.
3. Use a data-tier export/import workflow where appropriate.
4. Build a controlled pipeline for larger or repeated deployments.

For this project, the direct SQL insert scripts are the simplest and most reproducible.

## Step 6: Security

- Prefer Microsoft Entra identities.
- Use separate administrators and regular users.
- Assign least-privilege database roles.
- Avoid shared administrator credentials.
- Keep secrets out of source control.
- Use encrypted connections.
- Review Defender for SQL and auditing options.
- Send audit evidence to a protected destination.
- Consider private networking for anything beyond a temporary lab.
- Classify data even when the demonstration is synthetic.

## Step 7: Backups and recovery

Azure SQL Database automatically creates service-managed backups and supports point-in-time restore within the configured retention window. At the verification date, Microsoft documented regular full, differential, and transaction-log backups managed by the service.

Official guidance:  
https://learn.microsoft.com/en-us/azure/azure-sql/database/automated-backups-overview

Review:

- Short-term retention
- Long-term retention
- Backup storage redundancy
- Point-in-time restore
- Geo-restore needs
- Recovery testing
- Cost implications

## Important local-versus-Azure differences

| Area | Local SQL Server | Azure SQL Database |
|---|---|---|
| Server administration | You manage the instance | Microsoft manages much of the platform |
| Database creation | `CREATE DATABASE` on local instance | Portal/CLI/PowerShell or supported logical-server context |
| Backups | You schedule and store them | Automated service-managed backups |
| File paths | Local data and backup paths | No direct local file-system control |
| SQL Agent | Available by edition/configuration | Not available as traditional SQL Agent in single database |
| Authentication | Windows/SQL and other configured methods | Microsoft Entra and SQL authentication options |
| Networking | Local host and firewall | Azure firewall/private endpoints |
| Cost | Local hardware and time | Metered cloud resources and storage |
| Feature surface | Full instance features | Database-scoped service with differences |

## Deployment evidence to capture

After a successful optional deployment:

- Azure database overview with account/subscription identifiers hidden
- SSMS connection showing the target database, not credentials
- Object Explorer schemas
- Validation results
- Cost configuration or budget, with sensitive details hidden
- Restore configuration summary

Never publish server administrator names, connection strings, tenant identifiers that create risk, firewall details, access tokens, or billing information.

## Completion standard

Do not claim an Azure deployment until:

- The schema was deployed.
- Data was loaded.
- Validation was run.
- Network access was restricted.
- Authentication was tested.
- Cost controls were reviewed.
- Backup/restore settings were understood.
