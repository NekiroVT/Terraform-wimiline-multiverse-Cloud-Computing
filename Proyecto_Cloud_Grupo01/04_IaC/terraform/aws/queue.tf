resource "aws_sqs_queue" "dead_letter" {
  name                      = "wimiline-registro-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}
resource "aws_sqs_queue" "registration" {
  name                       = "wimiline-registro"
  visibility_timeout_seconds = 180
  sqs_managed_sse_enabled    = true
  redrive_policy             = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dead_letter.arn, maxReceiveCount = 5 })
}
resource "aws_lambda_function" "email" {
  function_name    = "wimiline-correo-bienvenida"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler          = "registration_email.handler"
  runtime          = "python3.13"
  timeout          = 45
  filename         = "${path.module}/registration_email.zip"
  source_code_hash = filebase64sha256("${path.module}/registration_email.zip")
  environment { variables = { GMAIL_SENDER = "wimiline.info@gmail.com", GMAIL_PASSWORD_PARAMETER = "/multiverso/prod/gmail-app-password" } }
}
resource "aws_lambda_event_source_mapping" "registration" {
  event_source_arn        = aws_sqs_queue.registration.arn
  function_name           = aws_lambda_function.email.arn
  batch_size              = 1
  function_response_types = ["ReportBatchItemFailures"]
}
