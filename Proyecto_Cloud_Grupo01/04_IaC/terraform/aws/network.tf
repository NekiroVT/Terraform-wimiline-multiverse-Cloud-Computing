resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "wimiline-vpc" }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "wimiline-igw" }
}
locals {
  subnets = {
    web1 = { cidr = "10.10.1.0/24", az = "us-east-1a", public = true }
    web2 = { cidr = "10.10.6.0/24", az = "us-east-1b", public = true }
    app1 = { cidr = "10.10.3.0/24", az = "us-east-1a", public = false }
    app2 = { cidr = "10.10.4.0/24", az = "us-east-1b", public = false }
    db1  = { cidr = "10.10.2.0/24", az = "us-east-1b", public = false }
    db2  = { cidr = "10.10.5.0/24", az = "us-east-1a", public = false }
  }
}
resource "aws_subnet" "sub" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public
  tags                    = { Name = "wimiline-${each.key}" }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "wimiline-public" }
}
resource "aws_route_table_association" "public" {
  for_each       = toset(["web1", "web2"])
  subnet_id      = aws_subnet.sub[each.key].id
  route_table_id = aws_route_table.public.id
}
resource "aws_nat_gateway" "regional" {
  availability_mode = "regional"
  vpc_id            = aws_vpc.main.id
  depends_on        = [aws_internet_gateway.main]
  tags              = { Name = "wimiline-nat-regional" }
}
resource "aws_route_table" "app" {
  for_each = toset(["app1", "app2"])
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.regional.id
  }
  tags = { Name = "wimiline-${each.key}-routes" }
}
resource "aws_route_table_association" "app" {
  for_each       = toset(["app1", "app2"])
  subnet_id      = aws_subnet.sub[each.key].id
  route_table_id = aws_route_table.app[each.key].id
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.app : rt.id]
  tags              = { Name = "wimiline-s3-endpoint" }
}
resource "aws_security_group" "alb" {
  name   = "wimiline-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "app" {
  name   = "wimiline-app-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "db" {
  name   = "wimiline-db-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
