output "vm_internal_ip" {
  description = "Name of the internal IP"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "instance_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.vm.name
}

output "instance_id" {
  description = "ID of the VM instance (Monitoring używa tego w metrykach)"
  value       = google_compute_instance.vm.id
}

output "instance_self_link" {
  description = "Self link of the VM instance"
  value       = google_compute_instance.vm.self_link
}

output "instance_zone" {
  description = "Zone of the VM instance"
  value       = google_compute_instance.vm.zone
}
