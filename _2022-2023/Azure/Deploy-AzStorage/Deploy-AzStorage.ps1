param (
  [Parameter(Mandatory)]$subId,
  [Parameter(Mandatory)]$saName,
  [Parameter(Mandatory)]$rg,
  [Parameter(Mandatory)]$saSKU,
  [Parameter(Mandatory)]$vnet,
  [Parameter(Mandatory)]$subnet,

  [Parameter(Mandatory)][object]$mytags
)

Connect-AzAccount
Select-AzSubscription -SubscriptionId $subId

$bicep = "C:\_bufer\_scripts\Azure\Deploy-AzStorage\template.bicep"

New-AzResourceGroupDeployment `
    -Name "SaDeploy-$($saName)-$(Get-Date -Format 'dd.MM.yyyy.hh.mm.ss')" `
    -ResourceGroupName $rg `
    -TemplateFile $bicep `
    -vmName $saName `
    -vmSize $saSKU `
    -vnet $vnet `
    -vnetRg $vnetRg `
    -subnet $subnet `
    -mytags $mytags