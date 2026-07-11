param policyDefinitionId string

resource denyPublicSqlAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'wm-deny-public-sql'
  properties: {
    displayName: 'Deny public Azure SQL networking for the wealth-management environment'
    policyDefinitionId: policyDefinitionId
    enforcementMode: 'Default'
    parameters: {}
  }
}
