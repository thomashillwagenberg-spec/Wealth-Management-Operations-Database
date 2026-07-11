param projectName string
param environmentName string
param location string
param suffix string
param tags object

var vnetName = '${projectName}-${environmentName}-vnet-${take(suffix,6)}'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: ['10.40.0.0/16'] }
    subnets: [
      {
        name: 'app-integration'
        properties: {
          addressPrefix: '10.40.1.0/24'
          delegations: [{ name: 'web-delegation', properties: { serviceName: 'Microsoft.Web/serverFarms' } }]
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'private-endpoints'
        properties: {
          addressPrefix: '10.40.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource sqlDns 'Microsoft.Network/privateDnsZones@2024-06-01' = { name: 'privatelink.database.windows.net', location: 'global', tags: tags }
resource webDns 'Microsoft.Network/privateDnsZones@2024-06-01' = { name: 'privatelink.azurewebsites.net', location: 'global', tags: tags }
resource vaultDns 'Microsoft.Network/privateDnsZones@2024-06-01' = { name: 'privatelink.vaultcore.azure.net', location: 'global', tags: tags }
resource blobDns 'Microsoft.Network/privateDnsZones@2024-06-01' = { name: 'privatelink.blob.core.windows.net', location: 'global', tags: tags }

resource sqlLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = { parent: sqlDns, name: 'vnet-link', location: 'global', properties: { virtualNetwork: { id: vnet.id }, registrationEnabled: false } }
resource webLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = { parent: webDns, name: 'vnet-link', location: 'global', properties: { virtualNetwork: { id: vnet.id }, registrationEnabled: false } }
resource vaultLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = { parent: vaultDns, name: 'vnet-link', location: 'global', properties: { virtualNetwork: { id: vnet.id }, registrationEnabled: false } }
resource blobLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = { parent: blobDns, name: 'vnet-link', location: 'global', properties: { virtualNetwork: { id: vnet.id }, registrationEnabled: false } }

output vnetId string = vnet.id
output appIntegrationSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'app-integration')
output privateEndpointSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'private-endpoints')
output sqlPrivateDnsZoneId string = sqlDns.id
output appServicePrivateDnsZoneId string = webDns.id
output keyVaultPrivateDnsZoneId string = vaultDns.id
output blobPrivateDnsZoneId string = blobDns.id
