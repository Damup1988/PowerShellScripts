$VNetName = ""
$rg = ""

$VNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $rg

foreach ($subnet in $vnet.Subnets) {
    Write-Host "Subnet: $($subnet.Name)"
    $nics = Get-AzNetworkInterface | Where-Object { $_.IpConfigurations.Subnet.Id -eq $subnet.Id }
    foreach ($nic in $nics) {
        $PIP = $nic.IpConfigurations.PublicIpAddress
        if ($null -ne $PIP.Id) {
            Write-Host "$($nic.Name) has PIP" -ForegroundColor Yellow
        }
    }
}

#to get all ipconfigs
#$result = Get-AzVirtualNetwork -Name $VNet.Name  -ResourceGroupName $ResourceGroupName -ExpandResource 'subnets/ipConfigurations'