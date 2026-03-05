resource "helm_release" "traefik" {
  provider         = helm.cluster
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true
  repository       = "https://helm.traefik.io/traefik"
  chart            = "traefik"
  version          = "32.1.0"

  values = [
    yamlencode({
      providers = {
        kubernetesCRD     = { enabled = true }
        kubernetesGateway = { enabled = true }
      }
      ports = {
        web = {}
        websecure = {
          tls = {
            enabled = true
          }
        }
      }
      service = {
        annotations = {
          "load-balancer.hetzner.cloud/use-private-ip" = "true"
          "load-balancer.hetzner.cloud/location"       = var.location
          "load-balancer.hetzner.cloud/name"           = "${var.cluster_name}-traefik"
        }
      }
    })
  ]

  depends_on = [null_resource.gateway_api_crds]
}
