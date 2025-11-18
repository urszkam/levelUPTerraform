variable "project_id" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "Name of the region"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM instance"
  type        = string
}

variable "machine_type" {
  description = "Name of the machine type"
  type        = string
}

variable "subnet_self_link" {
  description = "Name of the subnet self link"
  type        = string
}

variable "service_account_email" {
  description = "Name of the service acount email"
  type        = string
}

variable "env" {
  description = "name of the env"
  type        = string
}
