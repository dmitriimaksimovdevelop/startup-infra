output "kubeconfig" {
  description = "Kubeconfig for the Talos cluster"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "api_endpoint" {
  description = "Kubernetes API endpoint (load balancer IP)"
  value       = local.api_endpoint
}

output "node_ips" {
  description = "Public IPv4 addresses of all nodes"
  value       = { for name, node in hcloud_server.nodes : name => node.ipv4_address }
}

output "node_private_ips" {
  description = "Private IPv4 addresses of all nodes"
  value       = { for name, node in hcloud_server.nodes : name => tolist(node.network)[0].ip }
}

output "worker_ips" {
  description = "Public IPv4 addresses of worker nodes"
  value       = { for name, node in hcloud_server.workers : name => node.ipv4_address }
}

output "worker_private_ips" {
  description = "Private IPv4 addresses of worker nodes"
  value       = { for name, node in hcloud_server.workers : name => tolist(node.network)[0].ip }
}
