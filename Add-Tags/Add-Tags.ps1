$tags = @{}
$tags += @{ "AssignedTo" = "Srinivasa Degala"}
$tags += @{ "ApplicationName" = "S3D"}
$tags += @{ "ApplicationOwner" = "Srinivasa Degala"}
$tags += @{ "ITVertical" = "Engg Apps"}
$tags += @{ "Environment" = "PROD"}
$tags += @{ "Change" = "CHG0047550"}
$tags += @{ "CreatedBy" = "virp_damrov@petrofac.com"}

$rg = ""
$subId = ""
$resName = ""

Select-AzSubscription -SubscriptionId $subId
Set-AzResource `
    -ResourceGroupName $rg `
    -ResourceName $resName `
    -ResourceType "Microsoft.Compute/snapshots" `
    -Tag $tags