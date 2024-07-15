param funcAppName string

param monitoringSubscriptionId string
param monitoringRgName string
param monitoringLocation string

param cbsIpAddressInMonitoringVnet string

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: funcAppName
}


module updateFuncAppConfig 'bicep-modules/function-app-config-wrapper.bicep' = {
  name: 'updateFuncAppConfigPrivateLinkWrapper'
  params: {
    functionAppName: funcAppName
    newAppSettings: {
      cbsIpAddressInMonitoringVnet: cbsIpAddressInMonitoringVnet
      functionAppLocation: monitoringLocation
      funcAppId: functionApp.id
      WEBSITE_RUN_FROM_PACKAGE: 1
    }
  }
  scope: resourceGroup(monitoringSubscriptionId, monitoringRgName)
}
