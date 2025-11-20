# Single Debian VM for simple tests
data "google_compute_zones" "available_zones" {
  region = var.region
}

resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available_zones.names[0]
  project      = var.project_id

  # Debian 12 with 20GB root disk
  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # OS Login and OS Config toggles
  metadata = {
    enable-oslogin  = "TRUE"
    enable-osconfig = "TRUE"
  }

  # Startup script installs Nginx and the ops agent
  metadata_startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    env        = var.env
    project_id = var.project_id
  })

  labels = {
    env     = var.env
    project = var.project_id
    role    = "app-vm"
  }

  # Basic tags for firewall targeting
  tags = [var.env, "vm"]
}
