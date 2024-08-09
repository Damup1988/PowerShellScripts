$subsId = $(Get-AzSubscription).Id

foreach ($sub in $subsId) {
    # $sub = "ff8ea09d-a6a9-482a-a209-58f43068b627"
    Set-AzContext -Subscription $sub
    $serviceApps = Get-AzWebApp
}