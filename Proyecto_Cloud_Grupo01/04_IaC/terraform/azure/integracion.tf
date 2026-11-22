# Arquitectura V3: red privada, salida a S3 y acceso privado al almacenamiento.
resource "azurerm_virtual_network" "integracion" {
  name                = "vnet-wimiline-integracion"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  address_space       = ["10.20.0.0/16"]
}
resource "azurerm_subnet" "integracion" {
  name                 = "snet-integracion"
  resource_group_name  = azurerm_resource_group.wimiline.name
  virtual_network_name = azurerm_virtual_network.integracion.name
  address_prefixes     = ["10.20.2.0/24"]
}
resource "azurerm_subnet" "endpoint" {
  name                 = "snet-private-endpoint"
  resource_group_name  = azurerm_resource_group.wimiline.name
  virtual_network_name = azurerm_virtual_network.integracion.name
  address_prefixes     = ["10.20.3.0/24"]
}
resource "azurerm_network_security_group" "integracion" {
  name                = "nsg-wimiline-integracion"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "integracion" {
  subnet_id                 = azurerm_subnet.integracion.id
  network_security_group_id = azurerm_network_security_group.integracion.id
}
resource "azurerm_public_ip" "nat" {
  name                = "pip-wimiline-nat"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_nat_gateway" "integracion" {
  name                    = "nat-wimiline-integracion"
  location                = var.location
  resource_group_name     = azurerm_resource_group.wimiline.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}
resource "azurerm_nat_gateway_public_ip_association" "integracion" {
  nat_gateway_id       = azurerm_nat_gateway.integracion.id
  public_ip_address_id = azurerm_public_ip.nat.id
}
resource "azurerm_subnet_nat_gateway_association" "integracion" {
  subnet_id      = azurerm_subnet.integracion.id
  nat_gateway_id = azurerm_nat_gateway.integracion.id
}
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.wimiline.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "dnslink-wimiline-integracion"
  resource_group_name   = azurerm_resource_group.wimiline.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.integracion.id
}
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-wimiline-blob"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  subnet_id           = azurerm_subnet.endpoint.id
  private_service_connection {
    name                           = "psc-wimiline-blob"
    private_connection_resource_id = azurerm_storage_account.backup.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "blob-zone"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
resource "azurerm_network_interface" "integracion" {
  name                = "nic-wimiline-integracion"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  ip_configuration {
    name                          = "interna"
    subnet_id                     = azurerm_subnet.integracion.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_linux_virtual_machine" "integracion" {
  name                            = "vm-wimiline-integracion"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.wimiline.name
  size                            = "Standard_B2pts_v2"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.integracion.id]
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
}
resource "azurerm_role_assignment" "blob_vm" {
  scope                = azurerm_storage_container.backup.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.integracion.identity[0].principal_id
}


