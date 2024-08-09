resource "azurerm_virtual_network_peering" "VN-WCG-InternalToVN-WCG-Hub" {
  name                      = "VN-WCG-InternalToVN-WCG-Hub"
  resource_group_name       = azurerm_resource_group.RG-WCG-Network.name
  virtual_network_name      = azurerm_virtual_network.VN-WCG-Internal.name
  remote_virtual_network_id = azurerm_virtual_network.VN-WCG-Hub.id
}

resource "azurerm_virtual_network_peering" "VN-WCG-HubToVN-WCG-Internal" {
  name                      = "VN-WCG-HubToVN-WCG-Internal"
  resource_group_name       = azurerm_resource_group.RG-WCG-Network.name
  virtual_network_name      = azurerm_virtual_network.VN-WCG-Hub.name
  remote_virtual_network_id = azurerm_virtual_network.VN-WCG-Internal.id
}

resource "azurerm_virtual_network_peering" "VN-WCG-DMZToVN-WCG-Hub" {
  name                      = "VN-WCG-DMZToVN-WCG-Hub"
  resource_group_name       = azurerm_resource_group.RG-WCG-Network.name
  virtual_network_name      = azurerm_virtual_network.VN-WCG-DMZ.name
  remote_virtual_network_id = azurerm_virtual_network.VN-WCG-Hub.id
}

resource "azurerm_virtual_network_peering" "VN-WCG-HubToVN-WCG-DMZ" {
  name                      = "VN-WCG-HubToVN-WCG-DMZ"
  resource_group_name       = azurerm_resource_group.RG-WCG-Network.name
  virtual_network_name      = azurerm_virtual_network.VN-WCG-Hub.name
  remote_virtual_network_id = azurerm_virtual_network.VN-WCG-DMZ.id
}