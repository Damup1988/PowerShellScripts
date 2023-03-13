# connect az account
Connect-AzAccount

$allDisks = Get-AzDisk | Where-Object {$_.DiskSizeGB -eq 256}

foreach ($disk in $allDisks) {
    $json = $disk | ConvertTo-Json
    $sku = ($json | ConvertFrom-Json | Select-Object sku).sku.name
    $tier = ($json | ConvertFrom-Json | Select-Object sku).sku.Tier
    if ($sku -eq "StandardSSD_LRS" -and $tier -eq "Standard") {
        $disk.Name
    }
}