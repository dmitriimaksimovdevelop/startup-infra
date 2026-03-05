variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"
}

variable "server_type" {
  description = "Hetzner server type for cluster nodes"
  type        = string
  default     = "cx33"
}

variable "node_count" {
  description = "Number of cluster nodes (control plane)"
  type        = number
  default     = 3
}

variable "talos_image_id" {
  description = "Hetzner snapshot ID with Talos Linux image"
  type        = string
}

variable "network_cidr" {
  description = "CIDR for the Hetzner private network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR for the node subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ips" {
  description = "CIDRs allowed to access K8s API and Talos API"
  type        = list(string)
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "talos-k8s"
}

variable "kubernetes_version" {
  description = "Kubernetes version for Talos"
  type        = string
  default     = "1.32.2"
}

variable "talos_version" {
  description = "Talos Linux version (must match the snapshot image)"
  type        = string
  default     = "v1.9.5"
}

variable "pod_cidr" {
  description = "Pod CIDR for Cilium"
  type        = string
  default     = "10.244.0.0/16"
}

variable "cilium_version" {
  description = "Cilium Helm chart version"
  type        = string
  default     = "1.17.1"
}

variable "hcloud_ccm_version" {
  description = "Hetzner Cloud Controller Manager Helm chart version"
  type        = string
  default     = "1.22.0"
}

variable "arc_version" {
  description = "GitHub Actions Runner Controller Helm chart version"
  type        = string
  default     = "0.10.1"
}

variable "github_config_url" {
  description = "GitHub repository or organization URL for ARC runners"
  type        = string
}

variable "github_pat" {
  description = "GitHub Personal Access Token for ARC"
  type        = string
  sensitive   = true
}

variable "arc_runner_image" {
  description = "Container image for ARC runners"
  type        = string
  default     = "ghcr.io/actions/actions-runner:latest"
}

variable "arc_min_runners" {
  description = "Minimum number of ARC runners"
  type        = number
  default     = 0
}

variable "arc_max_runners" {
  description = "Maximum number of ARC runners"
  type        = number
  default     = 3
}

variable "kubelet_csr_approver_version" {
  description = "kubelet-csr-approver Helm chart version"
  type        = string
  default     = "1.2.6"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 0
}

variable "worker_server_type" {
  description = "Hetzner server type for worker nodes"
  type        = string
  default     = "cx33"
}

variable "loki_s3_bucket_name" {
  description = "S3 bucket name for Loki log storage"
  type        = string
}

variable "loki_s3_endpoint" {
  description = "S3 endpoint for Loki (e.g. nbg1.your-objectstorage.com)"
  type        = string
}

variable "loki_s3_access_key" {
  description = "S3 access key for Loki"
  type        = string
  sensitive   = true
}

variable "loki_s3_secret_key" {
  description = "S3 secret key for Loki"
  type        = string
  sensitive   = true
}

# --- Domain & TLS ---

variable "domain" {
  description = "Primary domain name for DNS records and TLS certificates"
  type        = string
}

variable "acme_email" {
  description = "Email address for Let's Encrypt ACME registration"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}
