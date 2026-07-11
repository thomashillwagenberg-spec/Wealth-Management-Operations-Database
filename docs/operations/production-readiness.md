# Production-readiness checklist

## Required before production

- [ ] Independent architecture and application-security review
- [ ] .NET build, unit, integration, architecture, and security tests pass in CI
- [ ] SQL scripts execute against the selected Azure SQL tier
- [ ] RLS and role tests pass with real Entra groups
- [ ] Managed identity is the only application database credential
- [ ] Public SQL and Key Vault access are disabled
- [ ] Private DNS resolution is verified from App Service
- [ ] Backup restore and regional recovery exercises are completed
- [ ] Defender and vulnerability findings are triaged
- [ ] Logging, alert routing, on-call, and incident response are operational
- [ ] Data classification, retention, deletion, and privacy review are approved
- [ ] Change control, access review, and separation of duties are defined
- [ ] Performance and load tests meet approved objectives
- [ ] Accessibility and user-acceptance testing are complete

The repository is a production reference architecture, not production evidence.
