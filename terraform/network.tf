resource "hcloud_network" "cluster" {
  name     = "${var.cluster_name}-network"
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.cluster.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.subnet_cidr
}
