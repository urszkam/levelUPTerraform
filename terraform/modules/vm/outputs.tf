output "vm_internal_ip" {
  description = ""
  value       = google_compute_instance.vm.network_interface[0].network_ip
}
