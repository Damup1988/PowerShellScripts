<# Convert a VM to a Spot VM
Based on sample script at https://docs.microsoft.com/en-us/azure/virtual-machines/windows/change-availability-set
NOTE:  Extensions will not be copied to new instance!!
#>

# Set variables to your specifics
$resourceGroup = "RG-EU-MAIN"
$vmName = "AZSPOTVM001"

# Get the details of the VM to be moved to the Availability Set
$originalVM = Get-AzVM `
	   -ResourceGroupName $resourceGroup `
	   -Name $vmName
 
# Create the basic configuration for the replacement VM. 
$newVM = New-AzVMConfig `
	   -VMName 'AZSPOTVM001converted' `
	   -VMSize 'Standard_D2as_v4' `
       -Priority "Regular" -MaxPrice -1

# Confgure OS Disk
Set-AzVMOSDisk `
	   -VM $newVM -CreateOption Attach `
	   -ManagedDiskId $originalVM.StorageProfile.OsDisk.ManagedDisk.Id `
	   -Name $originalVM.StorageProfile.OsDisk.Name 

if ($originalVM.OSProfile.WindowsConfiguration) {
    $newVM.StorageProfile.OsDisk.OsType="Windows" 
    } else {
    $newVM.StorageProfile.OsDisk.OsType="Linux"
    }  

# Add Data Disks
foreach ($disk in $originalVM.StorageProfile.DataDisks) { 
    Add-AzVMDataDisk -VM $newVM `
	   -Name $disk.Name `
	   -ManagedDiskId $disk.ManagedDisk.Id `
	   -Caching $disk.Caching `
	   -Lun $disk.Lun `
	   -DiskSizeInGB $disk.DiskSizeGB `
	   -CreateOption Attach
    }
    
# Add NIC(s) and keep the same NIC as primary
foreach ($nic in $originalVM.NetworkProfile.NetworkInterfaces) {	
	if ($nic.Primary -eq "True")
		{
    		Add-AzVMNetworkInterface `
       		-VM $newVM `
       		-Id $nic.Id -Primary
       		}
       	else
       		{
       		  Add-AzVMNetworkInterface `
      		  -VM $newVM `
      	 	  -Id $nic.Id 
                }
  	}

if ($originalVM.AvailabilitySetReference.Id) {
    #$newVM.AvailabilitySetReference=$originalVM.AvailabilitySetReference.Id
    echo "Warning: VM $originalVM.Name is in an availability set.  Spot VMs cannot run in availability sets."
    }

# Remove the original VM
Remove-AzVM -ResourceGroupName $resourceGroup -Name $vmName   

# Recreate the VM
New-AzVM `
	   -ResourceGroupName $resourceGroup `
	   -Location $originalVM.Location `
	   -VM $newVM `
	   -DisableBginfoExtension