using '../main.bicep'
param environmentName = 'stg'
param sqlEntraAdminLogin = readEnvironmentVariable('AZURE_SQL_ADMIN_LOGIN')
param sqlEntraAdminObjectId = readEnvironmentVariable('AZURE_SQL_ADMIN_OBJECT_ID')
param apiAudience = readEnvironmentVariable('WM_API_AUDIENCE')
param entraAuthority = readEnvironmentVariable('WM_ENTRA_AUTHORITY')
param webClientId = readEnvironmentVariable('WM_WEB_CLIENT_ID')
param webApiScope = readEnvironmentVariable('WM_WEB_API_SCOPE')
param enablePrivateEndpoints = true
param enablePublicNetworkForDevelopment = false
param enableZoneRedundancy = false
param enableGeoBackup = true
param enableResourceLocks = false

// Set a reviewed monthly limit before deployment; zero leaves the budget resource disabled.
param monthlyBudgetAmount = 0

// Requires a reviewed Defender for SQL subscription configuration.
param enableVulnerabilityAssessment = false
