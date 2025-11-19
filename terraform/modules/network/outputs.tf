output "subnet_self_link" {
  description = "Self link of the subnet to attach the VM to"
  value       = google_compute_subnetwork.subnet.self_link
}
