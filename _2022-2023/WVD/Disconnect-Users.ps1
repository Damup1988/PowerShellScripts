# connect to wvd
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

$hostPoolName = "AZ-S3D-V13-WVD"
$tenantName = "Az-VDI-SAS-Tenant"
$sessionHostName = "VDI-AZ-S3D-3a94"
$userName = ""
Get-RdsUserSession `
    -HostPoolName $hostPoolName `
    -TenantName $tenantName `
    | Where-Object {$_.SessionHostName -like "$($sessionHostName)*"} -and $_.AdUserName -like "*$($userName)" |`
    Invoke-RdsUserSessionLogoff -force