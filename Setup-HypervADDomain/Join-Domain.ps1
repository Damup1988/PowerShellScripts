# Prepare NIC
$NICName = (Get-NetAdapter)[0].Name

$InterfaceAlias = $NICName
$IPAddress = "10.0.1.101"
$PrefixLength = 24
$DefaultGateway = "10.0.1.1"
$DNS1 = "10.0.1.10"

New-NetIPAddress `
    -InterfaceAlias $InterfaceAlias `
    -IPAddress $IPAddress `
    -PrefixLength $PrefixLength `
    -DefaultGateway $DefaultGateway

Set-DnsClientServerAddress `
    -InterfaceAlias $InterfaceAlias `
    -ServerAddresses $DNS1

# Define variables
$NewComputerName = "ACL02"  # Specify the new name for the computer
$DomainName = "adatum.local"          # Specify the domain to join
$DomainUser = "dutyadmin"          # Specify the domain admin username
$DomainPassword = "BArakuda@123"      # Specify the domain admin password

# Create a secure string for the password
$SecurePassword = ConvertTo-SecureString $DomainPassword -AsPlainText -Force

# Create a PSCredential object
$Credential = New-Object System.Management.Automation.PSCredential ($DomainUser, $SecurePassword)

# Join the computer to the domain
Start-Sleep -Seconds 10
Add-Computer -NewName $NewComputerName -DomainName $DomainName -Credential $Credential

# Optional: Restart the computer after joining the domain
Restart-Computer -Force

