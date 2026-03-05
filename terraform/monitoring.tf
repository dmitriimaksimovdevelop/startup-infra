resource "helm_release" "hcloud_csi" {
  provider         = helm.cluster
  name             = "hcloud-csi"
  namespace        = "kube-system"
  create_namespace = true
  repository       = "https://charts.hetzner.cloud"
  chart            = "hcloud-csi"
  version          = "2.19.1"

  depends_on = [helm_release.hcloud_secret]
}

resource "helm_release" "victoria_metrics" {
  provider         = helm.cluster
  name             = "vm"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://victoriametrics.github.io/helm-charts/"
  chart            = "victoria-metrics-k8s-stack"
  version          = "0.38.1"

  values = [
    yamlencode({
      vmsingle = {
        enabled = true
        spec = {
          retentionPeriod = "14d"
          storage = {
            storageClassName = "hcloud-volumes"
            resources = {
              requests = {
                storage = "50Gi"
              }
            }
          }
        }
      }
      grafana = {
        enabled       = true
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled          = true
          type             = "pvc"
          storageClassName = "hcloud-volumes"
          size             = "5Gi"
        }
        datasources = {
          "datasources.yaml" = {
            apiVersion = 1
            datasources = [
              {
                name   = "Loki"
                type   = "loki"
                url    = "http://loki-gateway.monitoring.svc.cluster.local"
                access = "proxy"
              }
            ]
          }
        }
      }
    })
  ]

  depends_on = [helm_release.hcloud_csi]
}

resource "helm_release" "loki" {
  provider         = helm.cluster
  name             = "loki"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = "5.41.6"

  values = [
    yamlencode({
      deploymentMode = "SimpleScalable"
      loki = {
        auth_enabled = false
        commonConfig = {
          replication_factor = 1
        }
        schemaConfig = {
          configs = [{
            from         = "2024-04-01"
            store        = "tsdb"
            object_store = "s3"
            schema       = "v13"
            index = {
              prefix = "index_"
              period = "24h"
            }
          }]
        }
        storage = {
          bucketNames = {
            chunks = var.loki_s3_bucket_name
            ruler  = var.loki_s3_bucket_name
            admin  = var.loki_s3_bucket_name
          }
          type = "s3"
          s3 = {
            endpoint         = var.loki_s3_endpoint
            accessKeyId      = var.loki_s3_access_key
            secretAccessKey  = var.loki_s3_secret_key
            s3ForcePathStyle = true
            insecure         = false
          }
        }
      }
      read = {
        replicas = 1
      }
      write = {
        replicas = 1
      }
      backend = {
        replicas = 1
      }
      gateway = {
        enabled  = true
        replicas = 1
      }
      minio = {
        enabled = false
      }
    })
  ]
}

resource "helm_release" "promtail" {
  provider         = helm.cluster
  name             = "promtail"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  version          = "6.15.3"

  values = [
    yamlencode({
      config = {
        clients = [
          {
            url = "http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push"
          }
        ]
      }
      defaultVolumes = [
        {
          name     = "run"
          hostPath = { path = "/run/promtail" }
        },
        {
          name     = "pods"
          hostPath = { path = "/var/log/pods" }
        }
      ]
      defaultVolumeMounts = [
        {
          name      = "run"
          mountPath = "/run/promtail"
        },
        {
          name      = "pods"
          mountPath = "/var/log/pods"
          readOnly  = true
        }
      ]
    })
  ]

  depends_on = [helm_release.loki]
}
