param functionAppName string

param newAppSettings object

var currentAppSettings =  list(resourceId('Microsoft.Web/sites/config', functionAppName , 'appsettings'), '2022-03-01').properties



module updateFuncAppConfig 'function-app-config-child.bicep' = {
  name: 'updateFuncAppConfigChild'
  params: {
    functionAppName: functionAppName
    currentAppSettings: currentAppSettings
    newAppSettings: newAppSettings
  }
}
