resource "hcloud_server" "nodes" {
  for_each = local.nodes

  name        = "${var.cluster_name}-${each.key}"
  server_type = var.server_type
  location    = var.location
  image       = var.talos_image_id
  user_data   = data.talos_machine_configuration.boot.machine_configuration

  firewall_ids = [hcloud_firewall.cluster.id]

  network {
    network_id = hcloud_network.cluster.id
  }

  labels = {
    cluster = var.cluster_name
    role    = "controlplane"
    node    = each.key
  }

  depends_on = [hcloud_network_subnet.nodes]

  lifecycle {
    ignore_changes = [image, user_data, network]
  }
}

resource "hcloud_server" "workers" {
  for_each = local.workers

  name        = "${var.cluster_name}-${each.key}"
  server_type = var.worker_server_type
  location    = var.location
  image       = var.talos_image_id
  user_data   = data.talos_machine_configuration.worker_boot[0].machine_configuration

  firewall_ids = [hcloud_firewall.cluster.id]

  network {
    network_id = hcloud_network.cluster.id
  }

  labels = {
    cluster = var.cluster_name
    role    = "worker"
    node    = each.key
  }

  depends_on = [hcloud_network_subnet.nodes]

  lifecycle {
    ignore_changes = [image, user_data, network]
  }
}
