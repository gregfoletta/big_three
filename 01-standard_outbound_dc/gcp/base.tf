provider "google" {
  region  = "australia-southeast2"
  project = "big-three-11223344"
}

data "google_organization" "org" {
  domain = "foletta.org"
}

data "google_billing_account" "billing" {
  display_name = "foletta.org"
  open         = true
}

resource "google_project" "main" {
  name            = "big-three"
  project_id      = "big-three-11223344"
  org_id          = data.google_organization.org.org_id
  billing_account  = data.google_billing_account.billing.id
}

resource "google_project_service" "project" {
  project = google_project.main.id
  service = "compute.googleapis.com"
  disable_dependent_services = true
}


resource "google_compute_network" "prod" {
  name = "prod-network"
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
