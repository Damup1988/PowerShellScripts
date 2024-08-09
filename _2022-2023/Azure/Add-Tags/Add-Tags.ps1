# microsoft.compute/virtualmachines
# Microsoft.Compute/snapshots
# Microsoft.Automation/automationAccounts
# Microsoft.Compute/disks
# Microsoft.Network/networkInterfaces

$tags = @{}
$tags += @{ "AssignedTo" = "Srinivasa Degala"}
$tags += @{ "ApplicationName" = "E3D"}
$tags += @{ "ApplicationOwner" = "Srinivasa Degala"}
$tags += @{ "ITVertical" = "Cots Engg"}
$tags += @{ "Environment" = "Prod"}
$tags += @{ "Change" = "CHG0048818"}
$tags += @{ "CreatedBy" = "virp_damrov@petrofac.com"}

$rg = "RG-INC-PRD-EngApp-01"
$subId = "41f8638b-523d-468c-8809-50dfc02bc356"
$resName = "APP001PRDINCAZR_DataDisk_5"

#Select-AzSubscription -SubscriptionId $subId
Set-AzResource `
    -ResourceGroupName $rg `
    -ResourceName $resName `
    -ResourceType "Microsoft.Compute/disks" `
    -Tag $tags `
    -Force