variable "domain" {
  type    = string
  default = "multiverso.wimiline.com"
}
variable "enable_https" {
  type    = bool
  default = true
}
variable "alert_email" {
  type    = string
  default = "wimiline.info@gmail.com"
}

variable "ami_id" {
  description = "AMI Ubuntu 24.04 x86_64 validada en us-east-1; fijada para despliegues reproducibles."
  type        = string
  default     = "ami-0109d2b556bd3d7e1"
}
