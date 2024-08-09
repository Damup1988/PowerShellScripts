# connect to wvd
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

Get-RdsHostPool -TenantName Az-VDI-SAS-Tenant | `
    Format-Table HostPoolName,MaxSessionLimit | `
    Export-Csv -Delimiter ';' -Path "C:\_bufer\_scripts\WVD\data5.csv" -NoTypeInformation

$poolsLimits = Get-RdsHostPool -TenantName Az-VDI-SAS-Tenant

foreach ($pool in $poolsLimits) {
    Write-Host "$($pool.HostPoolName);$($pool.MaxSessionLimit)"
}