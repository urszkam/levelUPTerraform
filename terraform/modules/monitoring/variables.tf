variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "instance_id" {
  description = "VM instamce ID"
  type        = string
}

variable "notification_email" {
  description = "Email address used for sending notifications"
  type        = string
}
