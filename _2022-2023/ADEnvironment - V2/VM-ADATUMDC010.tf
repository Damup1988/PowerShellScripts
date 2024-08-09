resource "azurerm_network_interface" "ADATUMDC010-nic" {
  name                = "ADATUMDC010-nic"
  location            = azurerm_resource_group.RG-WCG-Compute.location
  resource_group_name = azurerm_resource_group.RG-WCG-Compute.name

  ip_configuration {
    name                          = "ADATUMDC010-nic-ipconfig01"
    subnet_id                     = azurerm_subnet.Subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.0.10"
  }
}

resource "azurerm_windows_virtual_machine" "ADATUMDC010" {
  name                  = "ADATUMDC010"
  location              = azurerm_resource_group.RG-WCG-Compute.location
  resource_group_name   = azurerm_resource_group.RG-WCG-Compute.name
  network_interface_ids = [azurerm_network_interface.ADATUMDC010-nic.id]
  size                  = "Standard_B2s"
  admin_username        = "dutyadmin"
  admin_password        = "BArakuda@123"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}