locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true   # ← this must be true
  enable_dns_support   = true   # ← this too
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}
resource "aws_key_pair" "my_key" {
  key_name   = "uttam-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_subnet" "main" {
  cidr_block              = var.subnet_cidr
  vpc_id                  = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.main.names[0]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "TerraWeek-IGW"
  }
}
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "TerraWeek-RT"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
	name 	    = "aws_sg"
	vpc_id      = aws_vpc.main.id
	tags = {
		Name = "TerraWeek-SG"
}
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ip" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_instance" "my_instance" {
        ami = data.aws_ami.main.id
        instance_type = var.instance_type
	 key_name      = aws_key_pair.my_key.key_name
        subnet_id       = aws_subnet.main.id
        vpc_security_group_ids = [aws_security_group.main.id]
        associate_public_ip_address = true

	tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })


	lifecycle {
    create_before_destroy = true  # ← New EC2 ready before old one dies
  }
}

