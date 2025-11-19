variable "vpc_name" {
    description = "Name of the VPC network"
    type        = string
}

variable "subnet_name" {
    description = "Name of subnet within the VPC"
    type        = string
}

variable "cidr_block" {
    description = "CIDR block used for the subnet"
    type        = string
}

variable "region" {
    description = "GCP region where the resources are created"
    type        = string
}
