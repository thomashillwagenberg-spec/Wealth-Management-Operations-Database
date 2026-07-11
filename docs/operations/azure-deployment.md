# Azure deployment guide

No paid resource was deployed while building this repository.

## Prerequisites

- Azure CLI with Bicep
- An approved subscription and resource group
- Entra app registrations and app roles
- An Entra group selected as Azure SQL administrator
- GitHub OIDC federation for automated deployment

## Validate

```bash
az bicep build --file infra/bicep/main.bicep
az deployment group what-if \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --parameters infra/bicep/parameters/dev.bicepparam
```

## Deploy infrastructure

```bash
az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION"
az deployment group create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --parameters infra/bicep/parameters/dev.bicepparam \
  --name wmops-dev-initial
```

## Deploy schema

Connect as the configured Entra SQL administrator to `WealthManagementOperations` and run `database/azure/run_azure_schema.sql` in SQLCMD mode. Then replace placeholders in `database/azure/10_entra_principals.template.sql`, create the App Service managed-identity user, and add it to `WealthManagementApplication`.

## Deploy application packages

```bash
dotnet publish src/WealthManagement.Api -c Release -o artifacts/api
dotnet publish src/WealthManagement.Web -c Release -o artifacts/web
az webapp deploy --resource-group "$AZURE_RESOURCE_GROUP" --name "$API_APP_NAME" --src-path artifacts/api --type zip
az webapp deploy --resource-group "$AZURE_RESOURCE_GROUP" --name "$WEB_APP_NAME" --src-path artifacts/web --type zip
```

Run the Azure validation script and health checks before routing users.
