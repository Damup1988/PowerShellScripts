resource "azurerm_virtual_network" "VN-WCG-DMZ" {
  name                = "VN-WCG-DMZ"
  location            = azurerm_resource_group.RG-WCG-Network.location
  resource_group_name = azurerm_resource_group.RG-WCG-Network.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "Subnet1" {
  name                 = "Subnet1"
  resource_group_name  = azurerm_resource_group.RG-WCG-Network.name
  virtual_network_name = azurerm_virtual_network.VN-WCG-DMZ.name
  address_prefixes     = ["10.10.0.0/26"]
}