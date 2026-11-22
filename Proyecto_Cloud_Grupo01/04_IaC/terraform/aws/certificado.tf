resource "aws_acm_certificate" "web" {
  domain_name       = var.domain
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = { Name = "wimiline-certificate" }
}
output "dns_validacion_certificado" {
  value = aws_acm_certificate.web.domain_validation_options
}
