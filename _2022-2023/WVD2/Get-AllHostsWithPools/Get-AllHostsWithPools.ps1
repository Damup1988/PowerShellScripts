$subs = Get-Content -Path "C:\Users\damup1988\OneDrive - Petrofac\_bufer\_scripts\WVD2\Get-AllHostsWithPools\subs.txt"

$data = @()
foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub
    $pools = Get-AzWvdHostPool
    foreach ($pool in $pools) {
        $poolName = $pool.Name
        $rg = $Id.Split('/')[4]
        $hosts = $(Get-AzWvdSessionHost -HostPoolName $poolName -ResourceGroupName $rg).Name
        foreach ($vm in $hosts) {
            $data += "$($vm.Split('/')[1].Split('.')[0]);$poolName"
        }
    }
}