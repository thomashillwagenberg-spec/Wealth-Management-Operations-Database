param projectName string
param environmentName string
param location string
param suffix string
param tags object
param sqlEntraAdminLogin string
param sqlEntraAdminObjectId string
param enablePublicNetwork bool
param enablePrivateEndpoint bool
param enableZoneRedundancy bool
param enableGeoBackup bool
param enableVulnerabilityAssessment bool
param privateEndpointSubnetId string
param sqlPrivateDnsZoneId string
param logAnalyticsWorkspaceId string
param auditStorageAccountName string
param auditStorageAccountId string
param auditStorageBlobEndpoint string

var serverName = toLower('${projectName}-${environmentName}-sql-${take(suffix,8)}')
var databaseName = 'WealthManagementOperations'
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: serverName
  location: location
  tags: tags
  identity: { type: 'SystemAssigned' }
  properties: {
    minimalTlsVersion: '1.2'
    publicNetworkAccess: enablePublicNetwork ? 'Enabled' : 'Disabled'
    restrictOutboundNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: sqlEntraAdminLogin
      sid: sqlEntraAdminObjectId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
  }
}
resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: environmentName == 'prod' ? { name: 'GP_Gen5_2', tier: 'GeneralPurpose', family: 'Gen5', capacity: 2 } : { name: 'Basic', tier: 'Basic', capacity: 5 }
  properties: {
    zoneRedundant: enableZoneRedundancy
    requestedBackupStorageRedundancy: enableGeoBackup ? 'Geo' : 'Local'
    readScale: 'Disabled'
  }
}
resource shortRetention 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2023-08-01-preview' = {
  parent: database
  name: 'default'
  properties: { retentionDays: environmentName == 'prod' ? 35 : 7, diffBackupIntervalInHours: 24 }
}
resource longRetention 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2023-08-01-preview' = {
  parent: database
  name: 'default'
  properties: { weeklyRetention: environmentName == 'prod' ? 'P12W' : 'PT0S', monthlyRetention: environmentName == 'prod' ? 'P12M' : 'PT0S', yearlyRetention: environmentName == 'prod' ? 'P5Y' : 'PT0S', weekOfYear: 1 }
}
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = { name: auditStorageAccountName }
resource sqlAuditWriter 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(auditStorageAccountId, sqlServer.id, 'sql-audit-writer')
  scope: storage
  properties: { principalId: sqlServer.identity.principalId, principalType: 'ServicePrincipal', roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','ba92f5b4-2d11-453d-a403-e96b0029c9fe') }
}
resource auditing 'Microsoft.Sql/servers/auditingSettings@2023-08-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: { state: 'Enabled', isManagedIdentityInUse: true, storageEndpoint: auditStorageBlobEndpoint, retentionDays: environmentName == 'prod' ? 180 : 30, logAnalyticsTargetState: 'Enabled', workspaceResourceId: logAnalyticsWorkspaceId }
  dependsOn: [sqlAuditWriter]
}

resource securityAlertPolicy 'Microsoft.Sql/servers/securityAlertPolicies@2025-01-01' = if (enableVulnerabilityAssessment) {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
  }
}

resource vulnerabilityAssessment 'Microsoft.Sql/servers/sqlVulnerabilityAssessments@2025-01-01' = if (enableVulnerabilityAssessment) {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
  }
  dependsOn: [securityAlertPolicy]
}
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: database
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'SQLInsights', enabled: true }
      { category: 'AutomaticTuning', enabled: true }
      { category: 'QueryStoreRuntimeStatistics', enabled: true }
      { category: 'QueryStoreWaitStatistics', enabled: true }
      { category: 'Errors', enabled: true }
      { category: 'Blocks', enabled: true }
      { category: 'Deadlocks', enabled: true }
      { category: 'Timeouts', enabled: true }
    ]
    metrics: [{ category: 'Basic', enabled: true }]
  }
}
resource endpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateEndpoint) {
  name: '${serverName}-pe'
  location: location
  tags: tags
  properties: { subnet: { id: privateEndpointSubnetId }, privateLinkServiceConnections: [{ name: 'sql', properties: { privateLinkServiceId: sqlServer.id, groupIds: ['sqlServer'] } }] }
}
resource dnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateEndpoint) {
  parent: endpoint
  name: 'default'
  properties: { privateDnsZoneConfigs: [{ name: 'sql', properties: { privateDnsZoneId: sqlPrivateDnsZoneId } }] }
}
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = database.name
output sqlDatabaseId string = database.id
