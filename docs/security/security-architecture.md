# Security architecture

The design follows Zero Trust principles: verify explicitly, use least privilege, assume breach, and collect evidence.

## Implemented in code or templates

- Entra-compatible authentication and strict production guard
- Policy-based role authorization
- Advisor object authorization and SQL RLS
- Managed identity connection pattern
- Parameterized Dapper calls
- Server-side request validation and pagination limits
- Idempotency for trade submission
- Rowversion concurrency for compliance updates
- Immutable posted transaction trigger
- Append-only hash-chained audit events
- HTTPS, HSTS, secure headers, CORS allowlist, request-size limit, and rate limiting
- RFC 7807 errors without sensitive details
- Private endpoint, TLS, Key Vault, auditing, diagnostics, lock, and backup templates

## Operational controls still required

- Entra tenant configuration and access reviews
- Privileged identity management
- Certificate and key rotation drills
- Defender findings triage
- Vulnerability management and patching
- Incident exercises and evidence retention
- Independent penetration testing and code review
- Change approval and separation of duties
