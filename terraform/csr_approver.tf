resource "helm_release" "kubelet_csr_approver" {
  provider   = helm.cluster
  name       = "kubelet-csr-approver"
  namespace  = "kube-system"
  repository = "https://postfinance.github.io/kubelet-csr-approver"
  chart      = "kubelet-csr-approver"
  version    = var.kubelet_csr_approver_version

  set {
    name  = "providerIpPrefixes"
    value = "0.0.0.0/0"
  }

  set {
    name  = "bypassDnsResolution"
    value = "true"
  }

  depends_on = [talos_cluster_kubeconfig.this]
}
