resource "helm_release" "arc_controller" {
  provider         = helm.cluster
  name             = "arc"
  namespace        = "arc-systems"
  create_namespace = true
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set-controller"
  version          = var.arc_version

  depends_on = [talos_cluster_kubeconfig.this]
}

resource "helm_release" "arc_runner_set" {
  provider         = helm.cluster
  name             = "arc-runner-set"
  namespace        = "arc-runners"
  create_namespace = true
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set"
  version          = var.arc_version

  set {
    name  = "githubConfigUrl"
    value = var.github_config_url
  }

  set_sensitive {
    name  = "githubConfigSecret.github_token"
    value = var.github_pat
  }

  set {
    name  = "minRunners"
    value = var.arc_min_runners
  }

  set {
    name  = "maxRunners"
    value = var.arc_max_runners
  }

  set {
    name  = "template.spec.containers[0].name"
    value = "runner"
  }

  set {
    name  = "template.spec.containers[0].image"
    value = var.arc_runner_image
  }

  set {
    name  = "template.spec.containers[0].command[0]"
    value = "/home/runner/run.sh"
  }

  depends_on = [helm_release.arc_controller]
}
