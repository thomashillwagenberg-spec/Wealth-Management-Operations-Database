# Testing checklist

## Test rule

A static review cannot prove that T-SQL executes. The project is ready for engine testing, but Thomas must run the scripts in SQL Server and record the results before claiming successful execution.

## Phase 1: Installation and connection

- [ ] SQL Server version is recorded with `SELECT @@VERSION`.
- [ ] SSMS connects to the intended local instance.
- [ ] The login can create a database.
- [ ] The project is extracted with folder structure intact.
- [ ] No real client data or credentials are present.

**Expected outcome:** A query window can execute against `master`.

## Phase 2: Clean build

- [ ] Read the warning in `00_reset_database.sql`.
- [ ] Run scripts `00` through `11` in order, or use `run_all.sql` in SQLCMD mode.
- [ ] Review every Messages pane.
- [ ] Confirm no red error text.
- [ ] Refresh Object Explorer.

**Expected outcome:** `WealthManagementOperations` exists with six schemas and 15 base tables.

## Phase 3: Object inventory

Run:

```sql
USE WealthManagementOperations;

SELECT s.name AS SchemaName, o.name AS ObjectName, o.type_desc
FROM sys.objects AS o
INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE s.name IN ('core','market','trading','compliance','audit','reporting')
ORDER BY s.name, o.type_desc, o.name;
```

- [ ] 15 base tables exist.
- [ ] Reporting views exist.
- [ ] Three functions exist.
- [ ] Five stored procedures exist.
- [ ] One compliance trigger exists.
- [ ] Security roles and demo users exist.
- [ ] Target indexes exist.

**Expected outcome:** The inventory matches the README and manifest.

## Phase 4: Formal validation

Run `sql/13_validation_tests.sql`.

| Test | Expected outcome |
|---|---|
| Expected table creation | 15 of 15 tables found |
| Synthetic row counts | Exact packaged counts |
| Foreign-key integrity | Zero orphans and zero disabled/untrusted foreign keys |
| Duplicate prevention | Duplicate client code rejected |
| Invalid quantity rejection | Negative quantity rejected |
| Nullable email handling | NULL accepted inside rolled-back test |
| Rollback behavior | Original value restored |
| Stored procedure execution | At least one row for ClientID 1 |
| Reporting view output | 50 account rows and 30 client-risk rows |
| Portfolio calculation | Independent and view values agree within $0.05 |
| Holdings reconciliation | Zero mismatches |
| Compliance calculation | Dashboard and independent count agree |
| Reporting view permission | Allowed |
| Raw client-table permission | Denied |
| Backup readiness | PASS when path exists; otherwise MANUAL |

- [ ] No row shows `FAIL`.
- [ ] Any `MANUAL` item is separately completed.
- [ ] Validation screenshot is captured after success.

## Phase 5: Query review

Run `sql/12_analysis_queries.sql`.

- [ ] Client totals return.
- [ ] Gains and losses return.
- [ ] Allocation percentages are plausible and approximately total 100% per account.
- [ ] Some synthetic portfolios are flagged outside risk range.
- [ ] Concentration query returns one largest position per account.
- [ ] Inactive-account query uses current date and may change over time.
- [ ] Overdue reviews reflect the execution date.
- [ ] Threshold query respects the chosen variable.
- [ ] Advisor monthly activity returns BUY and SELL totals.
- [ ] Review queue prioritizes alerts, overdue reviews, and risk mismatch.

**Expected outcome:** Queries return calculated results without hard-coded conclusions.

## Phase 6: Procedure and transaction tests

Run `sql/15_master_demo.sql`.

- [ ] CRUD demo inserts, updates, selects, deletes, and rolls back.
- [ ] Client report procedure returns data.
- [ ] Advisor activity procedure returns data.
- [ ] Trade procedure returns a transaction ID.
- [ ] Audit row appears inside the demonstration transaction.
- [ ] Outer rollback removes the demo trade and audit row.
- [ ] Temporary review queue returns data.

**Expected outcome:** The demo completes and retains no demonstration changes.

## Phase 7: Performance exercise

1. Enable **Include Actual Execution Plan** with Ctrl+M.
2. Run the final query in `10_create_indexes.sql`.
3. Review logical reads and elapsed time.
4. Inspect estimated versus actual row counts.
5. Save the `.sqlplan` locally if useful, but review it for machine names or paths before sharing.
6. Do not claim a percentage improvement without a measured before-and-after test.

**Expected outcome:** A real execution plan is captured. Index use can vary because the data set is small.

## Phase 8: Security

- [ ] `demo_reporting` can read reporting views.
- [ ] `demo_reporting` cannot read `core.Client`.
- [ ] `demo_advisor` can read the masked directory.
- [ ] `demo_advisor` cannot read compliance or audit schemas.
- [ ] `demo_compliance` can update alerts through the procedure.
- [ ] `demo_compliance` cannot delete compliance records.
- [ ] `demo_auditor` can read but cannot modify records.
- [ ] `demo_database_admin` has intended database control.

**Expected outcome:** Least-privilege examples behave as documented.

## Phase 9: Import

- [ ] Copy a CSV to a path readable by SQL Server.
- [ ] Edit `@ClientsCsvPath`.
- [ ] Enable the dynamic execution line only after checking the path.
- [ ] Import into staging.
- [ ] Confirm conversion and invalid-row queries.
- [ ] Do not load staging rows into target tables until validation passes.

**Expected outcome:** The staging process exposes malformed rows rather than silently accepting them.

## Phase 10: Backup and restore

- [ ] Confirm the backup directory.
- [ ] Run script 14.
- [ ] Confirm backup completion.
- [ ] Confirm `RESTORE VERIFYONLY`.
- [ ] Run `RESTORE FILELISTONLY`.
- [ ] Restore to a new database name.
- [ ] Run object and row-count checks against the restored copy.
- [ ] Remove backup files from any Git commit.

**Expected outcome:** A separate restored database is online and consistent.

## Phase 11: Repository review

- [ ] README instructions match actual behavior.
- [ ] No credentials or real data.
- [ ] No generated `.bak`, `.mdf`, or `.ldf` files.
- [ ] Screenshots hide machine-sensitive information.
- [ ] GitHub description and topics are accurate.
- [ ] LinkedIn claims match completed tests.
- [ ] Repository license is present.
- [ ] File names are readable and ordered.

## Sign-off record

Fill this in only after testing:

| Item | Value |
|---|---|
| SQL Server version | |
| SSMS version | |
| Test date | |
| Computer/OS, generalized | |
| Build result | |
| Validation FAIL count | |
| Backup result | |
| Restore result | |
| Azure deployed? | Yes / No |
| Known issues | |

## Publication gate

Do not publish “fully tested,” “production-ready,” “secure,” “optimized,” “deployed to Azure,” or “backup verified” unless that exact claim has been personally demonstrated and documented.
