param vNetName string

param location string

module variables 'bicep-modules/variables.bicep' = {
  name: 'scriptVariables'
  params: {
  }
}


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: variables.outputs.addressPrefixes
    }
    subnets: [
      {
        name: variables.outputs.subnetNameForFunctionApp
        properties: {
          addressPrefix: variables.outputs.subnetForFunctionAppAddressPrefix
          delegations: [
            {
              name: 'Microsoft.Web/serverfarms'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
      {
        name: variables.outputs.subnetNameForPrivateEndpoints
        properties: {
          addressPrefix: variables.outputs.subnetForPrivateEndpointsAddressPrefix
        }
      }
    ]
  }
}

output virtualNetworkId string = virtualNetwork.id
output virtualNetworkName string = virtualNetwork.name
