terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_compute_resource_policy" "schedule" {
  count = var.schedule == null ? 0 : 1

  project = var.project_id
  name    = "${var.name}-schedule"
  region  = var.region

  instance_schedule_policy {
    time_zone = var.schedule.time_zone

    dynamic "vm_start_schedule" {
      for_each = var.schedule.start == null ? [] : [var.schedule.start]

      content {
        schedule = vm_start_schedule.value
      }
    }

    vm_stop_schedule {
      schedule = var.schedule.stop
    }
  }
}

resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type

  # No access_config: the machine has no public IP. IAP is the only way in.
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
  }

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    # Keys through IAM rather than keys sitting in metadata.
    enable-oslogin = "TRUE"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  scheduling {
    instance_termination_action = var.spot ? "STOP" : null
    provisioning_model          = var.spot ? "SPOT" : "STANDARD"
    preemptible                 = var.spot
    automatic_restart           = !var.spot
    on_host_maintenance         = var.spot ? "TERMINATE" : "MIGRATE"
  }

  resource_policies = var.schedule == null ? [] : [google_compute_resource_policy.schedule[0].id]

  # Without a public IP or a Cloud NAT the machine cannot reach apt, so treat it
  # as immutable: to pick up a newer image, taint it and apply.
  allow_stopping_for_update = true
}
