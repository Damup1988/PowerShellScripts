resource "azurerm_public_ip" "PIP-FW-WCG-001" {
  name                = "PIP-FW-WCG-001"
  location            = azurerm_resource_group.RG-WCG-Network.location
  resource_group_name = azurerm_resource_group.RG-WCG-Network.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "FW-WCG-001" {
  name                = "FW-WCG-001"
  location            = azurerm_resource_group.RG-WCG-Network.location
  resource_group_name = azurerm_resource_group.RG-WCG-Network.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "ipconfig-001"
    subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.PIP-FW-WCG-001.id
  }
}

resource "azurerm_firewall_network_rule_collection" "RC-Allow-100" {
  name                = "RC-Allow-100"
  azure_firewall_name = azurerm_firewall.FW-WCG-001.name
  resource_group_name = azurerm_resource_group.RG-WCG-Network.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "NonDomainVMsToDMZSubnet1"

    source_addresses = [
      "10.1.1.0/27",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "10.10.0.0/26"
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
  
  rule {
    name = "DC010ToDomainControllers"

    source_addresses = [
      "10.10.0.10",
    ]

    destination_ports = [
      "53,123,135,389,3268,88,445,49152-65535",
    ]

    destination_addresses = [
      "10.1.0.0/28"
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}