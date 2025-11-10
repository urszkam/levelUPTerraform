output "vm_internal_ip" {
  description = ""
  value       = module.vm.vm_internal_ip
}

output "service_account_email" {
  description = ""
  value       = module.iam.service_account_email
}