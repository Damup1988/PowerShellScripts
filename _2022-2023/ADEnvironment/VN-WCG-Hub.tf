resource "azurerm_virtual_network" "VN-WCG-Hub" {
  name                = "VN-WCG-Hub"
  location            = azurerm_resource_group.RG-WCG-Network.location
  resource_group_name = azurerm_resource_group.RG-WCG-Network.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.RG-WCG-Network.name
  virtual_network_name = azurerm_virtual_network.VN-WCG-Hub.name
  address_prefixes     = ["10.0.0.0/26"]
}