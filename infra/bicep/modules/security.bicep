param projectName string
param environmentName string
param location string
param suffix string
param tags object
param privateEndpointSubnetId string
param privateDnsZoneId string
param enablePrivateEndpoint bool
param logAnalyticsWorkspaceId string

var vaultName = take(toLower('${projectName}-${environmentName}-kv-${take(suffix,6)}'),24)
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enablePurgeProtection: environmentName == 'prod'
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'
    networkAcls: { bypass: 'AzureServices', defaultAction: enablePrivateEndpoint ? 'Deny' : 'Allow' }
  }
}
resource endpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (enablePrivateEndpoint) {
  name: '${vault.name}-pe'
  location: location
  tags: tags
  properties: { subnet: { id: privateEndpointSubnetId }, privateLinkServiceConnections: [{ name: 'vault', properties: { privateLinkServiceId: vault.id, groupIds: ['vault'] } }] }
}
resource dnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (enablePrivateEndpoint) {
  parent: endpoint
  name: 'default'
  properties: { privateDnsZoneConfigs: [{ name: 'vault', properties: { privateDnsZoneId: privateDnsZoneId } }] }
}
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: vault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'AuditEvent', enabled: true }
      { category: 'AzurePolicyEvaluationDetails', enabled: true }
    ]
    metrics: [{ category: 'AllMetrics', enabled: true }]
  }
}
output keyVaultName string = vault.name
output keyVaultId string = vault.id
