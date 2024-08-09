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

resource "azurerm_route_table" "RT-VN-WCG-DMZ-Subnet1" {
  name                          = "RT-VN-WCG-DMZ-Subnet1"
  location                      = azurerm_resource_group.RG-WCG-Network.location
  resource_group_name           = azurerm_resource_group.RG-WCG-Network.name
  disable_bgp_route_propagation = false

  route {
    name                   = "UDR-To-VN-WCG-Internal-NonDomainVMs"
    address_prefix         = "10.1.1.0/27"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4"
  }
}

resource "azurerm_subnet_route_table_association" "RT-VN-WCG-DMZ-Subnet1" {
  subnet_id      = azurerm_subnet.Subnet1.id
  route_table_id = azurerm_route_table.RT-VN-WCG-DMZ-Subnet1.id
}