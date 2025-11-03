
output "subnet_self_link" {
  description = ""
  value       = google_compute_subnetwork.subnet.self_link
}

output "router_name" {
  description = ""
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = ""
  value       = google_compute_router_nat.nat.name
}

output "vpc_name" {
  description = ""
  value       = google_compute_network.vpc.name
}
