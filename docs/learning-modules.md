# Learning modules

These fifteen modules turn the repository into a structured course. The examples are original to this project. Run exercises only in the fictional training database.

## Module 1: SQL Server and SSMS setup

### Learning objective

Install a supported SQL Server Developer environment, install SSMS, connect safely, and confirm the server version.

### Plain-language explanation

SQL Server is the database engine. SSMS is the graphical tool used to connect, write T-SQL, inspect objects, and administer the database. Installing SSMS alone does not install a local Database Engine.

### Practical exercise

Follow `docs/setup-guide.md`, connect to the local instance, and record the engine version without publishing sensitive machine details.

### SQL example

```sql
SELECT
    @@SERVERNAME AS ServerName,
    @@VERSION AS SqlServerVersion,
    ORIGINAL_LOGIN() AS LoginName;
```

### Expected result

One row identifies the connected SQL Server instance, version, and login.

### Common mistakes

Installing only SSMS; entering the wrong instance name; using production credentials; exposing the database port publicly.

### Completion check

You can connect, open a query window, and run `SELECT @@VERSION`.

---

## Module 2: Relational database fundamentals

### Learning objective

Explain entities, rows, columns, primary keys, foreign keys, normalization, and referential integrity.

### Plain-language explanation

A relational database separates distinct business concepts into related tables. Primary keys uniquely identify rows. Foreign keys prevent child records from pointing to missing parents. Normalization reduces unnecessary repetition.

### Practical exercise

Read the relationship map and trace one client through advisor, account, transaction, holding, security, and price tables.

### SQL example

```sql
SELECT
    c.ClientCode,
    ia.AccountNumber,
    s.Symbol,
    ch.Quantity
FROM core.Client AS c
INNER JOIN core.InvestmentAccount AS ia ON ia.ClientID = c.ClientID
INNER JOIN trading.CurrentHolding AS ch ON ch.AccountID = ia.AccountID
INNER JOIN market.Security AS s ON s.SecurityID = ch.SecurityID
WHERE c.ClientID = 1;
```

### Expected result

Multiple holdings are returned for the selected fictional client without repeating the full client record in every base table.

### Common mistakes

Putting all data in one wide table; using names as keys; ignoring many-to-one relationships; duplicating classifications as free text.

### Completion check

You can describe why Client, InvestmentAccount, Security, and CurrentHolding are separate.

---

## Module 3: Database and schema creation

### Learning objective

Create a database and organize objects into business-domain schemas.

### Plain-language explanation

A database is the main container. Schemas are named namespaces inside it. They improve organization and can support permission boundaries.

### Practical exercise

Run scripts 01 and 02 after the reset script, then inspect schemas in Object Explorer.

### SQL example

```sql
CREATE DATABASE WealthManagementOperations;
GO
USE WealthManagementOperations;
GO
CREATE SCHEMA core AUTHORIZATION dbo;
GO
```

### Expected result

The database appears in Object Explorer and the `core` schema is visible.

### Common mistakes

Running against the wrong server; forgetting `USE`; choosing a name that already exists; treating schemas as separate databases.

### Completion check

You can explain the six schemas and identify the expected database context.

---

## Module 4: Table design, keys, and constraints

### Learning objective

Create typed tables and use keys, nullability, defaults, unique constraints, checks, and foreign keys to protect data quality.

### Plain-language explanation

Good table design prevents invalid data before reports depend on it. `NOT NULL` requires a value, `UNIQUE` protects business identifiers, `CHECK` limits allowed states, `DEFAULT` supplies a safe initial value, and foreign keys enforce relationships.

### Practical exercise

Run scripts 03 and 04. Inspect the constraints on `trading.AccountTransaction`.

### SQL example

```sql
ALTER TABLE trading.AccountTransaction
ADD CONSTRAINT CK_AccountTransaction_SecurityFields
CHECK
(
    (SecurityID IS NULL AND Quantity IS NULL AND Price IS NULL)
    OR
    (SecurityID IS NOT NULL AND Quantity > 0 AND Price > 0)
);
```

### Expected result

A security transaction cannot store a missing or nonpositive quantity or price.

### Common mistakes

Using `float` for money; allowing invalid statuses; creating foreign keys after bad data exists; disabling constraints to force imports.

### Completion check

You can name one constraint that protects each of client, account, transaction, review, and alert data.

---

## Module 5: Loading and modifying data

### Learning objective

Use `INSERT`, `UPDATE`, `DELETE`, CSV staging, and validation while respecting dependency order.

### Plain-language explanation

Parent/reference rows must be loaded before child rows. Changes should use explicit predicates and transactions. External files should first enter a staging area where types and business keys can be checked.

### Practical exercise

Run scripts 05 and 06. Then run the rolled-back CRUD section of script 15 and review script 16.

### SQL example

```sql
BEGIN TRANSACTION;

UPDATE core.Client
SET ModifiedAt = SYSUTCDATETIME()
WHERE ClientID = 1;

ROLLBACK TRANSACTION;
```

### Expected result

The update occurs inside the transaction and is removed by `ROLLBACK`.

### Common mistakes

Running `UPDATE` or `DELETE` without `WHERE`; importing directly to trusted tables; loading child rows first; ignoring row-count reconciliation.

### Completion check

You can identify the load order and prove that the CRUD demo leaves no permanent row.

---

## Module 6: Writing core SQL queries

### Learning objective

Filter, sort, join, group, and summarize data with readable SQL.

### Plain-language explanation

Core queries use `SELECT` to choose columns, `WHERE` to filter rows, joins to connect tables, `GROUP BY` to form groups, `HAVING` to filter groups, and `ORDER BY` to sort output.

### Practical exercise

Run the client-value and advisor-rollup queries in script 12.

### SQL example

```sql
SELECT
    a.AdvisorCode,
    COUNT(DISTINCT ia.AccountID) AS AccountCount
FROM core.Advisor AS a
INNER JOIN core.InvestmentAccount AS ia
    ON ia.AdvisorID = a.AdvisorID
GROUP BY a.AdvisorCode
HAVING COUNT(DISTINCT ia.AccountID) >= 1
ORDER BY AccountCount DESC;
```

### Expected result

One row per advisor with at least one account, sorted by account count.

### Common mistakes

Using an inner join when missing rows should remain; selecting nonaggregated columns not in `GROUP BY`; relying on unstated sort order.

### Completion check

You can explain the difference between `WHERE` and `HAVING`.

---

## Module 7: Advanced querying and reporting

### Learning objective

Use CASE expressions, date/string functions, subqueries, CTEs, and window functions for financial and control analysis.

### Plain-language explanation

CTEs break complex logic into named steps. Window functions calculate ranks and totals without collapsing detail rows. Subqueries answer related questions. `CASE` turns rules into readable classifications.

### Practical exercise

Run the concentration and review-priority queries in script 12, then explain each CTE.

### SQL example

```sql
WITH RankedAccounts AS
(
    SELECT
        AccountNumber,
        PortfolioValue,
        DENSE_RANK() OVER (ORDER BY PortfolioValue DESC) AS ValueRank
    FROM reporting.vw_AccountPortfolioValue
)
SELECT *
FROM RankedAccounts
WHERE ValueRank <= 5
ORDER BY ValueRank;
```

### Expected result

The five highest ranking account values are returned, with ties sharing a rank.

### Common mistakes

Confusing window functions with grouped aggregates; using a future price; hard-coding conclusions instead of calculating them.

### Completion check

You can identify the partition, ordering, and business purpose of a window function.

---

## Module 8: Views, functions, and stored procedures

### Learning objective

Choose the right reusable database object for reporting and controlled operations.

### Plain-language explanation

Views expose saved queries. Inline table-valued functions accept parameters and return relational results. Scalar functions return one value. Stored procedures can validate inputs, use temporary objects, change data, and return result sets.

### Practical exercise

Execute `reporting.usp_ClientPortfolioReport` for ClientID 1 and inspect the objects in scripts 07 through 09.

### SQL example

```sql
EXEC reporting.usp_ClientPortfolioReport
    @ClientID = 1,
    @AsOfDate = '2026-07-10';
```

### Expected result

One row per account for the fictional client, plus the calculated client total and account rank.

### Common mistakes

Putting every rule in a scalar function; granting raw tables when a view is enough; hiding side effects in procedures; omitting parameter validation.

### Completion check

You can justify why portfolio value is exposed through views/functions and trade recording through a procedure.

---

## Module 9: Transactions and error handling

### Learning objective

Use atomic transactions and `TRY...CATCH` so multi-step operations succeed or fail together.

### Plain-language explanation

A transaction groups dependent changes. `COMMIT` preserves them. `ROLLBACK` reverses them. `TRY...CATCH` handles errors and prevents half-finished operations.

### Practical exercise

Read `trading.usp_RecordTrade`, then run the rolled-back trade demonstration in script 15.

### SQL example

```sql
BEGIN TRY
    BEGIN TRANSACTION;

    -- dependent statements go here

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

### Expected result

A valid operation commits only when every step succeeds; an error leaves no partial transaction or holding update.

### Common mistakes

Forgetting to roll back in the catch block; swallowing the error; updating holdings without recording the transaction; assuming nested transactions are independent.

### Completion check

You can explain how the trade procedure prevents overselling and partial updates.

---

## Module 10: Indexes and performance

### Learning objective

Create targeted indexes and read an actual execution plan without making unsupported performance claims.

### Plain-language explanation

Indexes can reduce work for common filters, joins, and ordering, but they also consume storage and add write cost. The optimizer can correctly choose a scan for a small table. Performance claims require measured evidence.

### Practical exercise

Enable the actual plan and run the exercise at the end of script 10 with statistics IO and time enabled.

### SQL example

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT *
FROM trading.AccountTransaction
WHERE AccountID = 1
  AND TradeDate >= '2026-01-01'
ORDER BY TradeDate DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

### Expected result

SSMS displays a result set, IO/time messages, and an actual execution plan. Index selection can vary.

### Common mistakes

Assuming every scan is bad; creating duplicate indexes; measuring only elapsed time once; claiming a percentage gain from a tiny data set.

### Completion check

You can name the main operator, actual versus estimated rows, logical reads, and relevant index.

---

## Module 11: Security and access control

### Learning objective

Use roles, users, grants, denials, revocations, and curated views to demonstrate least privilege.

### Plain-language explanation

Permissions should follow job responsibilities. Roles make access easier to review. A curated reporting layer can reduce exposure to raw sensitive columns. `WITHOUT LOGIN` users make safe database-level test principals.

### Practical exercise

Run script 11 and the two role tests in script 13.

### SQL example

```sql
EXECUTE AS USER = 'demo_reporting';
SELECT TOP (5) *
FROM reporting.vw_ClientPortfolioSummary;
REVERT;
```

### Expected result

The approved view succeeds. Direct access to `core.Client` should be denied.

### Common mistakes

Giving every user `db_owner`; committing passwords; believing masking alone secures data; testing a deny without safely reverting context.

### Completion check

You can describe each role and one permission it intentionally does not have.

---

## Module 12: Backup and restoration

### Learning objective

Create a local backup, verify its readability, and plan a controlled restore to a separate database.

### Plain-language explanation

Backups protect recoverability only when permissions, storage, retention, and restore tests are addressed. `RESTORE VERIFYONLY` is useful but does not replace a real test restore.

### Practical exercise

Review and run script 14 after confirming the backup path. Restore to a new database name using the documented template.

### SQL example

```sql
BACKUP DATABASE WealthManagementOperations
TO DISK = N'C:\SQLBackups\WealthManagementOperations.bak'
WITH COPY_ONLY, CHECKSUM, COMPRESSION;

RESTORE VERIFYONLY
FROM DISK = N'C:\SQLBackups\WealthManagementOperations.bak'
WITH CHECKSUM;
```

### Expected result

The backup completes, verification completes, and a later practice restore creates a separate online database.

### Common mistakes

Writing to a folder the service cannot access; overwriting a needed database; committing the backup to GitHub; calling verification a full restore test.

### Completion check

You have recorded the backup and restore outcomes separately.

---

## Module 13: Azure SQL overview

### Learning objective

Explain how the project could move to Azure SQL Database and identify local-versus-cloud differences.

### Plain-language explanation

Azure SQL Database is a managed database service. Microsoft manages much of the platform, including automated backups, while the customer still controls data, identities, permissions, network access, and cost choices.

### Practical exercise

Read the Azure guide, price a minimal lab, and outline a deployment without creating resources unless you choose to spend money.

### SQL example

```sql
-- Run after connecting to the Azure SQL target database:
SELECT
    DB_NAME() AS DatabaseName,
    SUSER_SNAME() AS LoginIdentity,
    USER_NAME() AS DatabaseUser;
```

### Expected result

A deployment plan identifies service choice, authentication, network controls, schema deployment, data load, validation, backups, and costs.

### Common mistakes

Running the local DROP/CREATE scripts unchanged; opening broad firewall ranges; storing administrator passwords; assuming local backup commands work the same.

### Completion check

You can explain why Azure SQL single database is the recommended learning starting point.

---

## Module 14: Testing and validation

### Learning objective

Use independent checks to prove objects, data, calculations, constraints, transactions, procedures, and permissions behave as intended.

### Plain-language explanation

A query that returns data is not enough. Validation compares expected and actual results, intentionally tests rejected data, recalculates important values independently, and records manual checks.

### Practical exercise

Run script 13 and investigate every result that is not `PASS`.

### SQL example

```sql
SELECT
    TestID,
    TestName,
    ExpectedOutcome,
    ActualOutcome,
    TestStatus
FROM #ValidationResults
ORDER BY TestID;
```

### Expected result

No test shows `FAIL`. A backup-path item can require a documented manual step.

### Common mistakes

Changing expected counts to hide a failure; skipping security tests; treating static review as execution; publishing only favorable screenshots.

### Completion check

You can show the complete validation output and explain one independent calculation.

---

## Module 15: GitHub and LinkedIn presentation

### Learning objective

Package evidence clearly, protect sensitive information, and make only verified claims.

### Plain-language explanation

A strong portfolio repository lets another person understand the problem, run the build, inspect tests, and see limitations. A strong post explains the work without exaggerating expertise or production readiness.

### Practical exercise

Create a GitHub repository, upload the project, complete engine testing, capture real screenshots, and update the LinkedIn post with verified facts.

### SQL example

```sql
-- A final evidence query for the screenshot:
SELECT
    ClientCode,
    ClientName,
    TotalPortfolioValue,
    UnrealizedGainLoss
FROM reporting.vw_ClientPortfolioSummary
ORDER BY TotalPortfolioValue DESC;
```

### Expected result

The repository renders correctly, contains no secrets, and the post matches the actual test record.

### Common mistakes

Posting fabricated screenshots; exposing server details; calling the project production-ready; saying performance improved without measurements; leaving placeholders.

### Completion check

A reviewer can clone the repository, follow the README, and understand what was and was not verified.

---
