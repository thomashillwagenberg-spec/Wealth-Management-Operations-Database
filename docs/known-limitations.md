# Known limitations

- The .NET solution was not restored, compiled, published, or started in the packaging environment because the .NET SDK was unavailable and network resolution prevented installation.
- Unit, integration, architecture, and security test projects were implemented but not executed for the same reason.
- SQL Server, Docker, and `sqlcmd` were unavailable. The original and extended T-SQL suites were not executed against a database engine.
- Bicep was reviewed structurally but not compiled because Azure CLI and Bicep were unavailable.
- No Azure resources were deployed. Entra authentication, managed identity, Key Vault references, private endpoints, Azure SQL auditing, Defender, monitoring, backup, and failover settings are not operational evidence.
- The generated SPDX file is a source-declared dependency inventory. A full restore/build SBOM and vulnerability scan still require CI or a compatible workstation.
- The application contains synthetic demonstration data only and has not completed performance, load, accessibility, penetration, privacy-impact, backup-restoration, or disaster-recovery testing.
- The hash-chained audit design is tamper-evident within its stated boundary, not independently immutable. External digest protection or Azure SQL Ledger remains an optional deployment decision.
- Dynamic data masking is supplemental and is not a security boundary. Always Encrypted and customer-managed keys require separate key provisioning and compatibility testing.
- The control mapping supports design and readiness discussions. It is not ISO certification, SOC 2 attestation, regulatory approval, or legal advice.
- Package versions are pinned, but current vulnerability status must be checked through GitHub dependency review, CodeQL, container scanning, and a restored dependency graph.
- GitHub workflows are source templates until installed in a repository with protected environments, OIDC federation, branch protections, and required reviews.

Azure infrastructure was not deployed, and no deployed-control claim is made.
