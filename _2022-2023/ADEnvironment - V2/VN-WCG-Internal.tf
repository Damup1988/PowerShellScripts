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

resource "azurerm_route_table" "RT-VN-WCG-Internal-NonDomainVMs" {
  name                          = "RT-VN-WCG-Internal-NonDomainVMs"
  location                      = azurerm_resource_group.RG-WCG-Network.location
  resource_group_name           = azurerm_resource_group.RG-WCG-Network.name
  disable_bgp_route_propagation = false

  route {
    name                   = "UDR-To-VN-WCG-DMZ-Subnet1"
    address_prefix         = "10.10.0.0/26"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4"
  }
}

resource "azurerm_subnet_route_table_association" "RT-VN-WCG-Internal-NonDomainVMs" {
  subnet_id      = azurerm_subnet.NonDomainVMs.id
  route_table_id = azurerm_route_table.RT-VN-WCG-Internal-NonDomainVMs.id
}