locals {
  nodes   = { for i in range(1, var.node_count + 1) : "cp-${i}" => {} }
  workers = { for i in range(1, var.worker_count + 1) : "worker-${i}" => {} }

  api_endpoint = "https://${hcloud_load_balancer.k8s_api.ipv4}:6443"

  kubeconfig = yamldecode(talos_cluster_kubeconfig.this.kubeconfig_raw)

  # --- Control plane patches ---

  # Minimal patches for userdata (must fit in 32KB Hetzner limit)
  boot_patches = [
    local.patch_disable_kube_proxy,
    local.patch_disable_default_cni,
    local.patch_allow_scheduling_on_cp,
    local.patch_remove_lb_exclusion,
    local.patch_kubelet_node_ip,
    local.patch_hcloud_network,
    local.patch_cluster_discovery,
  ]

  # Full patches including Cilium inline manifest (applied via API after boot)
  common_patches = [
    local.patch_disable_kube_proxy,
    local.patch_disable_default_cni,
    local.patch_allow_scheduling_on_cp,
    local.patch_remove_lb_exclusion,
    local.patch_kubelet_node_ip,
    local.patch_cilium_inline,
    local.patch_hcloud_network,
    local.patch_cluster_discovery,
  ]

  # --- Worker patches ---

  worker_boot_patches = [
    local.patch_disable_kube_proxy,
    local.patch_disable_default_cni,
    local.patch_kubelet_node_ip,
    local.patch_hcloud_network,
    local.patch_cluster_discovery,
  ]

  worker_patches = [
    local.patch_disable_kube_proxy,
    local.patch_disable_default_cni,
    local.patch_kubelet_node_ip,
    local.patch_cilium_inline,
    local.patch_hcloud_network,
    local.patch_cluster_discovery,
  ]
}
