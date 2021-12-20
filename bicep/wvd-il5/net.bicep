param resourcePrefix string
param addressSpace string
param subnetArray array

var vnetName = '${resourcePrefix}-VNT-01'
var subnets = [for (sn, index) in subnetArray: {
  name: '${resourcePrefix}-${sn.name}'
  properties: {
    addressPrefix: sn.addressPrefix
  }
}]


resource priVnt 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: subnets
  }
}


output vnetName string = priVnt.name
