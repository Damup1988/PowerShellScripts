@description('admin user name')
param admin string

@description('admin password')
@minLength(12)
@secure()
param password string

@description('vm name')
param vmName string

@description('vm size')
@allowed(
  [
    'Standard_B1ms'
  ]
)
param vmSize string

param pubIpName string = '${vmName}-pubIpAddress'
param pubIpType string = 'Dynamic'
param pubIpSKU string = 'Basic'
param osVersion string = '2022-datacenter-azure-edition'
param location string = resourceGroup().location
param diagStorageAccName string = 'rgeun001diag'
param pipDeleteOption string = 'Detach'
param osDiskType string = 'StandardSSD_LRS'
param osDiskDeleteOption string = 'Delete'
param nicDeleteOption string = 'Detach'
param patchMode string = 'Manual'
param enableHotpatching bool = false
param autoShutdownStatus string = 'Enabled'
param autoShutdownTime string = '19:00'
param autoShutdownTimeZone string = 'UTC'
param autoShutdownNotificationStatus string = 'Enabled'
param autoShutdownNotificationLocale string = 'en'
param autoShutdownNotificationEmail string = 'Damir_Safarov@epam.com'

var nicName = '${vmName}-NIC'
var vnet = 'VNet-EUN-001'
var subnet = 'default'

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: pubIpName
  location: location
  sku: {
    name: pubIpSKU
  }
  properties: {
    publicIPAllocationMethod: pubIpType    
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
            properties: {
              deleteOption: pipDeleteOption
            }
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, subnet)
          }
        }
      }
    ]
  }
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'https://${diagStorageAccName}.blob.core.windows.net/'
      }
    }
  }
  tags: {
    CreatetBy: 'damir.safarov'
  }
}

resource shutdown_computevm_virtualMachine 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: autoShutdownStatus
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: autoShutdownTimeZone
    targetResourceId: vm.id
    notificationSettings: {
      status: autoShutdownNotificationStatus
      notificationLocale: autoShutdownNotificationLocale
      timeInMinutes: 30
      emailRecipient: autoShutdownNotificationEmail
    }
  }
  tags: {
    CreatetBy: 'damir.safarov'
  }
}

output message string = 'DONE'
