terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Modules
module "network" {
  source = "./modules/network"

  vpc_name    = "${var.project_name}-${var.env}-vpc"
  subnet_name = "${var.project_name}-${var.env}-subnet"
  cidr_block  = var.cidr_block
  region      = var.region
}

module "iam" {
  source = "./modules/iam"

  project_id         = var.project_id
  vm_sa_name         = "${var.project_name}-${var.env}-vm-sa"
  monitoring_sa_name = "${var.project_name}-${var.env}-monit-sa"
}

module "vm" {
  source = "./modules/vm"

  project_id            = var.project_id
  region                = var.region
  vm_name               = "${var.project_name}-${var.env}-vm"
  machine_type          = "e2-small"
  subnet_self_link      = module.network.subnet_self_link
  service_account_email = module.iam.vm_service_account_email
  env                   = var.env
  depends_on            = [module.network, module.iam]
}

module "monitoring" {
  source = "./modules/monitoring"

  project_id         = var.project_id
  env                = var.env
  instance_id        = module.vm.instance_id
  notification_email = var.notification_email
}
