resource "azurerm_resource_group" "RG-WCG-Network" {
  name     = "RG-WCG-Network"
  location = "germanywestcentral"
}

resource "azurerm_resource_group" "RG-WCG-Compute" {
  name     = "RG-WCG-Compute"
  location = "germanywestcentral"
}