resource "helm_release" "cert_manager" {
  provider         = helm.cluster
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.15.3"

  values = [
    yamlencode({
      installCRDs = true
      extraArgs = [
        "--controllers=*,gateway-shim",
        "--enable-gateway-api"
      ]
    })
  ]

  depends_on = [null_resource.gateway_api_crds]
}

resource "local_file" "cluster_issuer_manifest" {
  content = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.acme_email
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [
                  {
                    name      = "traefik-gateway"
                    namespace = "traefik"
                  }
                ]
              }
            }
          }
        ]
      }
    }
  })
  filename = "${path.module}/.cluster-issuer.yaml"
}

resource "null_resource" "cluster_issuer" {
  triggers = {
    manifest_sha = sha256(local_file.cluster_issuer_manifest.content)
  }

  provisioner "local-exec" {
    command = "KUBECONFIG=${local_sensitive_file.kubeconfig.filename} kubectl apply -f ${local_file.cluster_issuer_manifest.filename}"
  }

  depends_on = [helm_release.cert_manager, local_file.cluster_issuer_manifest]
}

resource "local_file" "gateway_manifest" {
  content = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "traefik-gateway"
      namespace = "traefik"
    }
    spec = {
      gatewayClassName = "traefik"
      listeners = [
        {
          name          = "web"
          protocol      = "HTTP"
          port          = 8000
          allowedRoutes = { namespaces = { from = "All" } }
        },
        {
          name          = "websecure"
          protocol      = "HTTPS"
          port          = 8443
          allowedRoutes = { namespaces = { from = "All" } }
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name = "wildcard-tls-cert"
              }
            ]
          }
        }
      ]
    }
  })
  filename = "${path.module}/.gateway.yaml"
}

resource "null_resource" "gateway" {
  triggers = {
    manifest_sha = sha256(local_file.gateway_manifest.content)
  }

  provisioner "local-exec" {
    command = "KUBECONFIG=${local_sensitive_file.kubeconfig.filename} kubectl apply -f ${local_file.gateway_manifest.filename}"
  }

  depends_on = [helm_release.traefik, local_file.gateway_manifest]
}

resource "local_file" "certificate_manifest" {
  content = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "wildcard-tls-cert"
      namespace = "traefik"
    }
    spec = {
      secretName = "wildcard-tls-cert"
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
      dnsNames = [
        var.domain,
        "www.${var.domain}"
      ]
    }
  })
  filename = "${path.module}/.certificate.yaml"
}

resource "null_resource" "certificate" {
  triggers = {
    manifest_sha = sha256(local_file.certificate_manifest.content)
  }

  provisioner "local-exec" {
    command = "KUBECONFIG=${local_sensitive_file.kubeconfig.filename} kubectl apply -f ${local_file.certificate_manifest.filename}"
  }

  depends_on = [null_resource.cluster_issuer, local_file.certificate_manifest]
}
