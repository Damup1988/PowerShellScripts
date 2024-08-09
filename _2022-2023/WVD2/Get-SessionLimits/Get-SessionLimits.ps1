Connect-AzAccount

$subs = Get-Content -Path "C:\_bufer\_scripts\WVD2\Get-SessionLimits\subs.txt"

$poolsLimits = @()
foreach ($sub in $subs) {
    $currSub = Select-AzSubscription -SubscriptionId $sub
    $poolsLimits += Get-AzWvdHostPool | Select-Object Name,MaxSessionLimit
}

foreach ($data in $poolsLimits) {
    write-host "$($data.Name);$($data.MaxSessionLimit)"
}