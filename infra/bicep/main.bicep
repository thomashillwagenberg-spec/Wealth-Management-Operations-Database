targetScope = 'resourceGroup'

@description('Short lowercase project prefix used in resource names.')
@minLength(3)
@maxLength(12)
param projectName string = 'wmops'

@allowed(['dev', 'stg', 'prod'])
param environmentName string
param location string = resourceGroup().location
param tags object = {}
param sqlEntraAdminLogin string
param sqlEntraAdminObjectId string
param apiAudience string
param entraAuthority string
param webClientId string
param webApiScope string
param enablePrivateEndpoints bool = environmentName != 'dev'
param enablePublicNetworkForDevelopment bool = environmentName == 'dev'
param enableZoneRedundancy bool = environmentName == 'prod'
param enableGeoBackup bool = environmentName == 'prod'
param enableResourceLocks bool = environmentName == 'prod'
param enableVulnerabilityAssessment bool = false
param alertEmail string = ''
@minValue(0)
param monthlyBudgetAmount int = 0

var suffix = uniqueString(subscription().subscriptionId, resourceGroup().id, projectName, environmentName)
var commonTags = union(tags, {
  application: 'wealth-management-operations'
  environment: environmentName
  dataClassification: 'synthetic-confidential'
  managedBy: 'bicep'
  owner: 'Thomas Wagenberg'
})

module network 'modules/network.bicep' = {
  name: 'network-${environmentName}'
  params: {
    projectName: projectName
    environmentName: environmentName
    location: location
    suffix: suffix
    tags: commonTags
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-${environmentName}'
  params: {
    projectName: projectName
    environmentName: environmentName
    location: location
    suffix: suffix
    tags: commonTags
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    blobPrivateDnsZoneId: network.outputs.blobPrivateDnsZoneId
    enablePrivateEndpoint: enablePrivateEndpoints
  }
}

module security 'modules/security.bicep' = {
  name: 'security-${environmentName}'
  params: {
    projectName: projectName
    environmentName: environmentName
    location: location
    suffix: suffix
    tags: commonTags
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    privateDnsZoneId: network.outputs.keyVaultPrivateDnsZoneId
    enablePrivateEndpoint: enablePrivateEndpoints
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

module data 'modules/data.bicep' = {
  name: 'data-${environmentName}'
  params: {
    projectName: projectName
    environmentName: environmentName
    location: location
    suffix: suffix
    tags: commonTags
    sqlEntraAdminLogin: sqlEntraAdminLogin
    sqlEntraAdminObjectId: sqlEntraAdminObjectId
    enablePublicNetwork: enablePublicNetworkForDevelopment
    enablePrivateEndpoint: enablePrivateEndpoints
    enableZoneRedundancy: enableZoneRedundancy
    enableGeoBackup: enableGeoBackup
    enableVulnerabilityAssessment: enableVulnerabilityAssessment
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    sqlPrivateDnsZoneId: network.outputs.sqlPrivateDnsZoneId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    auditStorageAccountName: monitoring.outputs.auditStorageAccountName
    auditStorageAccountId: monitoring.outputs.auditStorageAccountId
    auditStorageBlobEndpoint: monitoring.outputs.auditStorageBlobEndpoint
  }
}

module app 'modules/app.bicep' = {
  name: 'app-${environmentName}'
  params: {
    projectName: projectName
    environmentName: environmentName
    location: location
    suffix: suffix
    tags: commonTags
    integrationSubnetId: network.outputs.appIntegrationSubnetId
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    appServicePrivateDnsZoneId: network.outputs.appServicePrivateDnsZoneId
    enablePrivateEndpoints: enablePrivateEndpoints
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    sqlServerFqdn: data.outputs.sqlServerFqdn
    sqlDatabaseName: data.outputs.sqlDatabaseName
    keyVaultName: security.outputs.keyVaultName
    apiAudience: apiAudience
    entraAuthority: entraAuthority
    webClientId: webClientId
    webApiScope: webApiScope
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: security.outputs.keyVaultName
}

resource apiKeyVaultReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, app.outputs.apiPrincipalId, 'key-vault-secrets-user')
  scope: keyVault
  properties: {
    principalId: app.outputs.apiPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  }
}

resource webKeyVaultReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, app.outputs.webPrincipalId, 'key-vault-secrets-user')
  scope: keyVault
  properties: {
    principalId: app.outputs.webPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  }
}

module operations 'modules/operations.bicep' = {
  name: 'operations-${environmentName}'
  params: {
    projectName: projectName
    environmentName: environmentName
    location: location
    tags: commonTags
    apiAppId: app.outputs.apiAppId
    sqlDatabaseId: data.outputs.sqlDatabaseId
    actionGroupEmail: alertEmail
    enableResourceLocks: enableResourceLocks
  }
}

module budget 'modules/budget.bicep' = {
  name: 'budget-${environmentName}'
  params: {
    projectName: projectName
    environmentName: environmentName
    amount: monthlyBudgetAmount
    alertEmail: alertEmail
    enabled: monthlyBudgetAmount > 0 && !empty(alertEmail)
  }
}

output apiAppName string = app.outputs.apiAppName
output webAppName string = app.outputs.webAppName
output sqlServerName string = data.outputs.sqlServerName
output sqlDatabaseName string = data.outputs.sqlDatabaseName
output keyVaultName string = security.outputs.keyVaultName
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
