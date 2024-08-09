# connect to wvd
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

Remove-RdsAppGroupUser `
    -TenantName Az-VDI-SAS-Tenant `
    -HostPoolName AZ-S3D-V13-2-WVD `
    -AppGroupName "Desktop Application Group" `
    -UserPrincipalName $user

foreach ($user in $users) {
    Add-RdsAppGroupUser `
    -TenantName Az-VDI-SAS-Tenant `
    -HostPoolName AZ-S3D-V13-2-WVD `
    -AppGroupName "Desktop Application Group" `
    -UserPrincipalName $user
}