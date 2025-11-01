module "network" {
  source      = "./modules/network"
  vpc_name    = "${var.project_name}-${var.env}-vpc"
  subnet_name = "${var.project_name}-${var.env}-subnet"
  cidr_block  = var.cidr_block
  region      = var.region
}
