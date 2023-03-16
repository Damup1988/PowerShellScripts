# connect az account
Connect-AzAccount

$subs = Get-AzSubscription

foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub.Id
    $allDisks = Get-AzDisk | Where-Object {$_.DiskSizeGB -gt 1024}

    foreach ($disk in $allDisks) {
        $json = $disk | ConvertTo-Json
        $sku = ($json | ConvertFrom-Json | Select-Object sku).sku.name
        $tier = ($json | ConvertFrom-Json | Select-Object sku).sku.Tier
        if ($sku -eq "UltraSSD_LRS" -and $tier -eq "Ultra") {
            $disk.Name
        }
    }
}