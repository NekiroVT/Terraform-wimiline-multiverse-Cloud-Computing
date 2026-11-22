# Infraestructura de almacenamiento y contingencia multicloud en Azure (configurada para recibir respaldos desde AWS).
resource "azurerm_resource_group" "wimiline" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
    proyecto = "Wimiline"
    entorno  = "universidad"
  }
}

resource "random_id" "storage_suffix" {
  byte_length = 4
}

resource "azurerm_storage_account" "backup" {
  name                            = "wimilinebackup${random_id.storage_suffix.hex}"
  resource_group_name             = azurerm_resource_group.wimiline.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = var.habilitar_respaldo_desde_aws
  allow_nested_items_to_be_public = false

  dynamic "network_rules" {
    for_each = var.habilitar_respaldo_desde_aws ? [1] : []
    content {
      default_action = "Deny"
      bypass         = ["None"]
      ip_rules       = var.ips_nat_aws
    }
  }

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "backup" {
  name                  = "respaldos"
  storage_account_id    = azurerm_storage_account.backup.id
  container_access_type = "private"
}

