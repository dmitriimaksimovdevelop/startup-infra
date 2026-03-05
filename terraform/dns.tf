data "hcloud_load_balancer" "traefik" {
  name = "${var.cluster_name}-traefik"
}

resource "hcloud_zone" "main" {
  name = var.domain
  mode = "primary"
  ttl  = 86400
}

resource "hcloud_zone_rrset" "apex" {
  zone = hcloud_zone.main.id
  type = "A"
  name = "@"
  ttl  = 300
  records = [
    {
      value = data.hcloud_load_balancer.traefik.ipv4
    }
  ]
}

resource "hcloud_zone_rrset" "www" {
  zone = hcloud_zone.main.id
  type = "A"
  name = "www"
  ttl  = 300
  records = [
    {
      value = data.hcloud_load_balancer.traefik.ipv4
    }
  ]
}

resource "hcloud_zone_rrset" "wildcard" {
  zone = hcloud_zone.main.id
  type = "A"
  name = "*"
  ttl  = 300
  records = [
    {
      value = data.hcloud_load_balancer.traefik.ipv4
    }
  ]
}
