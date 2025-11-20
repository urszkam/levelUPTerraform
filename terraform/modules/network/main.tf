# Simple VPC with one subnet and outbound NAT
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  description             = "VPC network"

  lifecycle {
    ignore_changes = [description]
  }
}


# Subnet with flow logs enabled
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.cidr_block
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "Subnet associated with the VPC network"

  private_ip_google_access = true

  lifecycle {
    ignore_changes = [description]
  }

  log_config {
    aggregation_interval = "INTERVAL_1_MIN"
    flow_sampling        = 0.3
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Basic firewall rules for the VPC
resource "google_compute_firewall" "allow-internal" {
  name         = "${var.vpc_name}-allow-internal"
  network      = google_compute_network.vpc.name
  description  = "Firewall rule allowing internal traffic within the VPC"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.cidr_block]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  lifecycle {
    replace_triggered_by = [google_compute_network.vpc]
  }
}

# Allow SSH and ICMP from the internet
resource "google_compute_firewall" "allow-ssh-icmp" {
  name         = "${var.vpc_name}-allow-ssh-icmp"
  network      = google_compute_network.vpc.name
  description  = "Firewall rule allowing ssh and icmp within the VPC"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  lifecycle {
    replace_triggered_by = [google_compute_network.vpc]
  }
}

# Allow HTTP to reach the VM web page
resource "google_compute_firewall" "allow-http" {
  name        = "${var.vpc_name}-allow-http"
  network     = google_compute_network.vpc.name
  description = "Firewall rule allowing http to the VPC"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = ["vm"]
  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  lifecycle {
    replace_triggered_by = [google_compute_network.vpc]
  }
}

# Cloud Router as base for NAT
resource "google_compute_router" "router" {
  name        = "${var.vpc_name}-router"
  region      = var.region
  network     = google_compute_network.vpc.name
  description = "Cloud router for managing dynamic routes"

  lifecycle {
    replace_triggered_by = [google_compute_network.vpc]
  }
}

# NAT gives internet egress without public IPs on VMs
resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  lifecycle {
    replace_triggered_by = [google_compute_network.vpc]
  }
}
