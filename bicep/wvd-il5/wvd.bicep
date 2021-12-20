param resourcePrefix string
param hostPoolToken string
param logARefId string

var hostPoolName = '${resourcePrefix}-HP-01'
var hostPoolFriendlyName = '${resourcePrefix}-HP-FND-01'
var appGroupFriendlyName = '${resourcePrefix}-AG-FND-01'
var appGroupName = '${resourcePrefix}-AG-01'
var workSpaceName = '${resourcePrefix}-WS-01'
var workSpaceFriendlyName = '${resourcePrefix}-WS-FND-01'
var diagLogName = '${resourcePrefix}-DIAG-01'

resource hp 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: hostPoolName
  location: resourceGroup().location
  properties: {
    friendlyName: hostPoolFriendlyName
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
    registrationInfo: {
      token: hostPoolToken
      registrationTokenOperation: 'None'
      expirationTime: '2022-01-01T00:00:00Z'
    }
    customRdpProperty: 'autoreconnection enabled:i:1;bandwidthautodetect:i:1;audiocapturemode:i:1;drivestoredirect:s:;redirectclipboard:i:0;redirectsmartcards:i:1;usbdevicestoredirect:s:'
  }
}

resource ag 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: appGroupName
  location: resourceGroup().location
  properties: {
    friendlyName: appGroupFriendlyName
    applicationGroupType: 'Desktop'
    hostPoolArmPath: hp.id
  }
}

resource ws 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: workSpaceName
  location: resourceGroup().location
  properties: {
    friendlyName: workSpaceFriendlyName
    applicationGroupReferences: [
      ag.id
    ]
  }
}

resource diagLogsWs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagLogName
  scope: ws
  properties: {
    workspaceId: logARefId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
  }
}

resource diagLogsHp 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagLogName
  scope: hp
  properties: {
    workspaceId: logARefId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Connection'
        enabled: true
      }
      {
        category: 'HostRegistration'
        enabled: true
      }
      {
        category: 'AgentHealthStatus'
        enabled: true
      }
    ]
  }
}

resource diagLogsAg 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagLogName
  scope: ag
  properties: {
    workspaceId: logARefId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
    ]
  }
}

output hpName string = hp.name
