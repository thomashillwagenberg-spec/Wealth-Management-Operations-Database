targetScope = 'subscription'
param enableDefenderForSql bool = false
param assignDenyPublicSql bool = false
param targetResourceGroupName string = ''

resource sqlDefender 'Microsoft.Security/pricings@2024-01-01' = if (enableDefenderForSql) {
  name: 'SqlServers'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'V2'
  }
}

resource denyPublicSqlDefinition 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'wm-deny-public-sql'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Wealth Management: deny public Azure SQL networking'
    description: 'Production resource groups should disable Azure SQL public network access.'
    metadata: { category: 'SQL' }
    parameters: {}
    policyRule: {
      if: {
        allOf: [
          { field: 'type', equals: 'Microsoft.Sql/servers' }
          { field: 'Microsoft.Sql/servers/publicNetworkAccess', notEquals: 'Disabled' }
        ]
      }
      then: { effect: 'deny' }
    }
  }
}

resource targetResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = if (assignDenyPublicSql) {
  name: targetResourceGroupName
}

resource denyPublicSqlAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (assignDenyPublicSql) {
  name: 'wm-deny-public-sql'
  scope: targetResourceGroup
  properties: {
    displayName: 'Deny public Azure SQL networking for the wealth-management environment'
    policyDefinitionId: denyPublicSqlDefinition.id
    enforcementMode: 'Default'
    parameters: {}
  }
}

output defenderEnabled bool = enableDefenderForSql
output policyAssigned bool = assignDenyPublicSql
