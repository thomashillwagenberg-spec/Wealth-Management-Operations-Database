# Claims guide

## Claims Thomas can safely make

- The original SQL Server learning project was preserved and expanded into an enterprise-style .NET and Azure reference architecture.
- The repository contains a layered ASP.NET Core API, a Blazor demonstration interface, Dapper-based database access, database-hardening scripts, Bicep templates, tests, GitHub Actions, and operational documentation.
- The design uses fictional and synthetic data only.
- The original Python checker passed 71 static checks in the packaging environment.
- The expanded platform checker passed its final static and structural checks in the packaging environment.
- The design includes code and templates for policy authorization, advisor isolation, managed identity, idempotency, concurrency, audit evidence, private networking, monitoring, and deployment automation.
- The repository is Azure-ready as a reference implementation, subject to compilation, engine testing, deployment, and professional review.
- The control mapping is intended to support ISO 27001-aligned and SOC 2-readiness discussions, not certification claims.

## Claims Thomas must not make

- The .NET solution compiled or all tests passed unless CI or a workstation produces that evidence.
- The SQL database built or the stored procedures, permissions, RLS, temporal tables, or audit chain worked unless they are executed successfully.
- The Bicep templates compiled, passed `what-if`, or deployed successfully unless Azure produces that evidence.
- Azure networking, managed identity, Defender, auditing, backup, restore, geo-recovery, or monitoring is operational.
- An index improved performance without measured plans and workload evidence.
- The platform is production-ready, production-proven, unhackable, or appropriate for real client data.
- The project is ISO certified, SOC 2 certified, SEC compliant, FINRA compliant, bank certified, or independently audited.
- The repository replaces the judgment of database, cloud, security, privacy, legal, or compliance professionals.
