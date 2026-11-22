data "aws_caller_identity" "current" {}
resource "random_id" "suffix" { byte_length = 4 }
resource "random_password" "db" {
  length  = 32
  special = false
}
resource "random_password" "jwt" {
  length  = 48
  special = false
}
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = terraform_data.bucket["artifacts"].output.name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_object" "release" {
  bucket      = terraform_data.bucket["artifacts"].output.name
  key         = "releases/multiverso-release.zip"
  source      = "${path.module}/multiverso-release-v3.zip"
  source_hash = filebase64sha256("${path.module}/multiverso-release-v3.zip")
}
resource "aws_ssm_parameter" "db" {
  name  = "/multiverso/prod/db-password"
  type  = "SecureString"
  value = random_password.db.result
}
resource "aws_ssm_parameter" "jwt" {
  name  = "/multiverso/prod/jwt-secret-base64"
  type  = "SecureString"
  value = base64encode(random_password.jwt.result)
}
resource "aws_db_subnet_group" "db" {
  name       = "wimiline-db-subnets"
  subnet_ids = [aws_subnet.sub["db1"].id, aws_subnet.sub["db2"].id]
}
resource "aws_db_instance" "db" {
  identifier              = "multiverso-db"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = "multiverso"
  username                = "postgres"
  password                = random_password.db.result
  multi_az                = true
  publicly_accessible     = false
  backup_retention_period = 7
  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
}
resource "aws_lb" "web" {
  name               = "multiverso-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.sub["web1"].id, aws_subnet.sub["web2"].id]
}
resource "aws_lb_target_group" "web" {
  name     = "multiverso-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { path = "/" }
}
resource "aws_lb_target_group" "api" {
  name     = "multiverso-api-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { path = "/api/public/status" }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  dynamic "default_action" {
    for_each = var.enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.web.arn
    }
  }
  dynamic "default_action" {
    for_each = var.enable_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.web.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
resource "aws_lb_listener_rule" "api_http" {
  count        = var.enable_https ? 0 : 1
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
resource "aws_lb_listener_rule" "api_https" {
  count        = var.enable_https ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
resource "aws_launch_template" "app" {
  name_prefix            = "wimiline-app-"
  image_id               = var.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile { name = "LabInstanceProfile" }
  user_data = base64encode(format("%s\n# release-sha256: %s\n", replace(replace(replace(replace(replace(file("${path.module}/bootstrap.sh"), "__BUCKET__", terraform_data.bucket["artifacts"].output.name), "__DB_ENDPOINT__", aws_db_instance.db.address), "__BACKUP_BUCKET__", terraform_data.bucket["backup"].output.name), "__QUEUE_URL__", aws_sqs_queue.registration.url), "__PUSH_ENABLED__", tostring(var.habilitar_respaldo_azure)), filebase64sha256("${path.module}/multiverso-release-v3.zip")))
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }
  monitoring {
    enabled = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  depends_on = [aws_s3_object.release, aws_ssm_parameter.db, aws_ssm_parameter.jwt, aws_vpc_endpoint.s3, aws_route_table.app]
}
resource "aws_autoscaling_group" "app" {
  name                      = "wimiline-app-asg"
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 4
  vpc_zone_identifier       = [aws_subnet.sub["app1"].id, aws_subnet.sub["app2"].id]
  target_group_arns         = [aws_lb_target_group.web.arn, aws_lb_target_group.api.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 900
  launch_template {
    id      = aws_launch_template.app.id
    version = tostring(aws_launch_template.app.latest_version)
  }
  tag {
    key                 = "Name"
    value               = "wimiline-app"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_policy" "cpu" {
  name                   = "wimiline-cpu-60"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = 60
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
  }
}
output "alb_dns" { value = aws_lb.web.dns_name }
output "bucket_despliegue" { value = terraform_data.bucket["artifacts"].output.name }

