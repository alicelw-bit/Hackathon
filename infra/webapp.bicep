param webAppName string // = uniqueString(resourceGroup().id) // unique String gets created from az cli instructions
param logAnalyticsWorkspace string = '${uniqueString(resourceGroup().id)}la'


param sku string = 'S1' // The SKU of App Service Plan
param location string = resourceGroup().location


var appServicePlanName = toLower('AppServicePlan-${webAppName}')

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = { name: 'WebAppLog' }


resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
}
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  kind: 'app'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'UseOnlyInMemoryDatabase'
          value: 'true'
        }
      ]
    }
  }
}

/* resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
name: '${webAppName}-diagnostics'
scope: appService
properties: {
workspaceId: logAnalytics.id */

/* logs: [
  {
    category: 'AppServiceHTTPLogs'
    enabled: true
  }
  {
    category: 'AppServiceConsoleLogs'
    enabled: true
  }
  {
    category: 'AppServiceAppLogs'
    enabled: true
  }
  {
    category: 'AppServiceAuditLogs'
    enabled: true
  }
  {
    category: 'AppServicePlatformLogs'
    enabled: true
  }
]

metrics: [
  {
    category: 'AllMetrics'
    enabled: true
  }
]
}
}
*/
