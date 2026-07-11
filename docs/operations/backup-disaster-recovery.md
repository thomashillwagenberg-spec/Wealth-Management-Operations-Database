# Backup and disaster-recovery runbook

## Local SQL Server

Use the original backup script only after selecting a safe path. Verify the backup and perform a controlled restore into a different database. A successful backup command is not a recovery test.

## Azure SQL

The production Bicep profile requests geo-redundant backup storage, 35-day short-term retention, and long-term retention. Exact availability depends on region, tier, and current Azure features.

## Recovery workflow

1. Declare the incident and stop unsafe writes.
2. Identify the last known good point and business-approved data-loss tolerance.
3. Restore to a new database or initiate failover according to the chosen design.
4. Validate schema, row counts, reconciliations, identities, RLS, procedures, and application health.
5. Repoint the application through controlled configuration.
6. preserve evidence and document actual RTO and RPO.

## Reference objectives

A portfolio demonstration may target an RTO measured in hours and an RPO within Azure SQL point-in-time restore capability. A production firm must set objectives through business impact analysis, not repository defaults.
