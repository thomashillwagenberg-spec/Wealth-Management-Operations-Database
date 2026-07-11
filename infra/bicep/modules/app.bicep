param projectName string
param environmentName string
param location string
param suffix string
param tags object
param integrationSubnetId string
param privateEndpointSubnetId string
param appServicePrivateDnsZoneId string
param enablePrivateEndpoints bool
param applicationInsightsConnectionString string
param logAnalyticsWorkspaceId string
param sqlServerFqdn string
param sqlDatabaseName string
param keyVaultName string
param apiAudience string
param entraAuthority string
param webClientId string
param webApiScope string

var shortSuffix = take(suffix,6)
var planName = '${projectName}-${environmentName}-plan-${shortSuffix}'
var apiName = toLower('${projectName}-${environmentName}-api-${shortSuffix}')
var webName = toLower('${projectName}-${environmentName}-web-${shortSuffix}')
var sqlConnection = 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=Active Directory Default;'

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: tags
  sku: environmentName == 'prod' ? { name: 'P1v3', tier: 'PremiumV3', capacity: 2 } : { name: 'B1', tier: 'Basic', capacity: 1 }
  kind: 'linux'
  properties: { reserved: true, zoneRedundant: environmentName == 'prod' }
}
resource api 'Microsoft.Web/sites@2023-12-01' = {
  name: apiName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    virtualNetworkSubnetId: enablePrivateEndpoints ? integrationSubnetId : null
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: environmentName != 'dev'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      healthCheckPath: '/health/live'
      appSettings: [
        { name: 'ASPNETCORE_ENVIRONMENT', value: environmentName == 'prod' ? 'Production' : environmentName == 'stg' ? 'Staging' : 'Development' }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: applicationInsightsConnectionString }
        { name: 'ConnectionStrings__WealthManagement', value: sqlConnection }
        { name: 'Authentication__EnableDevelopmentAuth', value: 'false' }
        { name: 'Authentication__Authority', value: entraAuthority }
        { name: 'Authentication__Audience', value: apiAudience }
        { name: 'Database__RequireEncryptedConnection', value: 'true' }
        { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' }
      ]
    }
  }
}
resource web 'Microsoft.Web/sites@2023-12-01' = {
  name: webName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetId: enablePrivateEndpoints ? integrationSubnetId : null
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: environmentName != 'dev'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        { name: 'ASPNETCORE_ENVIRONMENT', value: environmentName == 'prod' ? 'Production' : environmentName == 'stg' ? 'Staging' : 'Development' }
        { name: 'Api__BaseUrl', value: 'https://${apiName}.azurewebsites.net' }
        { name: 'Authentication__Authority', value: entraAuthority }
        { name: 'Authentication__ClientId', value: webClientId }
        { name: 'Authentication__ApiScope', value: webApiScope }
        { name: 'Authentication__ClientSecret', value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/web-oidc-client-secret/)' }
        { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' }
      ]
    }
  }
}
resource apiDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: api
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'AppServiceHTTPLogs', enabled: true }
      { category: 'AppServiceConsoleLogs', enabled: true }
      { category: 'AppServiceAppLogs', enabled: true }
      { category: 'AppServiceAuditLogs', enabled: true }
      { category: 'AppServiceIPSecAuditLogs', enabled: true }
      { category: 'AppServicePlatformLogs', enabled: true }
    ]
    metrics: [{ category: 'AllMetrics', enabled: true }]
  }
}
resource webDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: web
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'AppServiceHTTPLogs', enabled: true }
      { category: 'AppServiceConsoleLogs', enabled: true }
      { category: 'AppServiceAppLogs', enabled: true }
      { category: 'AppServiceAuditLogs', enabled: true }
      { category: 'AppServiceIPSecAuditLogs', enabled: true }
      { category: 'AppServicePlatformLogs', enabled: true }
    ]
    metrics: [{ category: 'AllMetrics', enabled: true }]
  }
}
resource apiEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateEndpoints) {
  name: '${apiName}-pe'
  location: location
  tags: tags
  properties: { subnet: { id: privateEndpointSubnetId }, privateLinkServiceConnections: [{ name: 'sites', properties: { privateLinkServiceId: api.id, groupIds: ['sites'] } }] }
}
resource apiDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateEndpoints) {
  parent: apiEndpoint
  name: 'default'
  properties: { privateDnsZoneConfigs: [{ name: 'sites', properties: { privateDnsZoneId: appServicePrivateDnsZoneId } }] }
}
output apiAppName string = api.name
output webAppName string = web.name
output apiPrincipalId string = api.identity.principalId
output webPrincipalId string = web.identity.principalId
output apiAppId string = api.id
