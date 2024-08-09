$subsId = $(Get-AzSubscription).Id

$count = 0
foreach ($sub in $subsId) {
    $count++
    # $sub = "ff8ea09d-a6a9-482a-a209-58f43068b627"
    Set-AzContext -Subscription $sub
    $removedWebApps = $(Get-AzDeletedWebApp).Name
    $removedWebApps >> "data_$($count).txt"
}