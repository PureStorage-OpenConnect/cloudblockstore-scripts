
/*
Local variables
*/
var uniquePostfix = uniqueString(resourceGroup().id)


// variables for monitoring vNET
output subnetNameForFunctionApp string = 'function'
output subnetNameForPrivateEndpoints string = 'private-endpoints'

output addressPrefixes array = [ '10.0.0.0/16' ]

output subnetForFunctionAppAddressPrefix string = '10.0.1.0/24'
output subnetForPrivateEndpointsAddressPrefix string = '10.0.2.0/24'


// variables for FunctionApp
output monitoringFunctionAppName string = 'cbsmonitoring${uniqueString(resourceGroup().id)}-funcapp'
output monitoringPublisherRoleId string = '/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb'


var keyVaultName = 'kv-for-funcapp'
output keyVaultName string = keyVaultName
output keyVaultPrivateEndpointName string = '${keyVaultName}-pe'

output uniquePostfix string = uniquePostfix

