# Wealth Management Operations Database

**Author:** Thomas Wagenberg  
**Platform:** Microsoft SQL Server and SQL Server Management Studio  
**Status:** Portfolio build with completed static and logical consistency review. Local SQL Server execution remains required.  
**Data:** 100% fictional and synthetic.

## Project summary

This repository contains a complete SQL Server learning project for a fictional wealth-management firm. It organizes clients, advisors, risk profiles, investment accounts, securities, prices, transactions, current holdings, compliance reviews, alerts, and audit activity.

The project is designed to be rebuilt from a clean SQL Server environment, tested in SQL Server Management Studio (SSMS), discussed in interviews, and presented on GitHub or LinkedIn without exposing real client information.

## Business problem

A wealth-management operation needs reliable data for portfolio reporting, risk-alignment checks, transaction review, compliance work, access control, and audit support. Storing this information in disconnected spreadsheets makes validation, security, and repeatable reporting difficult.

This project demonstrates how a relational database can create a controlled source of data for those workflows.

## Skills demonstrated

- SQL Server and SSMS setup
- Relational design and normalization
- Databases, schemas, tables, keys, and relationships
- `INSERT`, `UPDATE`, `DELETE`, and `SELECT`
- Joins, aggregation, subqueries, CTEs, and window functions
- Views, user-defined functions, stored procedures, and triggers
- Transactions, `COMMIT`, `ROLLBACK`, and `TRY...CATCH`
- CSV staging and validation
- Indexes, statistics output, and execution-plan review
- Users, roles, `GRANT`, `DENY`, and `REVOKE`
- Backup preparation, verification, and restore planning
- Azure SQL deployment concepts
- Formal validation and audit logging

## Technology stack

- SQL Server 2025 Developer Edition, or another currently supported SQL Server edition
- SQL Server Management Studio 22
- Transact-SQL
- CSV
- Markdown
- Git and GitHub

Microsoft describes SQL Server 2025 Developer as a free edition for non-production development and testing. Microsoft’s current SSMS installation documentation provides the SSMS 22 installer and states that SSMS 22 works with SQL Server 2014 and later. Recheck the official links in [source-verification.md](source-verification.md) before installing because product requirements can change.

## Database architecture

Six schemas separate responsibilities:

| Schema | Purpose |
|---|---|
| `core` | Advisors, clients, risk profiles, and accounts |
| `market` | Asset classes, securities, and prices |
| `trading` | Transaction types, account transactions, and holdings |
| `compliance` | Reviews and alerts |
| `audit` | Activity logging |
| `reporting` | Views, functions, and reporting procedures |

The design contains 15 base tables, seven core reporting views plus one security view, three functions, five stored procedures, one trigger, and seven targeted nonclustered indexes.

See [database-design.md](database-design.md) and [data-dictionary.md](data-dictionary.md).

<!-- AFTER VERIFIED EXECUTION: Insert screenshots/01-object-explorer.png here. -->
<!-- AFTER VERIFIED EXECUTION: Insert screenshots/02-relationship-design.png here. -->

## Synthetic data included

| Entity | Expected rows |
|---|---:|
| Advisors | 5 |
| Clients | 30 |
| Investment accounts | 50 |
| Securities | 25 |
| Security prices | 175 |
| Transactions | 403 |
| Current holdings | 300 |
| Compliance reviews | 40 |
| Compliance alerts | 25 |

The holdings quantities are derived from cumulative synthetic purchases minus sales. Average cost uses a clearly documented weighted-average purchase-cost method. Cash balances, taxes, accrued income, lot-level accounting, corporate actions, and realized tax-lot gains are outside this educational scope.

## Installation requirements

1. A supported 64-bit Windows environment for SSMS.
2. SQL Server 2025 Developer Edition or another supported local edition.
3. SSMS 22.
4. Local administrator rights for installation.
5. Enough disk space for SQL Server, SSMS, the project, and backup files.
6. Permission to create databases and database security principals.

See [setup-guide.md](setup-guide.md) for current official links and detailed steps.

## Exact setup instructions

### Option A: Run the numbered scripts

Open SSMS, connect to the Database Engine, and run these files in order:

1. `sql/00_reset_database.sql`
2. `sql/01_create_database.sql`
3. `sql/02_create_schemas.sql`
4. `sql/03_create_tables.sql`
5. `sql/04_create_constraints.sql`
6. `sql/05_load_reference_data.sql`
7. `sql/06_load_sample_data.sql`
8. `sql/07_create_views.sql`
9. `sql/08_create_functions.sql`
10. `sql/09_create_procedures.sql`
11. `sql/10_create_indexes.sql`
12. `sql/11_security_setup.sql`
13. `sql/13_validation_tests.sql`

Then run:

14. `sql/12_analysis_queries.sql` for business reports  
15. `sql/15_master_demo.sql` for a guided demonstration  
16. `sql/14_backup_restore_examples.sql` only after reviewing the backup path and permissions  
17. `sql/16_import_csv_examples.sql` only after editing the CSV path

### Option B: SQLCMD mode

1. Open `sql/run_all.sql` from the `sql` folder.
2. In SSMS, select **Query > SQLCMD Mode**.
3. Execute the file.
4. Review the validation result set.
5. Run analysis, demo, backup, and import scripts separately.

`00_reset_database.sql` intentionally drops the training database. Do not point it at a database containing information you need.

## Example business questions

The packaged reports calculate, rather than pre-write, answers to questions such as:

- What is each client’s total portfolio value?
- Which accounts have the largest unrealized gains or losses?
- How is each account allocated by asset class?
- Which portfolios are outside their risk-profile equity ranges?
- Which positions create the greatest account concentration?
- Which accounts have not traded recently?
- Which compliance reviews are overdue?
- Which transactions exceed a selected threshold?
- What are monthly purchases and sales by advisor?
- Which clients require further review?

Run `sql/12_analysis_queries.sql`.

<!-- AFTER VERIFIED EXECUTION: Insert screenshots/03-portfolio-value-report.png here. -->
<!-- AFTER VERIFIED EXECUTION: Insert screenshots/04-risk-compliance-report.png here. -->

## Testing instructions

1. Build through `11_security_setup.sql`.
2. Run `13_validation_tests.sql`.
3. Confirm every engine-level test shows `PASS`; the backup readiness test can show `MANUAL` when no default path is exposed.
4. Correct any `FAIL` before publishing the project.
5. Capture the final validation grid for the repository only after it actually passes.

The validation suite checks objects, row counts, foreign keys, duplicate rejection, invalid data rejection, null handling, rollback, procedure output, view output, portfolio calculations, holdings reconciliation, compliance calculations, permissions, and backup-path readiness.

See [testing-checklist.md](testing-checklist.md).

<!-- AFTER ALL TESTS PASS: Insert screenshots/07-validation-results.png here. -->

## Security and privacy

The project uses only synthetic data. Five roles demonstrate least privilege:

- `DatabaseAdministrator`
- `AdvisorUser`
- `ComplianceReviewer`
- `ReportingAnalyst`
- `ReadOnlyAuditor`

Reporting access is routed through views where appropriate, emails can be masked, raw tables are denied to selected roles, and test users are created `WITHOUT LOGIN`. No password, token, private key, or connection string is included.

This is an educational security model, not a complete production wealth-management control environment. A real firm would require identity integration, encryption, key management, data classification, row-level access, monitoring, retention policies, change management, incident response, and legal/compliance review.

See [security-design.md](security-design.md).

<!-- AFTER VERIFIED EXECUTION: Insert screenshots/05-stored-procedure.png here. -->
<!-- AFTER MEASURED PLAN REVIEW: Insert screenshots/06-execution-plan.png here. -->

## Backup and restore

`sql/14_backup_restore_examples.sql` creates a copy-only full backup in the SQL Server instance’s default backup directory, uses checksums, and runs `RESTORE VERIFYONLY`. A commented restore-to-new-database template is included.

A successful backup is not enough. A recovery plan must be tested through a controlled restore. Never commit `.bak`, `.mdf`, `.ldf`, or secret-bearing configuration files to GitHub.

See [backup-and-restore.md](backup-and-restore.md).

## Azure deployment overview

For an optional student deployment, Azure SQL Database single database is the simplest managed-service starting point. The guide covers logical server creation, networking, firewall rules, authentication, SSMS connectivity, schema deployment, data loading, cost controls, security, managed backups, and differences from local SQL Server.

Local SQL Server remains the required primary environment. Azure is optional.

See [azure-deployment-guide.md](azure-deployment-guide.md).

## CSV and Excel-compatible import

The `data` folder contains UTF-8 CSV files for clients, securities, prices, transactions, and expected holdings. SQL-based staging guidance appears in `sql/16_import_csv_examples.sql`. SSMS Import Flat File Wizard instructions and Excel save-as-CSV guidance appear in [importing-data.md](importing-data.md).

## Screenshot plan

Do not fabricate screenshots. After the database actually runs, follow [screenshot-capture-guide.md](../screenshots/screenshot-capture-guide.md). The checklist covers Object Explorer, the relationship diagram, portfolio reporting, risk/compliance reporting, stored procedures, execution plans, validation, and the GitHub repository.

## Troubleshooting

| Problem | Likely cause | Action |
|---|---|---|
| Cannot connect to SQL Server | Wrong server name, service stopped, or authentication mismatch | Confirm the SQL Server service, instance name, and authentication method |
| `CREATE DATABASE` denied | Login lacks permission | Connect with a local administrator/sysadmin account |
| `:r` fails | SQLCMD mode is off or working directory is wrong | Enable **Query > SQLCMD Mode** and open `run_all.sql` from the `sql` folder |
| Object already exists | Scripts were run out of order or against a partial build | Use the reset script, then rebuild in order |
| CSV import cannot find file | SQL Server service cannot see the SSMS user’s path | Use an absolute path accessible to the SQL Server service |
| CSV columns shift | Delimiter, quote, encoding, or line-ending mismatch | Re-save as UTF-8 CSV and inspect the header |
| Backup access denied | SQL Server service account lacks folder rights | Use the instance default path or grant controlled folder access |
| A role test fails | Security script was skipped or session is not database owner/sysadmin | Run script 11, reconnect with sufficient permissions, then rerun validation |
| Index is not used | The data set is small or optimizer estimates favor a scan | Compare estimated and actual rows; do not assume every scan is bad |

## Project limitations

- Educational synthetic data only
- No production authentication or application layer
- No real market-data feed
- No cash-ledger reconciliation
- No tax-lot accounting or realized gain calculation
- No householding, beneficiary, fee-billing, or document workflow
- No row-level security by advisor
- No encryption-key demonstration
- No SQL Agent jobs, high availability, or disaster-recovery automation
- No engine execution performed in the artifact-generation environment

## Possible future improvements

- Add lot-level positions and realized gains
- Add cash balances and full double-entry reconciliation
- Add household, beneficiary, and legal-entity structures
- Implement row-level security by advisor
- Add temporal tables for selected records
- Add dynamic data masking and column encryption in a controlled lab
- Add Power BI reporting
- Add automated CI tests against a disposable SQL Server container
- Add a BACPAC or migration pipeline for Azure SQL
- Add performance tests with a larger, reproducible data set

## Portfolio and interview use

Use [linkedin-launch-package.md](linkedin-launch-package.md) only after replacing all placeholders with your verified outcomes. In an interview, explain the business problem, schema choices, validation controls, one reporting query, one transaction procedure, one permission decision, and one limitation you would address next.

## Disclaimer

All names, email addresses, account identifiers, security symbols, transactions, prices, holdings, compliance events, and dollar values in this repository are fictional and synthetic. Nothing here is investment advice, a client record, a production control system, or a representation of an actual financial institution.
