resource "hcloud_load_balancer" "k8s_api" {
  name               = "${var.cluster_name}-api"
  load_balancer_type = "lb11"
  location           = var.location
}

resource "hcloud_load_balancer_network" "k8s_api" {
  load_balancer_id = hcloud_load_balancer.k8s_api.id
  network_id       = hcloud_network.cluster.id
}

resource "hcloud_load_balancer_service" "k8s_api" {
  load_balancer_id = hcloud_load_balancer.k8s_api.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_target" "nodes" {
  for_each = local.nodes

  load_balancer_id = hcloud_load_balancer.k8s_api.id
  type             = "server"
  server_id        = hcloud_server.nodes[each.key].id
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.k8s_api]
}
