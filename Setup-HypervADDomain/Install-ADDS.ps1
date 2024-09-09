$NICName = (Get-NetAdapter)[0].Name

$InterfaceAlias = $NICName
$IPAddress = "10.0.10.10"
$PrefixLength = 24
$DefaultGateway = "10.0.10.1"
$DNS1 = "127.0.0.1"

New-NetIPAddress `
    -InterfaceAlias $InterfaceAlias `
    -IPAddress $IPAddress `
    -PrefixLength $PrefixLength `
    -DefaultGateway $DefaultGateway

Set-DnsClientServerAddress `
    -InterfaceAlias $InterfaceAlias `
    -ServerAddresses $DNS1

Rename-Computer -NewName SDC01
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools