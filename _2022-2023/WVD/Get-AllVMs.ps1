Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

$allV1Pools = (Get-RdsHostPool -TenantName Az-VDI-SAS-Tenant).HostPoolName
$allHosts = foreach ($pool in $allV1Pools) {$(Get-RdsSessionHost -TenantName "Az-VDI-SAS-Tenant" -HostPoolName $pool).SessionHostName}
$allVMs = foreach ($vm in $allHosts) {
    $hostName = $vm.Split('.')[0]
    $hostName
}
$allVMs