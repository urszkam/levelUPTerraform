 variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "vm_sa_name" {
  description = "Mame of VM service account"
  type        = string
}

variable "monitoring_sa_name" {
  description = "Name of Monitoring service account"
  type        = string
}
