resource "local_sensitive_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/.kubeconfig"
}

resource "null_resource" "gateway_api_crds" {
  triggers = {
    version = "1.1.0"
  }

  provisioner "local-exec" {
    command = "KUBECONFIG=${local_sensitive_file.kubeconfig.filename} kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml"
  }

  depends_on = [local_sensitive_file.kubeconfig]
}
