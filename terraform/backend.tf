# Remote state stored in GCS bucket
terraform {
  backend "gcs" {
    bucket  = "levelup-group4-terraform-state"
    prefix  = "dev"
  }
}
