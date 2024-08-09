param (
    [Parameter(Mandatory)]$subId,
    [Parameter(Mandatory)]$vmName,
    [Parameter(Mandatory)]$rg,
    [Parameter(Mandatory)]$vmSize,
    [Parameter(Mandatory)]$osdisk,
    [Parameter(Mandatory)]$vnet,
    [Parameter(Mandatory)]$subnet,
    [Parameter(Mandatory)]$image,

    [Parameter(Mandatory)][object]$mytags
)

Connect-AzAccount
Select-AzSubscription -SubscriptionId $subId

$vnetRg = $(Get-AzVirtualNetwork -Name $vnet).ResourceGroupName

$bicep = "C:\_bufer\_scripts\Azure\Deploy-AzVM\templateUltraDisk.bicep"

Write-Host "Enter password for new vm:" -ForegroundColor Yellow
$password = Read-Host -AsSecureString

<#$vmDeployJob = Start-Job -ScriptBlock $scriptBlock -arg {
    New-AzResourceGroupDeployment `
    -Name "VMDeploy-$($vmName)-$(Get-Date -Format 'dd.MM.yyyy.hh.mm.ss')" `
    -ResourceGroupName $rg `
    -TemplateFile $bicep `
    -admin "dutyadmin" `
    -password $password `
    -vmName $vmName `
    -vmSize $vmSize `
    -vnet $vnet `
    -vnetRg $vnetRg `
    -subnet $subnet `
    -mytags $mytags `
    -osdisk $osdisk `
    -image $image
}#>

New-AzResourceGroupDeployment `
    -Name "VMDeploy-$($vmName)-$(Get-Date -Format 'dd.MM.yyyy.hh.mm.ss')" `
    -ResourceGroupName $rg `
    -TemplateFile $bicep `
    -admin "dutyadmin" `
    -password $password `
    -vmName $vmName `
    -vmSize $vmSize `
    -vnet $vnet `
    -vnetRg $vnetRg `
    -subnet $subnet `
    -mytags $mytags `
    -osdisk $osdisk `
    -image $image

$nic = Get-AzNetworkInterface -ResourceGroupName $rg -Name "$vmName-NIC"
$nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"