$subs = Get-AzSubscription
$usRegions = Get-Content -Path "C:\_bufer\_scripts\Azure\Get-ResourcesByRegion\usregions.txt"

$resources = @()
foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub.Id
    $resources += Get-AzResource | Where-Object {$usRegions -contains $_.Location}
}

$resources | Export-Csv -Path .\azusreport2.csv