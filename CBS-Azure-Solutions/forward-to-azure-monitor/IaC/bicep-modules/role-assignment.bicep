param UAIPrincipalId string

@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'

param roleDefinitionId string

param functionAppName string

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing =  {
  name: functionAppName
}


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, UAIPrincipalId, roleDefinitionId)
  properties: {
    principalId: UAIPrincipalId
    principalType: principalType
    roleDefinitionId: roleDefinitionId
  }
  scope: functionApp
}

