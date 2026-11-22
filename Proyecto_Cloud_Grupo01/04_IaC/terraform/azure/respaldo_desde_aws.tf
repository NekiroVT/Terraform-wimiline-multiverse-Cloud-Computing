variable "habilitar_respaldo_desde_aws" {
  description = "Permite recibir copias desde las IP NAT de AWS. Cambia el flujo y la exposición de red."
  type        = bool
  default     = false
}
variable "ips_nat_aws" {
  description = "IPv4 públicas actuales del NAT regional AWS, sin prefijo."
  type        = list(string)
  default     = []
}
variable "sas_inicio" {
  type    = string
  default = "2026-11-20T00:00:00Z"
}
variable "sas_vencimiento" {
  type    = string
  default = "2026-12-20T00:00:00Z"
}
data "azurerm_storage_account_blob_container_sas" "aws_upload" {
  count             = var.habilitar_respaldo_desde_aws ? 1 : 0
  connection_string = azurerm_storage_account.backup.primary_connection_string
  container_name    = azurerm_storage_container.backup.name
  https_only        = true
  start             = var.sas_inicio
  expiry            = var.sas_vencimiento
  permissions {
    read   = false
    add    = true
    create = true
    write  = true
    delete = false
    list   = false
  }
}
output "aws_blob_upload_sas" {
  value     = var.habilitar_respaldo_desde_aws ? data.azurerm_storage_account_blob_container_sas.aws_upload[0].sas : null
  sensitive = true
}
output "blob_container_url" {
  value = azurerm_storage_container.backup.url
}
