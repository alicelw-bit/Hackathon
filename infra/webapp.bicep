@description('Web app name')
param webAppName string

@description('Location for all resources (should match the RG location)')
param location string = resourceGroup().location

@description('App Service plan SKU name (F1, B1, S1, P1v2, etc.)')
param skuName string = 'B1' 
@description('App Service plan SKU tier (Free, Basic, Standard, PremiumV2, etc.)')
param skuTier string = 'Basic'

@description('Capacity/instances for the plan')
param skuCapacity int = 1

@description('Existing Log Analytics workspace resource group name')
param workspaceResourceGroup string = 'Hackathon'  

@description('Existing Log Analytics workspace name')
param workspaceName string = 'WebAppLog'          
@description('Linux runtime for .NET 8')
param linuxFxVersion string = 'DOTNETCORE|8.0'

// Reference the existing workspace in the specified RG
resource laRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: workspaceResourceGroup
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspaceName
  scope: laRg
}

var appServicePlanName = toLower('AppServicePlan-${webAppName}')

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: skuName
    tier: skuTier
    size: skuName
    capacity: skuCapacity
  }
  properties: {
    reserved: true // Linux
  }
}

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
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

// Attach diagnostics to the web app and send to the workspace
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webAppName}-diagnostics'
  scope: appService
  properties: {
    workspaceId: logAnalytics.id
    logs: [
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
