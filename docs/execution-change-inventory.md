# Execution-phase change inventory

**Baseline:** the Azure-research-updated repository extracted at the start of this assignment.

This inventory distinguishes files newly added during the implementation and verification phase from pre-existing files materially modified during that phase. Generated caches, build folders, `.git`, and the final ZIP are excluded.

## Files added (15)

- `artifacts/test-results/blocked-gate-attempts.txt`
- `artifacts/test-results/execution-phase-static-check.txt`
- `artifacts/test-results/final-qc-summary.txt`
- `artifacts/test-results/python-syntax.txt`
- `artifacts/test-results/shell-syntax.txt`
- `artifacts/test-results/source-sbom-generation.txt`
- `artifacts/test-results/whitespace-review.txt`
- `docs/execution-change-inventory.md`
- `docs/operations/execution-verification.md`
- `src/WealthManagement.Contracts/Security/DevelopmentIdentities.cs`
- `src/WealthManagement.Web/Components/Pages/AdvisorActivity.razor`
- `src/WealthManagement.Web/Components/Pages/Concentration.razor`
- `tests/WealthManagement.UnitTests/PortfolioServiceTests.cs`
- `tools/execution_phase_check.py`
- `tools/generate_source_sbom.py`

## Files materially modified (47)

- `.github/workflows/package-artifacts.yml`
- `.github/workflows/sql-integration.yml`
- `.github/workflows/sql-static-review.yml`
- `FINAL-DELIVERY.md`
- `README.md`
- `artifacts/test-results/environment-capabilities.txt`
- `artifacts/test-results/platform-static-check.txt`
- `database/local/22_application_procedures.sql`
- `database/security/21_identity_and_row_level_security.sql`
- `database/security/23_transaction_immutability_and_permissions.sql`
- `database/tests/20_application_validation.sql`
- `docs/architecture/identity-authorization.md`
- `docs/known-limitations.md`
- `docs/operations/local-development.md`
- `docs/operations/test-results.md`
- `docs/repository-tree.txt`
- `infra/bicep/main.bicep`
- `infra/bicep/modules/app.bicep`
- `infra/bicep/modules/budget.bicep`
- `infra/bicep/modules/monitoring.bicep`
- `infra/bicep/modules/operations.bicep`
- `infra/bicep/modules/security.bicep`
- `project-manifest.json`
- `scripts/Run-Tests.ps1`
- `scripts/Setup-Local.ps1`
- `scripts/run-tests.sh`
- `scripts/setup-local.sh`
- `src/WealthManagement.Api/Authentication/DevelopmentHeaderAuthenticationHandler.cs`
- `src/WealthManagement.Api/Endpoints/OperationsEndpoints.cs`
- `src/WealthManagement.Api/Endpoints/PortfolioEndpoints.cs`
- `src/WealthManagement.Application/Abstractions/Repositories.cs`
- `src/WealthManagement.Application/Services/Services.cs`
- `src/WealthManagement.Infrastructure/Repositories/AccessControlRepository.cs`
- `src/WealthManagement.Infrastructure/Repositories/ComplianceRepository.cs`
- `src/WealthManagement.Infrastructure/Repositories/TradeRepository.cs`
- `src/WealthManagement.Web/Api/ApiAuthorizationHandler.cs`
- `src/WealthManagement.Web/Api/WealthManagementApiClient.cs`
- `src/WealthManagement.Web/Components/Layout/MainLayout.razor`
- `src/WealthManagement.Web/Components/Pages/Health.razor`
- `src/WealthManagement.Web/Components/Pages/Login.razor`
- `src/WealthManagement.Web/Components/_Imports.razor`
- `src/WealthManagement.Web/Program.cs`
- `tests/WealthManagement.ArchitectureTests/RepositoryArchitectureTests.cs`
- `tests/WealthManagement.IntegrationTests/DatabaseIntegrationTests.cs`
- `tests/WealthManagement.IntegrationTests/SqlIntegrationFactAttribute.cs`
- `tests/WealthManagement.SecurityTests/SecurityBoundaryTests.cs`
- `tests/WealthManagement.UnitTests/TradeServiceTests.cs`

## Interpretation

- “Added” means the path did not exist in the extracted baseline repository.
- “Materially modified” means the path existed in the baseline and has a content change in the working comparison repository.
- Static reports are evidence of executed Python or syntax checks. They are not evidence that .NET, SQL Server, Bicep, Entra, or Azure ran successfully.
