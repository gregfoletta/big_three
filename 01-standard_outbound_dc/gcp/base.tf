variable "gcp_prj_id" {
  type = string
  default = "prj-gf-study-1"
}

provider "google" {
  region  = "australia-southeast2"
  project = var.gcp_prj_id
}

data "google_organization" "org" {
  domain = "foletta.org"
}

data "google_billing_account" "billing" {
  display_name = "foletta.org"
  open         = true
}

resource "google_project_service" "project" {
  project = var.gcp_prj_id
  service = "compute.googleapis.com"
  disable_dependent_services = true
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [google_project_service.project]

  create_duration = "30s"
}

resource "google_compute_network" "prod" {
  name = "prod-network"
  auto_create_subnetworks = false
  routing_mode = "REGIONAL"

  depends_on = [time_sleep.wait_30_seconds]
}

resource "google_compute_subnetwork" "prod_a" {
  name = "prod-a"
  ip_cidr_range = "10.64.0.0/24"
  network = google_compute_network.prod.id
}


resource "google_compute_subnetwork" "prod_b" {
  name = "prod-b"
  ip_cidr_range = "10.64.1.0/24"
  network = google_compute_network.prod.id
}
