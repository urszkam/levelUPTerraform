terraform {
  backend "gcs" {
    bucket  = "levelup-group4-terraform-state"
    prefix  = "dev"
  }
}