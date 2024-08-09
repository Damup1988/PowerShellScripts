# connect to wvd
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

Get-RdsHostPool -TenantName Az-VDI-SAS-Tenant | `
    Format-Table HostPoolName,MaxSessionLimit | `
    Export-Csv -Delimiter ';' -Path "C:\_bufer\_scripts\WVD\data3.csv"

(Get-RdsHostPool -TenantName Az-VDI-SAS-Tenant | Select-Object HostPoolName, MaxSessionLimit).MaxSessionLimit