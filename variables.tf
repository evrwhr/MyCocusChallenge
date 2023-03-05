variable "cidr_block" {
    type = string
    description = "CIDR Block"
    default = "172.16.0.0/23"
}

variable "public_subnet" {
    type = string
    description = "Public subnet range"
    default = "172.16.0.0/24"
}

variable "private_subnet" {
    type = string
    description = "Private subnet range"
    default = "172.16.1.0/24"
}

variable "ami_id" {
    type = string
    description = "Image - amzn2-ami-kernel-5.10-hvm-2.0.20230221.0-x86_64-gp2"
    default = "ami-065793e81b1869261"
}

variable "instance_type" {
    type = string
    description = "Instance type free tier"
    default = "t2.micro"
}
