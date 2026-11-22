variable "subscription_id" {
  description = "ID de la suscripción Azure for Students."
  type        = string
}

variable "location" {
  description = "Región propuesta para los recursos de Azure."
  type        = string
  default     = "southcentralus"
}

variable "resource_group_name" {
  description = "Grupo de recursos propuesto para Wimiline."
  type        = string
  default     = "rg-wimiline-multicloud"
}

variable "resource_group_location" {
  description = "Ubicación del grupo ya creado; mantener para evitar reemplazarlo."
  type        = string
  default     = "eastus"
}
