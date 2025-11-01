variable "project_name" {
  description = ""
  type        = string
  default     = "levelUP"
}

variable "region" {
  description = ""
  type        = string
}

variable "env" {
  description = ""
  type        = string
  default     = "dev"
}

variable "cidr_block" {
  description = ""
  type        = string
  default     = "10.0.0.0/28"
}
