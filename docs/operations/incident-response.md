# Incident-response runbook

1. **Detect:** alert from App Insights, Azure SQL auditing, Defender, access review, or user report.
2. **Triage:** classify impact, affected identities, data, transactions, and environments.
3. **Contain:** disable compromised identities, revoke sessions, restrict network paths, stop deployment, or place the application in read-only mode.
4. **Preserve evidence:** export audit events, Azure activity logs, deployment logs, and relevant database audit records to protected storage.
5. **Eradicate:** correct the root cause, rotate affected secrets or keys, patch dependencies, and remove unauthorized access.
6. **Recover:** restore service through approved deployment or database recovery procedures and validate controls.
7. **Notify:** follow legal, contractual, insurance, and regulatory notification procedures owned by the organization.
8. **Learn:** complete a blameless review, update controls, tests, and runbooks.

Do not include tokens, passwords, full request bodies, or connection strings in incident tickets.
