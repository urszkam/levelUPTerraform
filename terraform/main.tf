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

module "network" {
  source      = "./modules/network"
  vpc_name    = "${var.project_name}-${var.env}-vpc"
  subnet_name = "${var.project_name}-${var.env}-subnet"
  cidr_block  = var.cidr_block
  region      = var.region
}

module "iam" {
  source  = "./modules/iam"
  project_id = var.project_id
  sa_name = "${var.project_name}-${var.env}-vm-sa"
}

module "vm" {
  source                = "./modules/vm"
  project_id            = var.project_id
  region                = var.region
  vm_name               = "${var.project_name}-${var.env}-vm"
  machine_type          = "e2-medium"
  subnet_self_link      = module.network.subnet_self_link
  service_account_email = module.iam.service_account_email
  env                   = var.env
}
