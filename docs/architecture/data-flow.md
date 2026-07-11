# Data-flow diagram

```mermaid
sequenceDiagram
    actor User
    participant Web as Blazor Web
    participant Entra as Microsoft Entra ID
    participant API as ASP.NET Core API
    participant SQL as Azure SQL
    participant Audit as Audit evidence

    User->>Web: Select a portfolio or submit a synthetic trade
    Web->>Entra: Authenticate with OIDC + PKCE
    Entra-->>Web: Identity and API token
    Web->>API: HTTPS request + token + correlation ID
    API->>API: Validate token, policy, request, object scope
    API->>SQL: Open encrypted managed-identity connection
    API->>SQL: Resolve server-side application user mapping
    SQL->>SQL: Set session context and apply RLS
    API->>SQL: Execute parameterized view/procedure call
    SQL->>Audit: Append outcome with correlation ID
    SQL-->>API: Curated result
    API-->>Web: RFC 7807 error or typed result
```

No browser-supplied role, advisor identifier, or client identifier is treated as authorization proof. Production roles originate from Entra and are resolved against `security.AppUser` before database session context is set.
