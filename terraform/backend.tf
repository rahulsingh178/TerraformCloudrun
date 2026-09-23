terraform {
  backend "gcs" {
    bucket = "terraform-state-rahul178-lab"
    prefix = "cloudrun-cicd"
  }
}