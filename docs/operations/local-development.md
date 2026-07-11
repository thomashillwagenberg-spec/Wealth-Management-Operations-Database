# Local development guide

## Prerequisites

- .NET 10 SDK version selected by `global.json`
- Docker Desktop with Linux containers, or a supported local SQL Server instance
- Python 3.11 or newer
- Optional SSMS for direct database study

## Fastest complete startup

```bash
cp .env.example .env
# Edit .env and replace MSSQL_SA_PASSWORD and WM_APP_PASSWORD with different strong local-only values.
./scripts/setup-local.sh
docker compose --profile app up --build -d api web
```

This starts and initializes SQL Server before starting the applications:

- SQL Server on `localhost:1433`
- API on `http://localhost:5187`
- Web demonstration on `http://localhost:5188`

The initialization process uses `sa` only for database administration and creates a separate `wm_application` login for the API. The API does not run as `sa`.

## Database-only startup

```bash
cp .env.example .env
# Edit the uncommitted .env file.
./scripts/setup-local.sh
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
# Edit .env, then:
./scripts/Setup-Local.ps1
```

## Run applications outside containers

Load the uncommitted environment file and map the application connection string:

```bash
set -a
source .env
set +a
export ConnectionStrings__WealthManagement="$WM_SQL_CONNECTION"
export ASPNETCORE_ENVIRONMENT=Development

dotnet run --project src/WealthManagement.Api/WealthManagement.Api.csproj
```

In a second terminal:

```bash
export ASPNETCORE_ENVIRONMENT=Development
dotnet run --project src/WealthManagement.Web/WealthManagement.Web.csproj
```

Use the URLs printed by `dotnet run`. The development sign-in page is available only when the Web application runs in the `Development` environment. Production startup fails rather than enabling header authentication without valid Entra configuration.

## Static and .NET tests

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

## SQL integration tests

After initialization:

```bash
set -a
source .env
set +a
export WM_SQL_ADMIN_CONNECTION="Server=localhost,1433;Initial Catalog=WealthManagementOperations;User ID=sa;Password=${MSSQL_SA_PASSWORD};Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
export WM_SQL_INTEGRATION_CONNECTION="$WM_SQL_CONNECTION"
dotnet test tests/WealthManagement.IntegrationTests/WealthManagement.IntegrationTests.csproj
```

You can also execute `database/tests/20_application_validation.sql` directly in SSMS or `sqlcmd` as an authorized test principal.

## Shutdown and reset

```bash
docker compose --profile app down
```

To delete the local SQL Server volume and all local demonstration data:

```bash
docker compose --profile app down -v
```

The reset is destructive. Use it only for synthetic local data.
