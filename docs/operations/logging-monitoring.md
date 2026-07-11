# Logging and monitoring

## Application telemetry

- Structured logs with correlation ID
- Authentication and authorization outcomes without token contents
- Dependency duration and failure rates
- Health-check state
- Trade and compliance operation outcomes
- Version and deployment identifiers

## Database and Azure telemetry

- Azure SQL auditing to protected Storage and Log Analytics
- Query Store, errors, blocks, deadlocks, and timeouts
- App Service HTTP 5xx and availability
- SQL capacity alert
- Azure activity and deployment logs

## Exclusions

Never log passwords, access tokens, refresh tokens, private keys, connection strings, full client records, or arbitrary request bodies. Audit metadata is allowlisted and capped.

Alert thresholds in Bicep are starting points and require tuning with real traffic and an on-call process.
