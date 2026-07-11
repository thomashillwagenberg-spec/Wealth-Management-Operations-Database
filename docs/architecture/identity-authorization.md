# Identity and authorization model

## Production

- Blazor uses Microsoft Entra OpenID Connect authorization code flow with PKCE.
- The API validates issuer, audience, lifetime, signing keys, and Entra app roles.
- App Service connects to Azure SQL with its system-assigned managed identity.
- `security.AppUser` maps an Entra object ID to one business role and, for advisors, one `AdvisorID`.
- `security.usp_SetExecutionContext` resolves the mapping server-side and sets SQL session context.
- RLS filters advisor access to assigned clients, accounts, transactions, holdings, reviews, and alerts.

## Local development

Development header and cookie authentication are registered only when `ASPNETCORE_ENVIRONMENT=Development`. Startup throws if API development authentication is enabled outside Development. A caller may select only a fixed synthetic identity from `WealthManagement.Contracts.Security.DevelopmentIdentities`; roles and advisor scope are resolved server-side and are not accepted from request headers or form fields. The same principal names are mapped in `security.AppUser`.

## Role intent

| Role | Intended application rights |
|---|---|
| DatabaseAdministrator | Controlled administration and all application functions |
| AdvisorUser | Assigned client portfolios and synthetic trade entry |
| ComplianceReviewer | Compliance dashboard, alerts, and status updates |
| ReportingAnalyst | Curated reporting only, no raw client tables |
| ReadOnlyAuditor | Read-only operational and audit evidence |

RLS is defense in depth. The application also checks client, account, and advisor scope before returning object-specific results.
