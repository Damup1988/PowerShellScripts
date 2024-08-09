$allVMs = Get-Content -Path "C:\_bufer\_scripts\Azure\Get-NetworkInfoForVMs\VMs.txt"

foreach ($vm in $allVMs) {
    $vm = Get-AzVm -Name $vm
    $vmName = $vm.Name
    $nic = ($vm.NetworkProfile.NetworkInterfaces.id).Split('/')[-1]
    $vmnicinfo = Get-AzNetworkInterface -Name $nic
    $vnet = (($vmnicinfo.IpConfigurations.subnet.id).Split('/'))[-3]
    $subnet = (($vmnicinfo.IpConfigurations.subnet.id).Split('/'))[-1]
    Write-Host "$vmName - $vnet - $subnet" -ForeGroundColor Yellow
}