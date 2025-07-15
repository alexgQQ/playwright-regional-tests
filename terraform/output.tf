output "instance_ip_addr" {
  value = {
    for k, bd in google_compute_instance.playwright-test-runner : k => bd.network_interface[0].access_config[0].nat_ip
  }
  description = "The external ip addresses for the test compute instances"
}
