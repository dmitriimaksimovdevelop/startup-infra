resource "helm_release" "hcloud_secret" {
  provider  = helm.cluster
  name      = "hcloud-secret"
  namespace = "kube-system"
  chart     = "${path.module}/charts/hcloud-secret"

  set_sensitive {
    name  = "token"
    value = var.hcloud_token
  }

  set {
    name  = "networkName"
    value = hcloud_network.cluster.name
  }

  depends_on = [talos_cluster_kubeconfig.this]
}

resource "helm_release" "hcloud_ccm" {
  provider   = helm.cluster
  name       = "hcloud-cloud-controller-manager"
  namespace  = "kube-system"
  repository = "https://charts.hetzner.cloud"
  chart      = "hcloud-cloud-controller-manager"
  version    = var.hcloud_ccm_version

  set {
    name  = "networking.enabled"
    value = "true"
  }

  set {
    name  = "networking.clusterCIDR"
    value = var.pod_cidr
  }

  set {
    name  = "env.HCLOUD_NETWORK.valueFrom.secretKeyRef.name"
    value = "hcloud"
  }

  set {
    name  = "env.HCLOUD_NETWORK.valueFrom.secretKeyRef.key"
    value = "network"
  }

  depends_on = [helm_release.hcloud_secret]
}
