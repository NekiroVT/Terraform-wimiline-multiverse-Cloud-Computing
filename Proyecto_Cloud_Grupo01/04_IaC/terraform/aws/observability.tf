resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = terraform_data.bucket["backup"].output.name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "backup" {
  bucket = terraform_data.bucket["backup"].output.name
  versioning_configuration { status = "Enabled" }
}
resource "aws_sns_topic" "alerts" { name = "wimiline-alertas" }
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
resource "aws_cloudwatch_metric_alarm" "unhealthy" {
  for_each            = { web = aws_lb_target_group.web.arn_suffix, api = aws_lb_target_group.api.arn_suffix }
  alarm_name          = "wimiline-${each.key}-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = aws_lb.web.arn_suffix, TargetGroup = each.value }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "wimiline-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions          = { DBInstanceIdentifier = aws_db_instance.db.identifier }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "wimiline-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = aws_lb.web.arn_suffix }
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "wimiline-operacion"
  dashboard_body = jsonencode({ widgets = [
    { type = "metric", x = 0, y = 0, width = 12, height = 6, properties = { region = "us-east-1", title = "RDS CPU", metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.db.identifier]], period = 300, stat = "Average" } },
    { type = "metric", x = 12, y = 0, width = 12, height = 6, properties = { region = "us-east-1", title = "ALB requests and errors", metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.web.arn_suffix], [".", "HTTPCode_ELB_5XX_Count", ".", "."]], period = 300, stat = "Sum" } }
  ] })
}
output "bucket_respaldos" { value = terraform_data.bucket["backup"].output.name }

