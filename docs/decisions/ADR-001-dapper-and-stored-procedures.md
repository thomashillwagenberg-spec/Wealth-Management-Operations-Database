# ADR-001: Dapper and stored procedures for the wealth database

**Status:** Accepted

## Decision

Use `Microsoft.Data.SqlClient` and Dapper for the principal wealth-management database. Preserve hand-written views, functions, and stored procedures. Do not generate Entity Framework migrations for the existing model.

## Consequences

SQL remains visible and reviewable. Permissions can target procedures and views. Developers must maintain explicit mappings and schema change scripts. Integration testing against SQL Server or Azure SQL is mandatory.
