$subs = Get-AzSubscription
$tagName = "AssignedTo"
$tagValue = "Navaneethakrishnan Karuppiah"
$tagValue2 = "navaneethakrishnan.k@petrofac.com"

foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub.Id

    $resourcesWithTags = Get-AzResource | Where-Object {$_.Tags -ne $null}
    $resources = $resourcesWithTags | Where-Object {$_.Tags[$tagName] -eq $tagValue}
    $resources | Format-Table
}