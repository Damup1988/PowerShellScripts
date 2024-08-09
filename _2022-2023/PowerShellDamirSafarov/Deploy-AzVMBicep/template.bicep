@description('admin user name')
param admin string

@description('admin password')
@minLength(12)
@secure()
param password string

@description('vm name')
param vmName string
@description('vm size')
param vmSize string
@description('vnet name')
param vnet string
@description('vnet name')
param vnetRg string
@description('subnet name')
param subnet string
@description('tags')
param mytags object


param osVersion string = '2022-datacenter-azure-edition'
param location string = resourceGroup().location
param osDiskType string = 'StandardSSD_LRS'
param osDiskDeleteOption string = 'Delete'
param nicDeleteOption string = 'Detach'
param patchMode string = 'Manual'
param enableHotpatching bool = false

var nicName = '${vmName}-NIC'

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(vnetRg, 'Microsoft.Network/virtualNetworks/subnets', vnet, subnet)
          }
        }
      }
    ]
  }
  tags: mytags
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: admin
      adminPassword: password
      windowsConfiguration: {
        enableAutomaticUpdates: false
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: enableHotpatching
          patchMode: patchMode
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: osDiskDeleteOption
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: nicDeleteOption
          }
        }
      ]
    }
    licenseType: 'Windows_Server'
  }
  tags: mytags
}
