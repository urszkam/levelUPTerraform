output "subnet_self_link" {
  description = "name of subnetwork"
  value       = google_compute_subnetwork.subnet.self_link
}
