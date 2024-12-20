$NICName = (Get-NetAdapter)[0].Name

$InterfaceAlias = $NICName
$IPAddress = "10.0.3.10"
$PrefixLength = 24
$DefaultGateway = "10.0.3.1"
$DNS1 = "127.0.0.1"

New-NetIPAddress `
    -InterfaceAlias $InterfaceAlias `
    -IPAddress $IPAddress `
    -PrefixLength $PrefixLength `
    -DefaultGateway $DefaultGateway

Set-DnsClientServerAddress `
    -InterfaceAlias $InterfaceAlias `
    -ServerAddresses $DNS1

Rename-Computer -NewName MGMTDC01
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools

Start-Sleep -Seconds 10
Restart-Computer -Force

