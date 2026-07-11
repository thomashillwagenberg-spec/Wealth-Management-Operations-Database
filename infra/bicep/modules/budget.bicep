param projectName string
param environmentName string
param amount int
param alertEmail string
param enabled bool
@description('First day of the current month in UTC. Override when a deployment platform rejects a past date.')
param startDate string = utcNow('yyyy-MM-01T00:00:00Z')

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = if (enabled) {
  name: '${projectName}-${environmentName}-monthly-budget'
  properties: {
    amount: amount
    category: 'Cost'
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: '2036-12-31T00:00:00Z'
    }
    notifications: empty(alertEmail) ? {} : {
      Actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [alertEmail]
        contactGroups: []
        contactRoles: []
      }
      Forecast100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [alertEmail]
        contactGroups: []
        contactRoles: []
      }
    }
  }
}

output budgetConfigured bool = enabled
