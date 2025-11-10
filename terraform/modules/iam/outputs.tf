output "service_account_email" {
  description = ""
  value       = google_service_account.vm_sa.email
}