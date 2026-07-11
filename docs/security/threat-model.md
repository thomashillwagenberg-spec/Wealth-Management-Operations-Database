# STRIDE threat model

| Threat | Example | Primary controls | Residual work |
|---|---|---|---|
| Spoofing | Forged or replayed identity token | Entra issuer/audience/signature/lifetime validation, HTTPS | Configure tenant, conditional access, token monitoring |
| Tampering | Change a posted transaction or audit event | Immutable transaction trigger, reversal pattern, append-only audit table, hash chain | Test ledger option and external digest storage |
| Repudiation | User disputes a compliance update | Actor, outcome, timestamp, entity, correlation ID, centralized audit | Time synchronization and evidence custody process |
| Information disclosure | Advisor reads another advisor's clients | Policy checks, object checks, RLS, curated views, private endpoints | Penetration test and entitlement review |
| Denial of service | Large requests or repeated expensive queries | Rate limits, request-size limits, timeouts, pagination, Azure Monitor | WAF and autoscale tuning if justified |
| Elevation of privilege | Client supplies an administrative role claim | Roles accepted only from validated identity, database mapping, no role fields in requests | Entra app-role governance and PIM |

## High-value abuse cases

- Reuse an idempotency key with different trade data
- Sell more than the current holding
- Read another advisor's client by changing the URL identifier
- Modify a stale compliance alert
- Enable development authentication in production
- Retrieve raw client records as a reporting user
- Insert secrets into logs or audit metadata

Tests and SQL validation scripts cover these cases where local execution is possible.
