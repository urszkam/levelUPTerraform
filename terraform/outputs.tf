output "vm_internal_ip" {
  description = "name of internal IP"
  value       = module.vm.vm_internal_ip
}

output "vm_service_account_email" {
  description = "name of VM service account"
  value       = module.iam.vm_service_account_email
}

output "monitoring_service_account_email" {
  description = "Name of Monitoring service account"
  value       = module.iam.monitoring_service_account_email
}
