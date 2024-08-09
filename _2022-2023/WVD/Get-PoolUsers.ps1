# connect to wvd
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

$poolUsers = Get-RdsAppGroupUser `
    -TenantName Az-VDI-SAS-Tenant `
    -HostPoolName AZ-PDMS-NPCC-WVD `
    -AppGroupName "Desktop Application Group" `
    | Select-Object UserPrincipalName

Connect-AzureAD

foreach ($currentItemName in $collection) {
    <# $currentItemName is the current item #>
}