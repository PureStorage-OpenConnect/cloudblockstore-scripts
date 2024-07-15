param functionAppName string

param currentAppSettings object
param newAppSettings object

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

resource functionAppConfigs 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: union(currentAppSettings,newAppSettings)
}
