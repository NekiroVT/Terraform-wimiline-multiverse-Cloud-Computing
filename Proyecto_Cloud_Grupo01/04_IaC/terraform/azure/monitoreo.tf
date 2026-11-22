resource "azurerm_log_analytics_workspace" "integracion" {
  name                = "law-wimiline-integracion"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.1
}
resource "azurerm_monitor_action_group" "alertas" {
  name                = "ag-wimiline-alertas"
  resource_group_name = azurerm_resource_group.wimiline.name
  short_name          = "wimiline"
  email_receiver {
    name          = "correo-operativo"
    email_address = "wimiline.info@gmail.com"
  }
}
resource "azurerm_monitor_metric_alert" "cpu_integracion" {
  name                = "alerta-wimiline-vm-cpu"
  resource_group_name = azurerm_resource_group.wimiline.name
  scopes              = [azurerm_linux_virtual_machine.integracion.id]
  description         = "CPU de la VM de integración superior a 80 por ciento durante 15 minutos."
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action { action_group_id = azurerm_monitor_action_group.alertas.id }
}
resource "azurerm_monitor_data_collection_rule" "integracion" {
  name                = "dcr-wimiline-integracion"
  location            = var.location
  resource_group_name = azurerm_resource_group.wimiline.name
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.integracion.id
      name                  = "workspace"
    }
  }
  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["workspace"]
  }
  data_sources {
    syslog {
      name           = "syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["user"]
      log_levels     = ["Error", "Critical", "Alert", "Emergency", "Warning", "Notice", "Info"]
    }
  }
}
resource "azurerm_virtual_machine_extension" "monitor" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.integracion.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}
resource "azurerm_monitor_data_collection_rule_association" "integracion" {
  name                    = "dcra-wimiline-integracion"
  target_resource_id      = azurerm_linux_virtual_machine.integracion.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.integracion.id
}

