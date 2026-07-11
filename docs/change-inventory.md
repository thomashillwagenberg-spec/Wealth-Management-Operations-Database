# Change inventory

Compared with the attached original SQL Server repository.

## Files added

### `.env.example`

- `.env.example`
### `.github`

- `.github/workflows/bicep-validation.yml`
- `.github/workflows/codeql.yml`
- `.github/workflows/container-scan.yml`
- `.github/workflows/dependency-review.yml`
- `.github/workflows/deploy-azure.yml`
- `.github/workflows/dotnet-ci.yml`
- `.github/workflows/package-artifacts.yml`
- `.github/workflows/sbom.yml`
- `.github/workflows/secret-scan.yml`
- `.github/workflows/sql-integration.yml`
- `.github/workflows/sql-static-review.yml`
### `Directory.Build.props`

- `Directory.Build.props`
### `Directory.Packages.props`

- `Directory.Packages.props`
### `FINAL-DELIVERY.md`

- `FINAL-DELIVERY.md`
### `WealthManagement.slnx`

- `WealthManagement.slnx`
### `artifacts`

- `artifacts/test-results/.gitkeep`
- `artifacts/test-results/environment-capabilities.txt`
- `artifacts/test-results/final-qc-summary.json`
- `artifacts/test-results/original-static-check.txt`
- `artifacts/test-results/platform-static-check.txt`
### `database`

- `database/azure/10_entra_principals.template.sql`
- `database/azure/11_sensitivity_classification.sql`
- `database/azure/12_dynamic_data_masking.sql`
- `database/azure/13_always_encrypted_evaluation.sql`
- `database/azure/14_ledger_audit_optional.sql`
- `database/azure/15_azure_validation.sql`
- `database/azure/run_azure_schema.sql`
- `database/local/20_application_extensions.sql`
- `database/local/22_application_procedures.sql`
- `database/local/25_create_local_application_login.sql`
- `database/local/run_application_extensions.sql`
- `database/security/21_identity_and_row_level_security.sql`
- `database/security/23_transaction_immutability_and_permissions.sql`
- `database/security/24_temporal_history.sql`
- `database/tests/20_application_validation.sql`
- `database/tests/30_azure_security_validation.sql`
### `docker-compose.yml`

- `docker-compose.yml`
### `docs`

- `docs/AZURE_INSPIRED_FUNCTIONAL_PARITY_MATRIX.md`
- `docs/AZURE_SQL_REFERENCE_RESEARCH.md`
- `docs/ORIGINALITY_AND_BRAND_REVIEW.md`
- `docs/architecture/azure-options.md`
- `docs/architecture/data-flow.md`
- `docs/architecture/database-access.md`
- `docs/architecture/identity-authorization.md`
- `docs/architecture/overview.md`
- `docs/architecture/trust-boundaries.md`
- `docs/change-inventory.md`
- `docs/claims.md`
- `docs/compliance/control-mapping.md`
- `docs/compliance/shared-responsibility.md`
- `docs/current-state-assessment.md`
- `docs/decisions/ADR-001-dapper-and-stored-procedures.md`
- `docs/decisions/ADR-002-identity-and-row-isolation.md`
- `docs/decisions/ADR-003-audit-ledger.md`
- `docs/decisions/ADR-004-deployment-profiles.md`
- `docs/known-limitations.md`
- `docs/operations/azure-deployment.md`
- `docs/operations/backup-disaster-recovery.md`
- `docs/operations/capture-guide.md`
- `docs/operations/cost-estimation.md`
- `docs/operations/demo-script.md`
- `docs/operations/incident-response.md`
- `docs/operations/local-development.md`
- `docs/operations/logging-monitoring.md`
- `docs/operations/production-readiness.md`
- `docs/operations/test-results.md`
- `docs/original-learning-readme.md`
- `docs/repository-tree.txt`
- `docs/security/data-classification-register.md`
- `docs/security/key-management.md`
- `docs/security/privacy-retention.md`
- `docs/security/secrets-management.md`
- `docs/security/security-architecture.md`
- `docs/security/threat-model.md`
- `docs/security/vulnerability-management.md`
### `global.json`

- `global.json`
### `infra`

- `infra/bicep/cmk-option.bicep`
- `infra/bicep/main.bicep`
- `infra/bicep/modules/app.bicep`
- `infra/bicep/modules/budget.bicep`
- `infra/bicep/modules/data.bicep`
- `infra/bicep/modules/monitoring.bicep`
- `infra/bicep/modules/network.bicep`
- `infra/bicep/modules/operations.bicep`
- `infra/bicep/modules/security.bicep`
- `infra/bicep/parameters/dev.bicepparam`
- `infra/bicep/parameters/prod.bicepparam`
- `infra/bicep/parameters/staging.bicepparam`
- `infra/bicep/policy/subscription-security.bicep`
### `scripts`

- `scripts/Run-Tests.ps1`
- `scripts/Setup-Local.ps1`
- `scripts/deploy-azure.sh`
- `scripts/init-database.sh`
- `scripts/run-tests.sh`
- `scripts/setup-local.sh`
### `src`

- `src/WealthManagement.Api/Authentication/AuthenticationExtensions.cs`
- `src/WealthManagement.Api/Authentication/DevelopmentHeaderAuthenticationHandler.cs`
- `src/WealthManagement.Api/Authorization/CurrentUserContext.cs`
- `src/WealthManagement.Api/Authorization/RoleNames.cs`
- `src/WealthManagement.Api/Dockerfile`
- `src/WealthManagement.Api/Endpoints/AuditEndpoints.cs`
- `src/WealthManagement.Api/Endpoints/ComplianceEndpoints.cs`
- `src/WealthManagement.Api/Endpoints/OperationsEndpoints.cs`
- `src/WealthManagement.Api/Endpoints/PortfolioEndpoints.cs`
- `src/WealthManagement.Api/Endpoints/TradeEndpoints.cs`
- `src/WealthManagement.Api/Middleware/CorrelationIdMiddleware.cs`
- `src/WealthManagement.Api/Middleware/GlobalExceptionHandler.cs`
- `src/WealthManagement.Api/Middleware/SecurityHeadersMiddleware.cs`
- `src/WealthManagement.Api/Program.cs`
- `src/WealthManagement.Api/Properties/launchSettings.json`
- `src/WealthManagement.Api/WealthManagement.Api.csproj`
- `src/WealthManagement.Api/appsettings.Development.json`
- `src/WealthManagement.Api/appsettings.json`
- `src/WealthManagement.Application/Abstractions/ICurrentUserContext.cs`
- `src/WealthManagement.Application/Abstractions/Repositories.cs`
- `src/WealthManagement.Application/Services/Services.cs`
- `src/WealthManagement.Application/Validation/ComplianceValidators.cs`
- `src/WealthManagement.Application/Validation/SubmitTradeRequestValidator.cs`
- `src/WealthManagement.Application/Validation/Validation.cs`
- `src/WealthManagement.Application/WealthManagement.Application.csproj`
- `src/WealthManagement.Contracts/Audit/AuditDtos.cs`
- `src/WealthManagement.Contracts/Common/ApiError.cs`
- `src/WealthManagement.Contracts/Common/PagedResult.cs`
- `src/WealthManagement.Contracts/Compliance/ComplianceDtos.cs`
- `src/WealthManagement.Contracts/Operations/OperationsDtos.cs`
- `src/WealthManagement.Contracts/Portfolios/PortfolioDtos.cs`
- `src/WealthManagement.Contracts/Trading/TradeDtos.cs`
- `src/WealthManagement.Contracts/WealthManagement.Contracts.csproj`
- `src/WealthManagement.Infrastructure/Data/DatabaseOptions.cs`
- `src/WealthManagement.Infrastructure/Data/ISqlConnectionFactory.cs`
- `src/WealthManagement.Infrastructure/Data/SqlConnectionFactory.cs`
- `src/WealthManagement.Infrastructure/DependencyInjection.cs`
- `src/WealthManagement.Infrastructure/Health/SqlDatabaseHealthCheck.cs`
- `src/WealthManagement.Infrastructure/Repositories/AccessControlRepository.cs`
- `src/WealthManagement.Infrastructure/Repositories/AuditRepository.cs`
- `src/WealthManagement.Infrastructure/Repositories/ComplianceRepository.cs`
- `src/WealthManagement.Infrastructure/Repositories/PortfolioRepository.cs`
- `src/WealthManagement.Infrastructure/Repositories/TradeRepository.cs`
- `src/WealthManagement.Infrastructure/WealthManagement.Infrastructure.csproj`
- `src/WealthManagement.Web/Api/ApiAuthorizationHandler.cs`
- `src/WealthManagement.Web/Api/WealthManagementApiClient.cs`
- `src/WealthManagement.Web/Components/App.razor`
- `src/WealthManagement.Web/Components/Layout/MainLayout.razor`
- `src/WealthManagement.Web/Components/Pages/Allocation.razor`
- `src/WealthManagement.Web/Components/Pages/Audit.razor`
- `src/WealthManagement.Web/Components/Pages/ClientPortfolio.razor`
- `src/WealthManagement.Web/Components/Pages/Clients.razor`
- `src/WealthManagement.Web/Components/Pages/Compliance.razor`
- `src/WealthManagement.Web/Components/Pages/Error.razor`
- `src/WealthManagement.Web/Components/Pages/Health.razor`
- `src/WealthManagement.Web/Components/Pages/Home.razor`
- `src/WealthManagement.Web/Components/Pages/Login.razor`
- `src/WealthManagement.Web/Components/Pages/Risk.razor`
- `src/WealthManagement.Web/Components/Pages/Trade.razor`
- `src/WealthManagement.Web/Components/Routes.razor`
- `src/WealthManagement.Web/Components/_Imports.razor`
- `src/WealthManagement.Web/Dockerfile`
- `src/WealthManagement.Web/Middleware/SecurityHeadersMiddleware.cs`
- `src/WealthManagement.Web/Program.cs`
- `src/WealthManagement.Web/Properties/launchSettings.json`
- `src/WealthManagement.Web/WealthManagement.Web.csproj`
- `src/WealthManagement.Web/appsettings.json`
- `src/WealthManagement.Web/wwwroot/app.css`
### `tests`

- `tests/WealthManagement.ArchitectureTests/GlobalUsings.cs`
- `tests/WealthManagement.ArchitectureTests/RepositoryArchitectureTests.cs`
- `tests/WealthManagement.ArchitectureTests/WealthManagement.ArchitectureTests.csproj`
- `tests/WealthManagement.IntegrationTests/DatabaseIntegrationTests.cs`
- `tests/WealthManagement.IntegrationTests/GlobalUsings.cs`
- `tests/WealthManagement.IntegrationTests/SqlIntegrationFactAttribute.cs`
- `tests/WealthManagement.IntegrationTests/WealthManagement.IntegrationTests.csproj`
- `tests/WealthManagement.SecurityTests/GlobalUsings.cs`
- `tests/WealthManagement.SecurityTests/SecurityBoundaryTests.cs`
- `tests/WealthManagement.SecurityTests/WealthManagement.SecurityTests.csproj`
- `tests/WealthManagement.UnitTests/GlobalUsings.cs`
- `tests/WealthManagement.UnitTests/TradeServiceTests.cs`
- `tests/WealthManagement.UnitTests/ValidationTests.cs`
- `tests/WealthManagement.UnitTests/WealthManagement.UnitTests.csproj`
### `tools`

- `tools/platform_static_check.py`

## Files materially changed

- `.gitignore`
- `README.md`
- `project-manifest.json`

## Files removed

None. The original project files were retained.

## Summary

- Added: 179 files
- Materially changed: 3 files
- Removed: 0 files

## July 11, 2026 Azure SQL research revision

Added the three mandated research, functional-parity, and originality documents. Updated the README, Azure architecture-options document, source-verification document, application header, static checker, test evidence, manifest, final delivery report, and repository tree to reflect the research without changing the original SQL learning sequence.
