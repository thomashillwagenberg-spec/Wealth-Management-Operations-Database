param projectName string
param environmentName string
param location string
param tags object
param apiAppId string
param sqlDatabaseId string
param actionGroupEmail string
param enableResourceLocks bool

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (!empty(actionGroupEmail)) {
  name: '${projectName}-${environmentName}-ops'
  location: 'global'
  tags: tags
  properties: { groupShortName: 'wmops' enabled: true emailReceivers: [{ name: 'operations' emailAddress: actionGroupEmail useCommonAlertSchema: true }] }
}
resource appAvailability 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${projectName}-${environmentName}-http5xx'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts on sustained App Service server errors.'
    severity: 2
    enabled: true
    scopes: [apiAppId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: { 'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria' allOf: [{ name: 'Http5xx' metricName: 'Http5xx' metricNamespace: 'Microsoft.Web/sites' operator: 'GreaterThan' threshold: 5 timeAggregation: 'Total' criterionType: 'StaticThresholdCriterion' }] }
    actions: empty(actionGroupEmail) ? [] : [{ actionGroupId: actionGroup.id }]
  }
}
resource sqlCapacityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${projectName}-${environmentName}-sql-capacity'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts when Azure SQL capacity remains high.'
    severity: 2
    enabled: true
    scopes: [sqlDatabaseId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: { 'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria' allOf: [{ name: 'Capacity' metricName: 'cpu_percent' metricNamespace: 'Microsoft.Sql/servers/databases' operator: 'GreaterThan' threshold: 85 timeAggregation: 'Average' criterionType: 'StaticThresholdCriterion' }] }
    actions: empty(actionGroupEmail) ? [] : [{ actionGroupId: actionGroup.id }]
  }
}
resource apiLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLocks) { name: 'protect-environment' scope: resourceGroup() properties: { level: 'CanNotDelete' notes: 'Production deletion protection. Use a controlled change to remove.' } }
