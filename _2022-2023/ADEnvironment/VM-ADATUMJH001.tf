resource "azurerm_public_ip" "PIP-ADATUMJH001" {
  name                = "PIP-ADATUMJH001"
  location            = azurerm_resource_group.RG-WCG-Compute.location
  resource_group_name = azurerm_resource_group.RG-WCG-Compute.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "NSG-ADATUMJH001-nic" {
  name                = "NSG-ADATUMJH001-nic"
  location            = azurerm_resource_group.RG-WCG-Compute.location
  resource_group_name = azurerm_resource_group.RG-WCG-Compute.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "ADATUMJH001-nic" {
  name                = "ADATUMJH001-nic"
  location            = azurerm_resource_group.RG-WCG-Compute.location
  resource_group_name = azurerm_resource_group.RG-WCG-Compute.name

  ip_configuration {
    name                          = "ADATUMJH001-nic-ipconfig01"
    subnet_id                     = azurerm_subnet.NonDomainVMs.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.10"
    public_ip_address_id          = azurerm_public_ip.PIP-ADATUMJH001.id
  }
}

resource "azurerm_network_interface_security_group_association" "NSG-ADATUMJH001-nic" {
  network_interface_id      = azurerm_network_interface.ADATUMJH001-nic.id
  network_security_group_id = azurerm_network_security_group.NSG-ADATUMJH001-nic.id
}

resource "azurerm_windows_virtual_machine" "ADATUMJH001" {
  name                  = "ADATUMJH001"
  location              = azurerm_resource_group.RG-WCG-Compute.location
  resource_group_name   = azurerm_resource_group.RG-WCG-Compute.name
  network_interface_ids = [azurerm_network_interface.ADATUMJH001-nic.id]
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