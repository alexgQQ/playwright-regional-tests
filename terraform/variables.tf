variable "project" {
  description = "The project id that the resources will be deployed in"
}

variable "bucket_path" {
  description = "The google bucket path where the test reports will be copied"
}

variable "region" {
  default = "us-central1"
  description = "The default region for the gcp provider"
}

variable "zone" {
  default = "us-central1-c"
  description = "The default zone for the gcp provider"
}

variable "inst_zones" {
  # This needs to be a set to work with for_each
  type    = set(string)
  default = ["us-central1-a", "us-east1-b", "us-south1-a", "us-west1-a"]
  description = "The zones where compute intstances will be deployed to test"
}

variable "compute_image" {
  default = "playwright-image"
  description = "The image name to use for provisioning the test compute instances"
}
