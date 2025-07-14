
resource "google_service_account" "compute-service-account" {
  account_id   = "playwright-test-runner"
  display_name = "Playwright Test Runner"
  description  = "The service account used on compute instances for executing regional playwright tests and uploading reports"
}

resource "google_project_iam_member" "compute-runner-iam" {
  project = var.project
  for_each = toset([
    "roles/editor",
    "roles/iam.roleAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/storage.objectAdmin",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.compute-service-account.email}"
}

resource "google_compute_instance" "playwright-test-runner" {
  for_each = var.inst_zones
  zone     = each.key
  # There are no listed RAM/CPU requirements https://playwright.dev/docs/intro#system-requirements
  # but from testing this needs more than 2GB of memory
  machine_type = "e2-medium"
  name         = "playwright-test-runner-${each.key}"

  boot_disk {
    auto_delete = true
    device_name = "playwright-test-runner-${each.key}"
    mode        = "READ_WRITE"

    initialize_params {
      image = "projects/${var.project}/global/images/${var.compute_image}"
      size  = 10
      type  = "pd-balanced"
    }
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  metadata = {
    enable-osconfig = "TRUE"
    # We'll use the zone from here to format the test report
    zone        = each.key
    bucket_path = var.bucket_path
  }

  metadata_startup_script = file("${path.module}/run_tests.sh")

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    # A bit of gross formatting but I need to get the region from each zone for the correct subnet
    subnetwork = "projects/${var.project}/regions/${join("-", slice(split("-", each.key), 0, length(split("-", each.key)) - 1))}/subnetworks/default"
  }

  scheduling {
    automatic_restart  = false
    preemptible        = false
    provisioning_model = "STANDARD"
  }

  service_account {
    email = google_service_account.compute-service-account.email
    # TODO: These are the default scopes apart from r/w for cloud storage
    # I'm not sure if I totally need all of these as there is no monitoring
    # but it works fine for now
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }
}
