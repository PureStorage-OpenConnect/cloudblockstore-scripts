
/*
Deployment target scope
*/
targetScope = 'resourceGroup'


/*
Parameters
*/

@description('Location where Function app will be deployed. Defaults to resource group location.')
param location string

@description('''
Name for virtual network, used by CBS deployment.
''')
param monitoringVnetName string

param adminUserPrincipalId string

@secure()
param cbsApiKey string

param myIpAddress string


module variables 'bicep-modules/variables.bicep' = {
  name: 'scriptVariables'
  params: {
  }
}

resource monitoringVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: monitoringVnetName
}

resource monitoringVnetSubnetForFunctionApp 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: variables.outputs.subnetNameForFunctionApp
  parent: monitoringVnet
}
resource monitoringVnetSubnetForPrivateEndpoints 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: variables.outputs.subnetNameForPrivateEndpoints
  parent: monitoringVnet
}


module monitoringFunctionApp 'bicep-modules/function-app.bicep' = {
  name: 'deployFunctionApp'
  params: {
    location: location
    runtime: 'dotnet-isolated'
    vnetSubnetId: monitoringVnetSubnetForFunctionApp.id
    appName: variables.outputs.monitoringFunctionAppName
    storageAccountType: 'Standard_LRS'
  }
}


module monitoringFunctionAppRoleAssignment 'bicep-modules/role-assignment.bicep' = {
  name: 'deployFunctionAppRoleAssignment'
  params: {
    UAIPrincipalId: monitoringFunctionApp.outputs.functionAppSystemIdentityId
    functionAppName: variables.outputs.monitoringFunctionAppName
    roleDefinitionId: variables.outputs.monitoringPublisherRoleId
    principalType: 'ServicePrincipal'
  }
}


module keyvaultDeployment 'bicep-modules/key-vault.bicep' = {
  name: 'deployKeyVault'
  params: {
    principalId:monitoringFunctionApp.outputs.functionAppSystemIdentityId
    cbsApiKey: cbsApiKey
    keyvaultName: variables.outputs.keyVaultName
    keyvaultPleName: variables.outputs.keyVaultPrivateEndpointName
    virtualNetworkId: monitoringVnet.id
    subnetId: monitoringVnetSubnetForPrivateEndpoints.id
    location: location
    adminUserPrincipalId: adminUserPrincipalId
    myIpAddress: myIpAddress
  }
}


var newAppSettings = {
  keyVaultUri: keyvaultDeployment.outputs.keyvaultUri
}

module updateFuncAppConfigForKv 'bicep-modules/function-app-config-wrapper.bicep' = {
  name: 'updateFuncAppConfigWrapper'
  params: {
    functionAppName: variables.outputs.monitoringFunctionAppName
    newAppSettings: newAppSettings
  }
}


//Outputs, used in subsequents steps of the deployment scripts
output functionAppName string = monitoringFunctionApp.outputs.name
output functionAppId string = monitoringFunctionApp.outputs.id
