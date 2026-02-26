targetScope = 'resourceGroup'

@description('Azure region')
param location string = 'eastus'

@description('Environment name')
param environment string

@description('Logic App Standard site name')
param logicAppName string

@description('App Service plan name used by Logic App Standard')
param appServicePlanName string

@description('Storage account name for workflow runtime')
param storageAccountName string

@description('Application Insights name')
param appInsightsName string

@description('App Service plan SKU name. Basic baseline uses WS1')
param skuName string = 'WS1'

@description('Worker size (0 = small, 1 = medium, 2 = large)')
param workerSize int = 0

@description('Worker count')
param workerCount int = 1

@description('Existing VNet name used for integration and private endpoints')
param vnetName string

@description('Existing subnet delegated for Logic App VNet integration')
param integrationSubnetName string

@description('Existing subnet for private endpoint')
param privateEndpointSubnetName string

@description('Existing Key Vault name for app settings/secret references')
param keyVaultName string

@description('Log Analytics workspace name for monitoring')
param logAnalyticsWorkspaceName string

@description('Resource tags')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource integrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: integrationSubnetName
  parent: vnet
}

resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: privateEndpointSubnetName
  parent: vnet
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: tags
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: integrationSubnet.id
          action: 'Allow'
        }
      ]
      ipRules: []
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law.id
    IngestionMode: 'LogAnalytics'
  }
}

resource servicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'elastic'
  sku: {
    name: skuName
    tier: 'WorkflowStandard'
    size: skuName
    capacity: workerCount
  }
  tags: tags
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    workerSize: workerSize
    workerSizeId: workerSize
  }
}

resource logicApp 'Microsoft.Web/sites@2023-12-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    serverFarmId: servicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: integrationSubnet.id
    siteConfig: {
      appSettings: [
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'WORKFLOWS_TENANT_ID'
          value: subscription().tenantId
        }
        {
          name: 'KeyVaultUri'
          value: keyVault.properties.vaultUri
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      publicNetworkAccess: 'Disabled'
    }
  }
}

resource logicAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'pe-${logicAppName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: peSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-${logicAppName}'
        properties: {
          privateLinkServiceId: logicApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource metricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'ma-${logicAppName}-servererrors'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert on Logic App HTTP 5xx count'
    severity: 2
    enabled: true
    scopes: [
      logicApp.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'http5xx'
          metricName: 'Http5xx'
          metricNamespace: 'microsoft.web/sites'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
  }
}

output logicAppResourceId string = logicApp.id
