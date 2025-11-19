variable "project_id" {
  description = "GCP Projet id"
  type        = string
}

variable "region" {
  description = "GCP region where resources are created"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM instance"
  type        = string
}

variable "machine_type" {
  description = "Machine type to use for the VM instance"
  type        = string
}

variable "subnet_self_link" {
  description = "Self link of the subnet to attach to VM"
  type        = string
}

variable "service_account_email" {
  description = "Email address of the service account assigned to the VM"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}
