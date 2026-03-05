# Bootstrap Guide

Step-by-step instructions for initial cluster deployment.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [talosctl](https://www.talos.dev/v1.9/introduction/getting-started/#talosctl)
- Completed Hetzner Cloud setup (see [HETZNER_SETUP.md](HETZNER_SETUP.md))

## Step 1: Configure Variables

Create `terraform/terraform.tfvars` (it is in `.gitignore`):

```hcl
hcloud_token      = "your-hcloud-token"
talos_image_id    = "12345678"
allowed_ips       = ["your-ip/32"]
github_config_url = "https://github.com/your-org/your-repo"
github_pat        = "ghp_xxxxxxxxxxxx"
domain            = "example.com"
acme_email        = "admin@example.com"

loki_s3_bucket_name = "my-loki-bucket"
loki_s3_endpoint    = "nbg1.your-objectstorage.com"
loki_s3_access_key  = "your-loki-s3-access-key"
loki_s3_secret_key  = "your-loki-s3-secret-key"
```

Create `terraform/backend.tfvars`:

```hcl
access_key = "your-s3-access-key"
secret_key = "your-s3-secret-key"
```

Also update the `bucket` name in `terraform/backend.tf`.

## Step 2: Initialize and Apply

```bash
cd terraform

# Initialize (downloads providers, connects to state backend)
terraform init

# Review the plan
terraform plan

# Apply (creates ~20 resources)
terraform apply
```

The first apply takes approximately 10 minutes:
1. Creates network, firewall, load balancer, servers
2. Generates Talos secrets and machine configs
3. Applies configs to servers
4. Bootstraps the cluster on cp-1
5. Waits for cluster health (up to 10 min)
6. Installs Cilium, CCM, CSI, cert-manager, Traefik, monitoring, ARC

## Step 3: Get Kubeconfig

```bash
# Save kubeconfig
terraform output -raw kubeconfig > ../kubeconfig

# Verify nodes
kubectl --kubeconfig=../kubeconfig get nodes

# Or use the Makefile from the project root:
cd ..
make kubeconfig
make nodes
```

## Step 4: Verify Components

```bash
export KUBECONFIG=./kubeconfig

# Cilium
kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium

# Hetzner CCM
kubectl get pods -n kube-system -l app.kubernetes.io/name=hcloud-cloud-controller-manager

# Traefik
kubectl get pods -n traefik

# cert-manager
kubectl get pods -n cert-manager

# Monitoring (VictoriaMetrics, Grafana, Loki)
kubectl get pods -n monitoring

# ARC Controller
kubectl get pods -n arc-systems

# ARC Runners
kubectl get pods -n arc-runners
```

## Step 5: Set Up CI/CD

1. Encode kubeconfig as base64:
   ```bash
   base64 -i kubeconfig | pbcopy  # macOS
   base64 -w0 kubeconfig          # Linux
   ```
2. Add it as the GitHub secret `KUBECONFIG`
3. Copy the example workflows:
   ```bash
   cp .github/workflows/infra.yaml.example .github/workflows/infra.yaml
   cp .github/workflows/deploy.yaml.example .github/workflows/deploy.yaml
   ```
4. Push changes to `apps/` -- the deploy workflow triggers automatically

## Step 6: Talosconfig (Optional)

```bash
terraform output -raw talosconfig > ../talosconfig
export TALOSCONFIG=./talosconfig

# Check cluster health
talosctl health

# View logs
talosctl logs kubelet
```

## Updating the Cluster

When changing variables or configuration:

```bash
cd terraform
terraform plan   # review changes
terraform apply  # apply
```

## Destroying the Cluster

```bash
cd terraform
terraform destroy
```

> **Warning:** This will permanently destroy ALL cluster resources with no way to recover.
