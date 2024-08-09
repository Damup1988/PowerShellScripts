# get list of vms
Connect-AzAccount

$subId = "ff8ea09d-a6a9-482a-a209-58f43068b627"
$rg = "RG-SAS-PRD-VDI"

$vms = Get-AzVm -ResourceGroup $rg