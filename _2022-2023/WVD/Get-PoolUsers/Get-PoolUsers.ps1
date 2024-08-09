# connect to wvd
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

$pools = $(Get-RdsHostPool -TenantName Az-VDI-SAS-Tenant).HostPoolName
$tenantName = "Az-VDI-SAS-Tenant"

$data = @()
foreach ($pool in $pools) {
    Write-Host "doing $pool" -ForegroundColor Yellow
    $appGroupName = (Get-RdsAppGroup `
        -TenantName $tenantName `
        -HostPoolName $pool `
        | Select-Object AppGroupName).AppGroupName
    $users = (Get-RdsAppGroupUser `
        -TenantName $tenantName `
        -HostPoolName $pool `
        -AppGroupName $appGroupName `
        | Select-Object UserPrincipalName).UserPrincipalName
    foreach ($user in $users) {
        $data += "$user;$pool"
    }
}

$data >> .\result.txt