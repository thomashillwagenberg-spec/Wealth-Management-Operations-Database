# Trust boundaries

```mermaid
flowchart TB
    subgraph Internet[Untrusted client boundary]
      Browser[Browser]
    end
    subgraph Identity[Identity boundary]
      Entra[Microsoft Entra ID]
    end
    subgraph App[Application boundary]
      WAF[Optional Front Door Premium + WAF]
      Web[Blazor Web App]
      API[ASP.NET Core API]
    end
    subgraph Data[Private data boundary]
      SQL[(Azure SQL)]
      KV[Key Vault]
      Logs[Log Analytics and protected storage]
    end
    Browser --> Entra
    Browser --> WAF --> Web --> API
    API --> SQL
    API --> KV
    API --> Logs
    SQL --> Logs
```

Key boundaries are token validation, application policy enforcement, object-level access checks, managed-identity database access, database role grants, RLS, and append-oriented audit evidence. Private endpoints reduce exposure but do not replace identity or authorization.
