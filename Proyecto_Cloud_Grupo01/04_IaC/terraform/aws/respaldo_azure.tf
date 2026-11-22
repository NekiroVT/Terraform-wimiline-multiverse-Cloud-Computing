variable "habilitar_respaldo_azure" {
  type    = bool
  default = false
}
data "terraform_remote_state" "azure" {
  count   = var.habilitar_respaldo_azure ? 1 : 0
  backend = "local"
  config  = { path = "${path.module}/../azure/terraform.tfstate" }
}
resource "aws_ssm_parameter" "azure_sas" {
  count = var.habilitar_respaldo_azure ? 1 : 0
  name  = "/multiverso/prod/azure-blob-sas"
  type  = "SecureString"
  value = data.terraform_remote_state.azure[0].outputs.aws_blob_upload_sas
}
resource "aws_ssm_parameter" "azure_container_url" {
  count = var.habilitar_respaldo_azure ? 1 : 0
  name  = "/multiverso/prod/azure-blob-container-url"
  type  = "String"
  value = data.terraform_remote_state.azure[0].outputs.blob_container_url
}
resource "aws_cloudwatch_metric_alarm" "copias_azure" {
  count               = var.habilitar_respaldo_azure ? 1 : 0
  alarm_name          = "wimiline-respaldo-azure-ausente"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CopySuccess"
  namespace           = "Wimiline/Backup"
  period              = 14400
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "fallo_copia_azure" {
  count               = var.habilitar_respaldo_azure ? 1 : 0
  alarm_name          = "wimiline-respaldo-azure-error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CopyFailure"
  namespace           = "Wimiline/Backup"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
