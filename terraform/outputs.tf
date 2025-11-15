output "vm_internal_ip" {
  description = ""
  value       = module.vm.vm_internal_ip
}

output "vm_service_account_email" {
  description = ""
  value       = module.iam.vm_service_account_email
}

output "monitoring_service_account_email" {
  description = ""
  value       = module.iam.monitoring_service_account_email
}
