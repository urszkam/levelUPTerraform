output "vm_internal_ip" {
  description = "Internal IP address of the vm"
  value       = module.vm.vm_internal_ip
}

output "vm_service_account_email" {
  description = "Email address of the VM's service account"
  value       = module.iam.vm_service_account_email
}

output "monitoring_service_account_email" {
  description = "Email address of the monitoring service account"
  value       = module.iam.monitoring_service_account_email
}
