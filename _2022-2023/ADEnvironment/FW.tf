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