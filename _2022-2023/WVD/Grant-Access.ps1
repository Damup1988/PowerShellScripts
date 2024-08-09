# Connect to a tenant
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

# Get all roles
Get-RdsRoleDefinition | Select-Object RoleDefinitionName,Description

# Grant an access
$virp_account = "virp_sriraj@petrofac.com"
New-RdsRoleAssignment `
    -RoleDefinitionName "RDS Contributor" `
    -SignInName $virp_account `
    -TenantGroupName "Default Tenant Group" `
    -TenantName "Az-VDI-SAS-Tenant"
Get-RdsRoleAssignment | Select-Object SignInName,RoleDefinitionName | Where-Object {$_.SignInName -eq $virp_account}