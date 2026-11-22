resource "azurerm_consumption_budget_resource_group" "wimiline" {
  name              = "presupuesto-wimiline-azure"
  resource_group_id = azurerm_resource_group.wimiline.id
  amount            = 20
  time_grain        = "Monthly"
  time_period { start_date = "2026-11-01T00:00:00Z" }
  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = ["wimiline.info@gmail.com"]
  }
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = ["wimiline.info@gmail.com"]
  }
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = ["wimiline.info@gmail.com"]
  }
}
