locals {
  patch_disable_kube_proxy = yamlencode({
    cluster = {
      proxy = {
        disabled = true
      }
    }
  })

  patch_allow_scheduling_on_cp = yamlencode({
    cluster = {
      allowSchedulingOnControlPlanes = true
    }
  })

  # Remove the node.kubernetes.io/exclude-from-external-load-balancers label
  # that Talos sets on control plane nodes by default (since v1.8).
  # Without this, CCM cannot add CP nodes as LB targets.
  patch_remove_lb_exclusion = jsonencode([
    {
      op   = "remove"
      path = "/machine/nodeLabels/node.kubernetes.io~1exclude-from-external-load-balancers"
    }
  ])

  patch_kubelet_node_ip = yamlencode({
    machine = {
      kubelet = {
        nodeIP = {
          validSubnets = [var.subnet_cidr]
        }
        extraArgs = {
          "cloud-provider"             = "external"
          "rotate-server-certificates" = "true"
        }
      }
    }
  })

  patch_cilium_inline = yamlencode({
    cluster = {
      inlineManifests = [
        {
          name     = "cilium"
          contents = data.helm_template.cilium.manifest
        }
      ]
    }
  })

  patch_hcloud_network = yamlencode({
    machine = {
      network = {
        interfaces = [
          {
            interface = "eth1"
            dhcp      = true
          }
        ]
      }
    }
  })

  patch_disable_default_cni = yamlencode({
    cluster = {
      network = {
        cni = {
          name = "none"
        }
      }
    }
  })

  patch_cluster_discovery = yamlencode({
    cluster = {
      discovery = {
        enabled = true
        registries = {
          kubernetes = { disabled = false }
          service    = { disabled = true }
        }
      }
    }
  })
}
