################################################################################  
#COCUS CHALLENGE - Leonardo Ribeiro 03-05-2023
################################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.3.0"
    }
  }
}

provider "aws" {
    region = "${local.region}"
}

locals {
  name   = "awslab"
  region = "eu-west-1"
  public_subnet_tag = "subnet-public"
  private_subnet_tag = "subnet-private"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name            = "${local.name}-vpc"
  cidr            = "${var.cidr_block}"
  azs             = ["${local.region}a"]
  public_subnets  = ["${var.public_subnet}"]
  private_subnets = ["${var.private_subnet}"]

  create_igw         = true
  enable_nat_gateway = false

  vpc_tags = {
    Name = "${local.name}-vpc"
  }
  public_subnet_tags = {
    Name = "${local.name}-${local.public_subnet_tag}"
  }
  private_subnet_tags = {
    Name = "${local.name}-${local.private_subnet_tag}"
  }
}

################################################################################  
#PUBLIC SG
################################################################################
resource "aws_security_group" "public" {
  name = "${local.name}-public-sg"
  description = "Public internet access"
  vpc_id = module.vpc.vpc_id
 
  tags = {
    Name        = "${local.name}-public-sg"
    Environment = "lab"
    ManagedBy   = "terraform"
    CreatedBy   ="Leonardo Ribeiro"
  }
}
resource "aws_security_group_rule" "public_http" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
}
resource "aws_security_group_rule" "public_icmp" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
}
resource "aws_security_group_rule" "public_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public_outbound" {
 type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
}

################################################################################  
#PRIVATE SG
################################################################################
resource "aws_security_group" "private" {
  name = "${local.name}-private-sg"
  description = "Private access"
  vpc_id = module.vpc.vpc_id
    
  tags = {
    Name        = "${local.name}-private-sg"
    Environment = "lab"
    ManagedBy   = "terraform"
    CreatedBy   ="Leonardo Ribeiro"
  }
}
resource "aws_security_group_rule" "private_custom" {
  type        = "ingress"
  from_port   = 3110
  to_port     = 3110
  protocol    = "tcp"
  cidr_blocks = ["${var.public_subnet}"]
  security_group_id = aws_security_group.private.id
}
resource "aws_security_group_rule" "private_icmp" {
 type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private.id
}
resource "aws_security_group_rule" "private_ssh" {
 type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${var.public_subnet}"]
  security_group_id = aws_security_group.private.id
}
resource "aws_security_group_rule" "private_outbound" {
 type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["${var.public_subnet}"]
  security_group_id = aws_security_group.private.id
}

################################################################################
# EC2 WEB SERVER
################################################################################
resource "aws_key_pair" "webserver_key_pair" {
key_name = "${local.name}-webserver-key-pair"
public_key = tls_private_key.webserver_rsa.public_key_openssh
}
resource "tls_private_key" "webserver_rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "webserver_key" {
content  = tls_private_key.webserver_rsa.private_key_pem
filename = "${local.name}-webserver-key-pair"
}

resource "aws_instance" "webserver" {

  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = aws_key_pair.webserver_key_pair.key_name
  monitoring             = false
  vpc_security_group_ids = ["${aws_security_group.public.id}"]
  subnet_id              = "${join(", ", "${module.vpc.public_subnets}")}"
 
  tags = {
    Name        = "webserver"
    ManagedBy   = "terraform"
    Environment = "lab"
    CreatedBy   = "Leonardo Ribeiro"
  }
} 

################################################################################
# EC2 DATABASE
################################################################################
resource "aws_key_pair" "database_key_pair" {
key_name = "${local.name}-database-key-pair"
public_key = tls_private_key.database_rsa.public_key_openssh
}
resource "tls_private_key" "database_rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "database_key" {
content  = tls_private_key.database_rsa.private_key_pem
filename = "${local.name}-database-key-pair"
}
  
resource "aws_instance" "database" {
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = aws_key_pair.database_key_pair.key_name
  monitoring             = false
  vpc_security_group_ids = ["${aws_security_group.private.id}"]
  subnet_id              = "${join(", ", "${module.vpc.private_subnets}")}"
 
  tags = {
    Name        = "database"
    ManagedBy   = "terraform"
    Environment = "lab"
    CreatedBy   = "Leonardo Ribeiro"
  }
} 
