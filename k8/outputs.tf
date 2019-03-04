output "gcp_cluster_endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}

output "gcp_ssh_command" {
  value = "ssh ${var.linux_admin_username}@${google_container_cluster.primary.endpoint}"
}

output "gcp_cluster_name" {
  value = "${google_container_cluster.primary.name}"
}
