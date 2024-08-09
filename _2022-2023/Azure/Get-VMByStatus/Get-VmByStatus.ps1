$subsId = $(Get-AzSubscription -TenantId 16a4d712-85ca-455c-bba0-139c059e16e3).Id

$vms = @()
foreach ($subId in $subsId) {
    Select-AzSubscription -SubscriptionId $subId

    $vms += Get-AzVM | Where-Object {$_.ProvisioningState -ne "Running" -and `
        $_.ProvisioningState -ne "Stopped (deallocated)" -and `
        $_.Location -eq "southeastasia" -and `
        $_.ProvisioningState -ne "Online"}
}