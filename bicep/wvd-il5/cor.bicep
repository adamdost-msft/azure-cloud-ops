param resourcePrefix string
param objId string
param locationShortName string
param kvtSku string = 'premium'
param vmUserName string
@secure()
param vmPassword string

var kvtName = '${resourcePrefix}${locationShortName}KVT'
var rcvName = '${resourcePrefix}-${locationShortName}-RCV'
var logAName = '${resourcePrefix}-${locationShortName}-OMS'
var diagName = '${resourcePrefix}${locationShortName}DIAG'

resource kvt 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: replace(kvtName, '-', '')
  location: resourceGroup().location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: objId
        permissions: {
          keys: [
            'get'
            'list'
            'create'
            'delete'
            'import'
          ]
          secrets: [
            'list'
            'get'
            'set'
            'delete'
          ]
        }
      }
    ]
    sku: {
      name: kvtSku
      family: 'A'
    }
  }
}

resource recoveryServiceVault 'Microsoft.RecoveryServices/vaults@2021-01-01' = {
  name: rcvName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    
  }
}

resource byok 'Microsoft.KeyVault/vaults/keys@2021-04-01-preview' = {
  parent: kvt
  name: 'byok'
  properties: {
    attributes: {
      enabled: true
    }
    keyOps: [
      'encrypt'
      'decrypt'
      'sign'
      'verify'
    ]
    kty: 'RSA-HSM'
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource vmUserNameKvt 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'vmUserName'
  parent: kvt
  properties: {
    value: vmUserName
  }
}

resource vmUserPassKvt 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'vmPassword'
  parent: kvt
  properties: {
    value: vmPassword
  }
}

resource defaultBackup 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-10-01' = {
  name: '${resourcePrefix}-BKP-WVD-01'
  location: resourceGroup().location
  parent: recoveryServiceVault
  properties: {
    backupManagementType: 'AzureIaasVM'
  }
}


output logARefId string = logAnalyticsWorkspace.id
output kvtRefName string = kvt.name
output logAWorkSpaceKey string = listKeys(logAnalyticsWorkspace.id, '2015-11-01-preview').primarySharedKey
