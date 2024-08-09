# connect az account
Connect-AzAccount
Select-AzSubscription -SubscriptionId ff8ea09d-a6a9-482a-a209-58f43068b627

$allDisks = Get-AzDisk | Where-Object {$_.DiskSizeGB -eq 512}

foreach ($disk in $allDisks) {
    $json = $disk | ConvertTo-Json
    $sku = ($json | ConvertFrom-Json | Select-Object sku).sku.name
    $tier = ($json | ConvertFrom-Json | Select-Object sku).sku.Tier
    if ($sku -eq "StandardSSD_LRS" -and $tier -eq "Standard") {
        $disk.Name
    }
}