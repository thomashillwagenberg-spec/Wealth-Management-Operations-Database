# Cost-estimation guide

Do not treat these categories as current quotes. Obtain a region-specific estimate before deployment.

## Development

- Basic App Service Plan shared by API and Web
- Basic or low-cost Azure SQL database
- Low Log Analytics ingestion and short retention
- Standard Key Vault operations
- Locally redundant audit storage
- Private endpoints disabled by default for cost-conscious experimentation

## Staging

- App Service plan with always-on support
- Azure SQL with geo-redundant backup option
- Private endpoints, DNS zones, and VNet integration
- Increased telemetry and retention

## Production reference

- Premium App Service instances, possibly zone redundant
- General Purpose Azure SQL with zone redundancy
- Private endpoints and protected storage
- Longer log, audit, and backup retention
- Defender for SQL
- Optional Front Door Premium, WAF, API Management, second region, and replica database

The largest cost drivers are database compute, duplicate regional capacity, premium networking/security services, telemetry ingestion, and retention.
