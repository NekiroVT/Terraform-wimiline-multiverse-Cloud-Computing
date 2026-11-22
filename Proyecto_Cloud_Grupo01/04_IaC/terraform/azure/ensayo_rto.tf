variable "rto_ensayo_habilitado" {
  type    = bool
  default = false
}
variable "rto_ip_autorizada" {
  type    = string
  default = ""
}
resource "azurerm_subnet" "rto_test" {
  count                = var.rto_ensayo_habilitado ? 1 : 0
  name                 = "snet-ensayo-rto"
  resource_group_name  = azurerm_resource_group.wimiline.name
  virtual_network_name = azurerm_virtual_network.integracion.name
  address_prefixes     = ["10.20.4.0/24"]
}
resource "azurerm_network_security_group" "rto_test" {
  count               = var.rto_ensayo_habilitado ? 1 : 0
  name                = "nsg-ensayo-rto"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  security_rule {
    name                       = "SoloOrigenPruebaWeb"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "${var.rto_ip_autorizada}/32"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "rto_test" {
  count                     = var.rto_ensayo_habilitado ? 1 : 0
  subnet_id                 = azurerm_subnet.rto_test[0].id
  network_security_group_id = azurerm_network_security_group.rto_test[0].id
}
resource "azurerm_public_ip" "rto_test" {
  count               = var.rto_ensayo_habilitado ? 1 : 0
  name                = "pip-ensayo-rto"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_network_interface" "rto_test" {
  count               = var.rto_ensayo_habilitado ? 1 : 0
  name                = "nic-ensayo-rto"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  ip_configuration {
    name                          = "rto"
    subnet_id                     = azurerm_subnet.rto_test[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rto_test[0].id
  }
}
resource "azurerm_linux_virtual_machine" "rto_test" {
  count                           = var.rto_ensayo_habilitado ? 1 : 0
  name                            = "vm-ensayo-rto"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.wimiline.name
  size                            = "Standard_B2pts_v2"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.rto_test[0].id]
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${pathexpand("~/.ssh")}/wimiline_azure_integracion.pub")
  }
  identity { type = "SystemAssigned" }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }
  depends_on = [azurerm_subnet_network_security_group_association.rto_test]
}
resource "azurerm_role_assignment" "rto_test_blob" {
  count                = var.rto_ensayo_habilitado ? 1 : 0
  scope                = azurerm_storage_container.backup.resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_virtual_machine.rto_test[0].identity[0].principal_id
}
output "rto_ensayo_ip" {
  value = var.rto_ensayo_habilitado ? azurerm_public_ip.rto_test[0].ip_address : null
}

