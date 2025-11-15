output "vm_service_account_email" {
  description = ""
  value       = google_service_account.vm_sa.email
}

output "monitoring_service_account_email" {
  description = ""
  value       = google_service_account.monitoring_sa.email
}
