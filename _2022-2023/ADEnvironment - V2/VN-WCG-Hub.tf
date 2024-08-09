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

resource "azurerm_route_table" "RT-VN-WCG-Hub-AzureFirewallSubnet" {
  name                          = "RT-VN-WCG-Hub-AzureFirewallSubnet"
  location                      = azurerm_resource_group.RG-WCG-Network.location
  resource_group_name           = azurerm_resource_group.RG-WCG-Network.name
  disable_bgp_route_propagation = false

  route {
    name           = "UDR-Default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "RT-VN-WCG-Hub-AzureFirewallSubnet" {
  subnet_id      = azurerm_subnet.AzureFirewallSubnet.id
  route_table_id = azurerm_route_table.RT-VN-WCG-Hub-AzureFirewallSubnet.id
}