resource "azurerm_virtual_network" "VN-WCG-Internal" {
  name                = "VN-WCG-Internal"
  location            = azurerm_resource_group.RG-WCG-Network.location
  resource_group_name = azurerm_resource_group.RG-WCG-Network.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "DomainControllers" {
  name                 = "DomainControllers"
  resource_group_name  = azurerm_resource_group.RG-WCG-Network.name
  virtual_network_name = azurerm_virtual_network.VN-WCG-Internal.name
  address_prefixes     = ["10.1.0.0/28"]
}

resource "azurerm_subnet" "NonDomainVMs" {
  name                 = "NonDomainVMs"
  resource_group_name  = azurerm_resource_group.RG-WCG-Network.name
  virtual_network_name = azurerm_virtual_network.VN-WCG-Internal.name
  address_prefixes     = ["10.1.1.0/27"]
}