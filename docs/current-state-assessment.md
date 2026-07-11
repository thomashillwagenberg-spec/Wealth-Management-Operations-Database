# Current-state assessment

## Baseline retained

The original repository remains the canonical local SQL learning project. It contains the six original schemas, 15 base tables, synthetic seed data, reporting views, functions, procedures, indexes, roles, backup examples, CSV import examples, and the original engine validation suite.

The original Python checker was executed before expansion and reported 71 passed checks and zero failures. That result is static and logical review only. It is not SQL Server execution evidence.

## Gaps identified before expansion

- No application, API, or user interface
- No Microsoft Entra integration
- No object-level advisor isolation
- No application managed-identity database role
- No idempotency boundary for financial operations
- No safe optimistic concurrency for compliance updates
- No tamper-evident application audit stream
- No IaC, CI/CD, deployment profiles, or OIDC federation
- No application, architecture, or security tests
- No health, telemetry, incident, recovery, or cost runbooks
- Azure guidance without deployable templates

## Azure SQL compatibility boundaries

Azure SQL Database is not built with `sql/01_create_database.sql`, does not use the local backup script, and requires Azure-native backup, restore, auditing, networking, and identity. `database/azure/run_azure_schema.sql` intentionally excludes the reset, database creation, and backup scripts.

## Verification status

| Area | Status |
|---|---|
| Original Python static checker | Executed |
| Expanded repository static checker | Executed during packaging |
| .NET restore, build, and tests | Requires a .NET 10 SDK |
| Original T-SQL validation | Requires SQL Server or Azure SQL |
| Application T-SQL validation | Requires SQL Server or Azure SQL |
| Bicep compile and Azure what-if | Requires Azure CLI and Bicep |
| Azure deployment | Not performed |
| Backup restore drill | Not performed |
| Entra sign-in and managed identity | Not performed |
