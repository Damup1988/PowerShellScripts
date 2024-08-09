Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

$allV1Pools = (Get-RdsHostPool -TenantName Az-VDI-SAS-Tenant).HostPoolName
$allHosts = @()
foreach ($pool in $allV1Pools) {
    $hostsNames = (Get-RdsSessionHost -TenantName "Az-VDI-SAS-Tenant" -HostPoolName $pool).SessionHostName
    foreach ($vm in $hostsNames) {
        $allHosts += "$pool;$($vm.Split('.')[0])"
    }
}