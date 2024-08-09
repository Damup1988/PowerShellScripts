param (
    [Parameter(Mandatory)]$subId,
    [Parameter(Mandatory)]$vmName,
    [Parameter(Mandatory)]$rg,
    [Parameter(Mandatory)]$vmSize,
    [Parameter(Mandatory)]$vnet,
    [Parameter(Mandatory)]$subnet,

    [Parameter(Mandatory)][object]$mytags
)

Connect-AzAccount
Select-AzSubscription -SubscriptionId $subId

$vnetRg = $(Get-AzVirtualNetwork -Name $vnet).ResourceGroupName

$bicep = "C:\_bufer\_scripts\Azure\Deploy-AzVM\template.bicep"

Write-Host "Enter password for new vm:" -ForegroundColor Yellow
$password = Read-Host -AsSecureString

New-AzResourceGroupDeployment `
    -Name "VMdeploy-$($vmName)-$(Get-Date -Format 'dd.MM.yyyy.hh.mm.ss')" `
    -ResourceGroupName $rg `
    -TemplateFile $bicep `
    -admin "dutyadmin" `
    -password $password `
    -vmName $vmName `
    -vmSize $vmSize `
    -vnet $vnet `
    -vnetRg $vnetRg `
    -subnet $subnet `
    -mytags $mytags