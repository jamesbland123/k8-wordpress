# Terraform K8 
provider "google" {
  credentials = "${file("~/.config/gcloud/terraform-admin.json")}"
  project     = "abc123"
  region      = "us-west2"
}

resource "google_container_cluster" "primary" {
  name   = "${var.cluster_name}"
  region = "us-west2"

  # Create the cluster with the smallest node pool and remove it
  remove_default_node_pool = true
  initial_node_count       = 1

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = "${var.linux_admin_username}"
    password = "${var.linux_admin_password}}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_container_node_pool" "primary" {
  name       = "my-node-pool"
  region     = "us-west2"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = "${var.gcp_cluster_count}"

  node_config {
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }
}
