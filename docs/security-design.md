# Security design

## Objective

The demonstration applies least privilege by separating administration, advisor work, compliance work, reporting, and audit access. It uses roles instead of granting every permission directly to individual users.

## Roles

| Role | Intended access | Important restriction |
|---|---|---|
| `DatabaseAdministrator` | Full database control | Should be assigned to very few trusted administrators |
| `AdvisorUser` | Masked client directory, portfolio views, client report, controlled trade procedure | Denied raw client, compliance, and audit access |
| `ComplianceReviewer` | Compliance tables, masked directory, risk and dashboard views, alert-status procedure | Denied raw client and audit access; no compliance deletes |
| `ReportingAnalyst` | Reporting schema and reporting procedures | Denied raw client and audit access; denied writes |
| `ReadOnlyAuditor` | Broad read access across business and audit schemas | Explicitly denied inserts, updates, and deletes |

## Test principals

The script creates users such as `demo_reporting` `WITHOUT LOGIN`. These are contained test principals used with `EXECUTE AS USER` in the validation suite. They are not production identities and have no password.

## Why views matter

A reporting view can:

- Expose only needed columns
- Apply consistent calculations
- Mask an email address
- Avoid direct table permissions
- Reduce the chance that each analyst rebuilds business logic differently

The demonstration relies on SQL Server ownership chaining for approved views while directly denying selected base tables.

## Why raw client access is restricted

Even synthetic examples should teach the correct instinct: names, email addresses, identifiers, financial positions, and compliance records should not be broadly exposed. A real firm would classify the data and define access by job function, client assignment, legal entity, purpose, and jurisdiction.

## GRANT, DENY, and REVOKE

- `GRANT` gives a permission.
- `DENY` explicitly blocks a permission and generally overrides a grant.
- `REVOKE` removes a prior grant or deny without automatically creating the opposite permission.

The script uses all three so the learner can see the difference.

## Production controls not represented

This project does not claim production-grade security. A real deployment would also consider:

- Microsoft Entra ID or another controlled identity provider
- Multifactor authentication
- Privileged-access management
- Row-level security for advisor assignments
- Dynamic data masking only as a supplemental control
- Always Encrypted or application-layer protection for selected fields
- Transparent Data Encryption
- TLS certificate validation
- Secrets in a managed vault
- Data loss prevention and classification
- SQL auditing sent to protected storage
- Alerting and security operations
- Segregation of duties
- Access reviews and termination workflows
- Secure software delivery and change approval

## GitHub rules

Never commit:

- Passwords
- Connection strings with credentials
- Private keys
- Tokens
- `.bak`, `.mdf`, or `.ldf` files containing data
- Screenshots showing secrets, server addresses, or personal information
- Real client records

Use `.gitignore`, environment variables, managed secret stores, and repository secret scanning.

## Practical security test

After script 11:

```sql
EXECUTE AS USER = 'demo_reporting';
SELECT TOP (5) * FROM reporting.vw_ClientPortfolioSummary;
REVERT;
```

This should succeed.

```sql
EXECUTE AS USER = 'demo_reporting';
SELECT TOP (5) * FROM core.Client;
REVERT;
```

This should fail. If the second query errors before `REVERT`, run `REVERT` in a new batch or reconnect. The formal validation script handles the expected error with `TRY...CATCH`.

## Educational limit

Permissions tested inside one database do not prove an end-to-end secure application. Authentication, network design, application authorization, operating-system rights, backups, exports, and administrative access all remain part of the security boundary.
