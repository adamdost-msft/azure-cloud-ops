param resourcePrefix string
param vnetNameRef string
param netRgpName string
param nicArray array
param vmUserName string
param vmPassword string
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'
param hostName string
param hostPoolToken string
param logARefId string
param logAWorkSpaceKey string


var wvdSessionHostNum = length(nicArray)
var vmSize = 'Standard_D2_v3'

resource vnetRef 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetNameRef
  scope: resourceGroup(netRgpName)
}

resource avdNicObj 'Microsoft.Network/networkInterfaces@2021-05-01' = [for data in nicArray: {
  name: '${resourcePrefix}-${data.name}'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: '${resourcePrefix}-${data.name}-IPC-01'
        properties: {
          privateIPAddress: data.privateIP
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: vnetRef.properties.subnets[0].id // SVC Subnet is set to 0 always
          }
        }
      }
    ]
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = [for i in range(1, wvdSessionHostNum): {
  name: '${resourcePrefix}-WVD-${i}'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${resourcePrefix}-VM-${i}'
      adminUsername: vmUserName
      adminPassword: vmPassword
    }
    storageProfile: {
      imageReference:  {
          publisher: 'MicrosoftWindowsDesktop'
          offer: 'Windows-10'
          sku: '20h1-ent'
          version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        name: '${resourcePrefix}-VM-${i}-OS-DISK-01'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: avdNicObj[(i-1)].id
        }
      ]
    }
  }
  dependsOn: [
    avdNicObj
  ]
}]


resource wvdDsc 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(1, wvdSessionHostNum): {
  name: '${resourcePrefix}-WVD-${i}/Microsoft.PowerShell.DSC'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostName
        registrationInfoToken: hostPoolToken
        aadJoin: true
      }
    }
  }
  dependsOn: [
    vm
  ]
}]

resource vm_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(1, wvdSessionHostNum): {
  name: '${resourcePrefix}-WVD-${i}/AADLoginForWindows'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    wvdDsc
  ]
}]
/*
resource omsLogAnalytics 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(1, wvdSessionHostNum): {
  name: '${resourcePrefix}-WVD-${i}/OMSExtension'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      logAnalyticsWorkspaceResourceId: logARefId
    }
    protectedSettings: {
      workspaceKey: logAWorkSpaceKey
    }
  }
  dependsOn: [
    vm_AADLoginForWindows
  ]
}]
*/
