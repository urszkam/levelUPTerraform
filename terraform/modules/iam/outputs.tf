output "vm_service_account_email" {
  description = "Email of the VM service account"
  value       = google_service_account.vm_sa.email
}

output "monitoring_service_account_email" {
  description = "Email of the Monitoring service account"
  value       = google_service_account.monitoring_sa.email
}
