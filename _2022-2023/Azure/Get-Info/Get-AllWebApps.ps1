$subs = Get-AzSubscription

foreach ($sub in $subs) {
    Select-AzSubscription -Name $sub.Name
    $webApps = Get-AzWebApp
    $webApps.Id
}