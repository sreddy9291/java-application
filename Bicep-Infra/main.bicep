targetScope = 'subscription'

@description('Primary deployment location (standardized to East US)')
param location string = 'eastus'

@description('Environment short name: dev, qa, uat, prod')
@allowed([
  'dev'
  'qa'
  'uat'
  'prod'
])
param environment string

@description('Resource group name. Convention: RG-AG-<environment>')
param resourceGroupName string

@description('Tags applied to all resources')
param tags object = {}

@description('Array of Logic App Standard definitions for this environment')
param logicApps array

@description('Shared virtual network name for Logic App integration')
param vnetName string

@description('Subnet name delegated for Logic App integration')
param integrationSubnetName string

@description('Private endpoint subnet name')
param privateEndpointSubnetName string

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string

@description('Key Vault name for secrets and references')
param keyVaultName string

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module logicAppModules 'modules/logic-app-standard.bicep' = [for app in logicApps: {
  name: 'la-${environment}-${app.name}'
  scope: rg
  params: {
    location: location
    environment: environment
    logicAppName: app.name
    appServicePlanName: app.appServicePlanName
    storageAccountName: app.storageAccountName
    appInsightsName: app.appInsightsName
    skuName: app.skuName
    workerSize: app.workerSize
    workerCount: app.workerCount
    vnetName: vnetName
    integrationSubnetName: integrationSubnetName
    privateEndpointSubnetName: privateEndpointSubnetName
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    tags: union(tags, app.tags ?? {})
  }
}]
