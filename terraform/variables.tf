 variable "aws_region" {
   type = string
   default = "ap-south-1"
 }
 variable "vpc_cidr" {
   type = string
   default = "10.0.0.0/16"
 }
 variable "subnet_cidr" {
   type = string
   default = "10.0.1.0/24"
 }
 variable "instance_type" {
   type = string
   default = "t2.micro"
 }
 variable "project_name" {
   description = "The name of the project used for resource naming and tagging"
   type = string
 }
variable "environment" {
  type = string
  default = "dev"
}
variable "allowed_ports" {
  type = list(number)
  default = [22, 80, 443]
}
variable "extra_tags" {
  type = map(string)
  default = {}
}
data "aws_ami" "main" {
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
   filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
data "aws_availability_zones" "main" {
  state = "available"
}

