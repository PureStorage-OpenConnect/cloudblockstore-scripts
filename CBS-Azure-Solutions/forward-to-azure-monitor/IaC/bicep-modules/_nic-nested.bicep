param nicName string

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-08-01' existing = {
  name: nicName
}

output ip string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

