$subs = Get-AzSubscription
$tagName = ""
$tagValue = ""
$tagValue2 = ""

foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub.Id

    $resourcesWithTags = Get-AzResource | Where-Object {$_.Tags -ne $null}
    $resources = $resourcesWithTags | Where-Object {$_.Tags[$tagName] -eq $tagValue}
    $resources | Format-Table
}