variable "ensayo_alerta_azure_habilitado" {
  type    = bool
  default = false
}

resource "azurerm_monitor_metric_alert" "ensayo_notificacion" {
  count               = var.ensayo_alerta_azure_habilitado ? 1 : 0
  name                = "ensayo-wimiline-alerta-temporal"
  resource_group_name = azurerm_resource_group.wimiline.name
  scopes              = [azurerm_linux_virtual_machine.integracion.id]
  description         = "PRUEBA TEMPORAL: comprueba la entrega de una alerta de Azure Monitor."
  severity            = 4
  frequency           = "PT1M"
  window_size         = "PT5M"
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 101
  }
  action { action_group_id = azurerm_monitor_action_group.alertas.id }
}
