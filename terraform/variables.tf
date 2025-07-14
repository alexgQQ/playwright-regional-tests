variable "project" {}

variable "bucket_path" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

variable "inst_zones" {
  # This needs to be a set to work with for_each
  type    = set(string)
  default = ["us-central1-a", "us-east1-b", "us-south1-a", "us-west1-a"]
  # default = ["us-central1-a"]
}

variable "compute_image" {
  default = "playwright-image"
}
