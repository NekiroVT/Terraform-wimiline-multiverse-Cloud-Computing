resource "azurerm_virtual_machine_extension" "herramientas" {
  name                 = "wimiline-herramientas"
  virtual_machine_id   = azurerm_linux_virtual_machine.integracion.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  protected_settings = jsonencode({
    commandToExecute = "bash -c 'echo ${base64encode(file("${path.module}/scripts/instalar-herramientas.sh"))} | base64 -d > /tmp/wimiline-instalar.sh && bash /tmp/wimiline-instalar.sh && echo ${base64encode(file("${path.module}/scripts/copiar-respaldo.sh"))} | base64 -d > /opt/wimiline/bin/copiar-respaldo.sh && chmod 750 /opt/wimiline/bin/copiar-respaldo.sh'"
  })
  depends_on = [azurerm_subnet_nat_gateway_association.integracion, azurerm_nat_gateway_public_ip_association.integracion]
}
