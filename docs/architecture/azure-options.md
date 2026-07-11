# Azure architecture options

**Research basis:** [Azure SQL Reference Research](../AZURE_SQL_REFERENCE_RESEARCH.md), accessed July 11, 2026.

## Selected baseline

- Azure SQL Database, single database
- General Purpose, provisioned compute for the production reference
- Existing low-cost development profile, with serverless documented as an optional measured experiment
- Azure App Service for the API and Blazor application
- System-assigned managed identities
- Microsoft Entra administrator and contained database principals
- Entra-only production authentication
- Private endpoints, private DNS, and public-network disablement outside development
- TDE, SQL auditing, diagnostics, Azure Monitor, Application Insights, and protected audit storage
- Modular Bicep and GitHub Actions OpenID Connect

## Why Azure SQL Database

The application is a new, single-database workload that uses database-scoped SQL Server capabilities. It does not require operating-system access, SQL Server Agent, or instance-level compatibility. Managed Instance and SQL Server on Azure Virtual Machines would add cost and operational responsibility without a demonstrated requirement.

## Optional production decisions

| Option | Benefit | Cost or burden | Decision gate |
|---|---|---|---|
| Serverless development database | Potential savings for intermittent activity | Auto-pause can be prevented by sessions, probes, or background activity | Measure actual activity and connection behavior |
| Business Critical | Lower latency and stronger high-availability/read-scale characteristics | Higher cost | Measured latency and availability need |
| Customer-managed TDE key | Greater key control | Key availability, rotation, separation of duties, recovery ownership | Formal key-management process |
| Defender for SQL and vulnerability assessment | Threat and configuration findings | Paid service, alerts, triage, remediation ownership | Budget and security operations owner |
| Deployment slots | Staged application release and swap | Additional deployment discipline; does not roll back schema automatically | Tested release and database migration strategy |
| Active geo-replication or failover group | Regional recovery and stable failover endpoint | Second-region cost, data-loss choices, operations, testing | Approved RTO, RPO, and business impact analysis |
| Front Door Premium and WAF | Global ingress and application-layer protection | Cost, tuning, false positives, operations | Public production traffic model |
| API Management | Policies, developer portal, productized APIs | Cost and operating layer | Multiple consumers or externally managed API program |
| Hyperscale | Independently scalable compute and storage for very large databases | Complexity and cost not justified by current data | Demonstrated scale requirement |
| Elastic pool | Shared resources across multiple databases | No benefit for one database | Multi-database tenancy or portfolio |

## Explicitly not claimed

The templates have not been compiled or deployed in Azure. Zone redundancy, backups, private networking, managed identity, Entra-only authentication, auditing, monitoring, Defender, restore, and failover behavior remain unverified until executed in an approved subscription.
