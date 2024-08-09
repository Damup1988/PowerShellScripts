# connect to wvd
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

Add-RdsAppGroupUser `
    -TenantName Az-VDI-SAS-Tenant `
    -HostPoolName AZ-S3D-V13-2-WVD `
    -AppGroupName "Desktop Application Group" `
    -UserPrincipalName $user

$users = Get-Content -Path "C:\_bufer\_scripts\WVD\users.txt"

foreach ($user in $users) {
    Add-RdsAppGroupUser `
    -TenantName Az-VDI-SAS-Tenant `
    -HostPoolName AZ-S3D-V13-2-WVD `
    -AppGroupName "Desktop Application Group" `
    -UserPrincipalName $user
}