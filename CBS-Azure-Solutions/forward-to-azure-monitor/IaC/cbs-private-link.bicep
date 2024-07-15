param cbsSubscriptionId string
param cbsManagedRgName string
param cbsLocation string

param monitoringSubscriptionId string
param monitoringRgName string
param monitoringVnetName string
param monitoringLocation string

param loadBalancerName string
param loadBalancerFrontEndIpConfigurationName string = 'LoadBalancerFrontEnd0'

param privatelinkServiceName string = 'monitoring-cbs-PLS'
param privateEndpointName string = 'monitoring-cbs-PE'



module variables 'bicep-modules/variables.bicep' = {
  name: 'scriptVariables'
  params: {
  }
}

module privateLinkService 'bicep-modules/_private-link-service.bicep' = {
  name: 'privateLinkService'
  params: {
    loadbalancerId: resourceId(cbsSubscriptionId, cbsManagedRgName, 'Microsoft.Network/loadBalancers', loadBalancerName)
    location: cbsLocation
    loadBalancerFrontEndIpConfigurationResourceId: resourceId(cbsSubscriptionId, cbsManagedRgName, 'Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, loadBalancerFrontEndIpConfigurationName)
    privatelinkServiceName: privatelinkServiceName
  }
  scope: resourceGroup(monitoringSubscriptionId, monitoringRgName)
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: privateEndpointName
  location: monitoringLocation
  properties: {
    subnet: {
      id: resourceId(monitoringSubscriptionId, monitoringRgName,'Microsoft.Network/virtualNetworks/subnets',  monitoringVnetName, variables.outputs.subnetNameForPrivateEndpoints)
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkService.outputs.id
        }
      }
    ]
  }
}
module networkInterface 'bicep-modules/_nic-nested.bicep' = {
  name: 'nested'
  params: {
    nicName: last(split(privateEndpoint.properties.networkInterfaces[0].id, '/'))
  }
}

output cbsIpAddressInMonitoringVnet string = networkInterface.outputs.ip
