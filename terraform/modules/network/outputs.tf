
output "subnet_self_link" {
  description = "Self-link of the created subnet"
  value       = google_compute_subnetwork.subnet.self_link
}

output "router_name" {
  description = "Name of the Cloud Router used by NAT"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Name of the Cloud NAT configuration"
  value       = google_compute_router_nat.nat.name
}
