# Final delivery report

## Outcome

The Azure-researched baseline repository was advanced through an implementation and verification phase without replacing the original SQL Server educational project. The final source now contains the layered .NET application, database hardening, dedicated concentration and advisor-activity workflows, server-resolved development identities, stronger object-level authorization, idempotency evidence, operational health output, expanded Bicep diagnostics/private connectivity, self-contained SQL integration CI, and preserved verification evidence.

All clients, accounts, portfolios, alerts, and trades remain fictional and synthetic.

## Runtime evidence boundary

The packaging environment did not provide .NET, Docker, SQL Server, `sqlcmd`, Azure CLI, or Bicep, and network name resolution prevented safe tool installation. Therefore:

- .NET restore, compilation, publishing, tests, and startup were attempted but blocked.
- SQL Server initialization and database tests were attempted but blocked.
- Bicep build and Azure what-if were attempted but blocked.
- No Azure resource was deployed.
- No runtime success is claimed for the application, database, Entra, managed identity, private networking, backup, failover, or monitoring.

Exact outputs and exit codes are preserved in `artifacts/test-results/`.

## Executed verification

| Test | Result | Evidence boundary |
|---|---:|---|
| Original SQL checker | 71 passed, 0 failed | Actual Python execution; no SQL engine |
| Expanded platform checker | 45 passed, 0 failed | Actual Python execution; static/structural |
| Execution-phase checker | 26 passed, 0 failed | Actual Python execution; source/wiring |
| Python syntax | Passed | Tool syntax only |
| Bash syntax | Passed | Script syntax only |
| Source-declared SPDX inventory | Generated | Direct declarations only, not resolved dependencies |

## Security corrections completed in source

- Development role and advisor claims are no longer accepted from request data. A fixed synthetic identity catalog resolves them server-side.
- Client, account, and advisor object-level checks are implemented before repository access.
- Advisor activity has a matching database access procedure and least-privilege grant.
- Idempotent trade replay returns the original transaction and correlation identifier.
- Compliance error mapping distinguishes authorization, business rules, missing records, and concurrency conflicts.
- App Service and Key Vault diagnostics target Log Analytics.
- Audit storage has optional private endpoint and private DNS support.
- SQL integration CI uses ephemeral generated passwords, initializes a disposable SQL Server container, uploads evidence, and tears down the environment.

## Package inventory

- Final source files: 238
- Files added during this phase: 15
- Pre-existing files materially modified: 47
- SQL files: 34
- C# files: 52
- Razor files: 17
- Bicep and parameter files: 13
- GitHub Actions workflows: 11

## Major files added in this phase

See `docs/execution-change-inventory.md` for the exact comparison. Principal additions include:

- `src/WealthManagement.Contracts/Security/DevelopmentIdentities.cs`
- `src/WealthManagement.Web/Components/Pages/Concentration.razor`
- `src/WealthManagement.Web/Components/Pages/AdvisorActivity.razor`
- `tests/WealthManagement.UnitTests/PortfolioServiceTests.cs`
- `tools/execution_phase_check.py`
- `tools/generate_source_sbom.py`
- `docs/operations/execution-verification.md`
- `artifacts/test-results/blocked-gate-attempts.txt`

## Local startup

```bash
cp .env.example .env
# Replace both placeholders with different strong local-only passwords.
./scripts/setup-local.sh
docker compose --profile app up --build -d api web
```

Web: `http://localhost:5188`
API: `http://localhost:5187`

## Complete local validation

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tools/static_check.py
PYTHONDONTWRITEBYTECODE=1 python3 tools/platform_static_check.py
PYTHONDONTWRITEBYTECODE=1 python3 tools/generate_source_sbom.py
PYTHONDONTWRITEBYTECODE=1 python3 tools/execution_phase_check.py
bash -n scripts/*.sh

dotnet restore WealthManagement.slnx
dotnet build WealthManagement.slnx -c Release --no-restore
dotnet test WealthManagement.slnx -c Release --no-build --collect:"XPlat Code Coverage"
```

## Bicep validation

```bash
az bicep install
az bicep build --file infra/bicep/main.bicep
az bicep build --file infra/bicep/cmk-option.bicep
az bicep build --file infra/bicep/policy/subscription-security.bicep
az deployment group validate \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --parameters infra/bicep/parameters/dev.bicepparam
az deployment group what-if \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --parameters infra/bicep/parameters/dev.bicepparam
```

## Azure deployment

```bash
az login
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION"
az deployment group create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --parameters infra/bicep/parameters/dev.bicepparam \
  --name "wmops-dev-$(date +%Y%m%d%H%M%S)"
```

No deployment was performed during packaging.

## Claims boundary

Safe claims and prohibited claims are maintained in `docs/claims.md`. The project is an educational, enterprise-style reference implementation. It is not production proof, ISO certification, SOC 2 attestation, SEC or FINRA compliance, Microsoft approval, or evidence that any cloud control is operating.
