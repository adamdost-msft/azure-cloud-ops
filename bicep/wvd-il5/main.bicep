param resourcePrefix string
param addressSpace string
param location string
param subnetArray array
param locationShortName string
param objId string
param vmUserName string
@secure()
param vmPassword string
param timeStamp string = utcNow()
param nicArray array
param hostPoolToken string

var netRgpName = '${resourcePrefix}-NET-RGP-01'
var corRgpName = '${resourcePrefix}-COR-RGP-01'
var appRgpName = '${resourcePrefix}-APP-RGP-01'


targetScope = 'subscription'

resource netRgp 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: netRgpName
  location: location
}

resource corRgp 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: corRgpName
  location: location
}

resource appRgp 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appRgpName
  location: location
}
module deployNet 'net.bicep' = {
  scope: netRgp
  name: 'net-deploy-${timeStamp}'
  params: {
    resourcePrefix: resourcePrefix
    addressSpace: addressSpace
    subnetArray: subnetArray
  }
}
module deployCor 'cor.bicep' = {
  scope: corRgp
  name: 'cor-deploy-${timeStamp}'
  params: {
    resourcePrefix: resourcePrefix
    locationShortName: locationShortName
    objId: objId
    vmPassword: vmPassword
    vmUserName: vmUserName
  }
}


module deployWvd 'wvd.bicep' = {
  scope: appRgp
  name: 'wvd-deploy-${timeStamp}'
  params: {
    resourcePrefix: resourcePrefix
    hostPoolToken: hostPoolToken
    logARefId: deployCor.outputs.logARefId
  }
}

module deployVM 'vm.bicep' = {
  scope: appRgp
  name: 'vm-deploy-${timeStamp}'
  params: {
    resourcePrefix: resourcePrefix
    vmPassword: vmPassword
    vmUserName: vmUserName
    netRgpName: netRgpName
    nicArray: nicArray
    vnetNameRef: deployNet.outputs.vnetName
    hostName: deployWvd.outputs.hpName
    hostPoolToken: hostPoolToken
    logARefId: deployCor.outputs.logARefId
    logAWorkSpaceKey: deployCor.outputs.logAWorkSpaceKey
  }
}

//az deployment sub create --location 'usgovvirginia' --template-file main.bicep --parameters params.json
