variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Common project prefix for service names"
  type        = string
}

variable "region" {
  description = "The GCP region where the resources are created"
  type        = string
}

variable "env" {
  description = "Name of the environment (e.g., dev)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block used for network resources"
  type        = string
}

variable "notification_email" {
  description = "Email address used for sending notifications"
  type        = string
}
