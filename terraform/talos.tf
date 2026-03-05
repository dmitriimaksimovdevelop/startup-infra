resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "boot" {
  cluster_name     = var.cluster_name
  cluster_endpoint = local.api_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  config_patches     = local.boot_patches
}

data "talos_machine_configuration" "cp" {
  cluster_name     = var.cluster_name
  cluster_endpoint = local.api_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  config_patches     = local.common_patches
}

# --- Worker configs (conditional) ---

data "talos_machine_configuration" "worker_boot" {
  count            = var.worker_count > 0 ? 1 : 0
  cluster_name     = var.cluster_name
  cluster_endpoint = local.api_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  config_patches     = local.worker_boot_patches
}

data "talos_machine_configuration" "worker" {
  count            = var.worker_count > 0 ? 1 : 0
  cluster_name     = var.cluster_name
  cluster_endpoint = local.api_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  config_patches     = local.worker_patches
}

# --- Client config ---

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = concat(
    [for node in hcloud_server.nodes : node.ipv4_address],
    [for node in hcloud_server.workers : node.ipv4_address],
  )
  nodes = concat(
    [for node in hcloud_server.nodes : node.ipv4_address],
    [for node in hcloud_server.workers : node.ipv4_address],
  )
}

resource "talos_machine_configuration_apply" "nodes" {
  for_each = local.nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cp.machine_configuration
  endpoint                    = hcloud_server.nodes[each.key].ipv4_address
  node                        = hcloud_server.nodes[each.key].ipv4_address
}

resource "talos_machine_configuration_apply" "workers" {
  for_each = local.workers

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[0].machine_configuration
  endpoint                    = hcloud_server.workers[each.key].ipv4_address
  node                        = hcloud_server.workers[each.key].ipv4_address
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = hcloud_server.nodes["cp-1"].ipv4_address
  node                 = hcloud_server.nodes["cp-1"].ipv4_address

  depends_on = [talos_machine_configuration_apply.nodes]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = hcloud_server.nodes["cp-1"].ipv4_address
  node                 = hcloud_server.nodes["cp-1"].ipv4_address

  depends_on = [talos_machine_bootstrap.this]
}
