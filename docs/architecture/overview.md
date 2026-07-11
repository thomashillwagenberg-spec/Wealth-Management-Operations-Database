# Architecture overview

```mermaid
flowchart LR
    U[Authenticated user] -->|OIDC authorization code + PKCE| W[Blazor Web App]
    W -->|Bearer token / development headers only in Development| A[ASP.NET Core API]
    A -->|Managed identity, encrypted SqlClient connection| S[(Azure SQL Database)]
    A --> M[Application Insights]
    S --> L[Log Analytics]
    S --> B[Protected audit storage]
    A --> K[Key Vault references]
    E[Microsoft Entra ID] --> W
    E --> A
    P[Private DNS + private endpoints] --- A
    P --- S
    P --- K
```

The application is a reference architecture, not a deployed production system. The local profile uses SQL Server and development-only authentication. The Azure profile uses Entra authentication, managed identity, curated procedures and views, private networking, Key Vault, and centralized monitoring.

## Layers

- **Contracts:** transport-safe records
- **Application:** use cases, validation, access checks
- **Infrastructure:** Dapper, `Microsoft.Data.SqlClient`, health checks
- **API:** authentication, policies, middleware, endpoints
- **Web:** Blazor demonstration interface
- **Database:** original SQL plus optional application and Azure hardening scripts
- **Infrastructure:** modular Bicep with development, staging, and production profiles
