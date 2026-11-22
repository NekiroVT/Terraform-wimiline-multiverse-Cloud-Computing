output "resource_group_name" {
  value = azurerm_resource_group.wimiline.name
}

output "storage_account_name" {
  value = azurerm_storage_account.backup.name
}

output "backup_container_name" {
  value = azurerm_storage_container.backup.name
}
