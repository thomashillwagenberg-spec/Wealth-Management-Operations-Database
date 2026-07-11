# Database-access design

The wealth database uses Dapper and `Microsoft.Data.SqlClient`. Entity Framework migrations are intentionally not used for the existing SQL model.

Reasons:

1. The hand-written T-SQL is a central portfolio artifact.
2. Views and stored procedures express reporting, transaction, and control logic directly.
3. Dapper preserves explicit SQL, parameters, timeouts, cancellation, and result shapes.
4. Database permissions can be limited to approved views and procedures.
5. The model can be studied independently in SSMS.

Controllers and endpoint files do not create connections or execute SQL. Infrastructure repositories own database calls. Trade and compliance writes use stored procedures with transactions, idempotency or rowversion checks, and audit events.

Retry is not applied blindly. Non-idempotent financial operations require an idempotency key and database record before a caller may safely retry.
