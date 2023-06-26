@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'
param applicationName string = 'wv-todo'
@allowed([
  'F1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1V3'
  'P2V3'
  'P3V3'
])
param sku string = 'F1'
param instance int = 1
param location string = resourceGroup().location
param corsOrigins array = ['*']

var planName = '${applicationName}-${environmentName}-plan'
var appName = '${applicationName}-${environmentName}'
var family = substring(sku, 0, 1)
var size = substring(sku, 1, 1)
var newSku = environmentName == 'dev' ? 'F1' : sku
var tier = family == 'B' ? 'Basic' : family == 'S' ? 'Standard' : family == 'P' ? 'Premium' : 'Free'

// Create a new app service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: planName
  location: location
  sku: {
    name: newSku
    tier: tier
    size: size
    family: family
    capacity: instance
  }
  kind: 'app'
}

// Create a new web app
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: 'v7.0'
      cors: {
        allowedOrigins: corsOrigins
      }
      http20Enabled: true
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Create a deployment slot
resource slot 'Microsoft.Web/sites/slots@2022-09-01' = if (environmentName == 'prod') {
  parent: webApp
  name: 'preprod'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: 'v7.0'
      cors: {
        allowedOrigins: corsOrigins
      }
      http20Enabled: true
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}
