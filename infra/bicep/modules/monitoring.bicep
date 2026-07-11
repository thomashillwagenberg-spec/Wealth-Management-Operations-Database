param projectName string
param environmentName string
param location string
param suffix string
param tags object
param privateEndpointSubnetId string
param blobPrivateDnsZoneId string
param enablePrivateEndpoint bool

var shortSuffix = take(suffix, 8)
resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${projectName}-${environmentName}-log-${shortSuffix}'
  location: location
  tags: tags
  properties: { sku: { name: 'PerGB2018' } retentionInDays: environmentName == 'prod' ? 90 : 30 publicNetworkAccessForIngestion: 'Enabled' publicNetworkAccessForQuery: 'Enabled' }
}
resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${projectName}-${environmentName}-appi-${shortSuffix}'
  location: location
  kind: 'web'
  tags: tags
  properties: { Application_Type: 'web' WorkspaceResourceId: workspace.id DisableIpMasking: false IngestionMode: 'LogAnalytics' }
}
resource auditStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: take(toLower(replace('${projectName}${environmentName}audit${shortSuffix}','-','')),24)
  location: location
  tags: tags
  sku: { name: environmentName == 'prod' ? 'Standard_GZRS' : 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: environmentName == 'dev' ? 'Enabled' : 'Disabled'
    networkAcls: { defaultAction: environmentName == 'dev' ? 'Allow' : 'Deny' bypass: 'AzureServices' }
    encryption: { keySource: 'Microsoft.Storage' services: { blob: { enabled: true keyType: 'Account' } file: { enabled: true keyType: 'Account' } } }
  }
}
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: auditStorage
  name: 'default'
  properties: { deleteRetentionPolicy: { enabled: true days: environmentName == 'prod' ? 30 : 7 } containerDeleteRetentionPolicy: { enabled: true days: environmentName == 'prod' ? 30 : 7 } isVersioningEnabled: true }
}
resource auditContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = { parent: blobService name: 'sqlauditlogs' properties: { publicAccess: 'None' } }
resource auditStorageEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateEndpoint) {
  name: '${auditStorage.name}-blob-pe'
  location: location
  tags: tags
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [{
      name: 'blob'
      properties: { privateLinkServiceId: auditStorage.id groupIds: ['blob'] }
    }]
  }
}
resource auditStorageDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateEndpoint) {
  parent: auditStorageEndpoint
  name: 'default'
  properties: { privateDnsZoneConfigs: [{ name: 'blob' properties: { privateDnsZoneId: blobPrivateDnsZoneId } }] }
}

output logAnalyticsWorkspaceId string = workspace.id
output applicationInsightsName string = insights.name
output applicationInsightsConnectionString string = insights.properties.ConnectionString
output auditStorageAccountName string = auditStorage.name
output auditStorageAccountId string = auditStorage.id
output auditStorageBlobEndpoint string = auditStorage.properties.primaryEndpoints.blob
