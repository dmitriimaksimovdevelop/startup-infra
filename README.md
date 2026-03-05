# Hetzner Kubernetes Infrastructure

Production-ready Kubernetes cluster on Hetzner Cloud, fully managed with Terraform. Designed for small startups and indie projects that need a cost-effective, secure, and automated infrastructure.

## What You Get

A single `terraform apply` provisions:

- **Talos Linux** cluster (immutable, minimal, no SSH) on Hetzner Cloud
- **Cilium** CNI with eBPF (replaces kube-proxy), Hubble observability
- **Traefik** ingress controller with Gateway API support
- **cert-manager** with Let's Encrypt for automatic TLS
- **Hetzner CCM + CSI** for cloud load balancers and persistent volumes
- **VictoriaMetrics + Grafana** for metrics monitoring
- **Loki + Promtail** for centralized log aggregation
- **GitHub Actions Runner Controller (ARC)** for in-cluster CI/CD runners
- **Hetzner DNS** management for your domain
- **Werf**-based application deployment pipeline

## Architecture

```
                    Internet
                       |
              [ Hetzner LB (Traefik) ]
                       |
        +--------------+--------------+
        |              |              |
   [ cp-1 ]      [ cp-2 ]      [ cp-3 ]      (Talos Linux, control plane)
        |              |              |
        +----- Private Network -------+
                       |
              [ Hetzner LB (K8s API) ]
                       |
                  You / CI/CD
```

### Estimated Monthly Cost (Hetzner)

| Resource | Type | ~Cost/mo |
|----------|------|----------|
| 3x Control Plane | cx33 | ~34.47 EUR |
| 1x API Load Balancer | lb11 | ~5.39 EUR |
| 1x Traefik Load Balancer | lb11 | ~5.39 EUR |
| Object Storage (state + logs) | S3 | ~1-3 EUR |
| **Total** | | **~46-48 EUR** |

*Workers are optional. By default, workloads run on control plane nodes.*

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [talosctl](https://www.talos.dev/v1.9/introduction/getting-started/#talosctl)
- A [Hetzner Cloud](https://console.hetzner.cloud/) account

## Quick Start

### 1. Prepare Hetzner Cloud

See [docs/HETZNER_SETUP.md](docs/HETZNER_SETUP.md) for detailed instructions:
- Create an API token
- Create an S3 bucket for Terraform state
- Upload a Talos Linux snapshot

### 2. Configure Variables

```bash
cd terraform

# Copy and edit the example files
cp terraform.tfvars.example terraform.tfvars
cp backend.tfvars.example backend.tfvars

# Edit terraform.tfvars with your values
# Edit backend.tfvars with your S3 credentials
# Edit backend.tf to set your bucket name
```

### 3. Deploy

```bash
# Initialize Terraform (downloads providers, connects to backend)
terraform init

# Review the execution plan
terraform plan

# Apply (~10 minutes for initial deployment)
terraform apply
```

### 4. Access Your Cluster

```bash
# Save kubeconfig
terraform output -raw kubeconfig > ../kubeconfig
export KUBECONFIG=../kubeconfig

# Verify
kubectl get nodes
kubectl get pods -A
```

See [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) for the full step-by-step guide.

## Project Structure

```
.
├── terraform/                  # Infrastructure as Code
│   ├── variables.tf            # All input variables
│   ├── versions.tf             # Provider versions and configuration
│   ├── backend.tf              # S3 remote state configuration
│   ├── network.tf              # Hetzner private network
│   ├── firewall.tf             # Firewall rules
│   ├── load_balancer.tf        # K8s API load balancer
│   ├── servers.tf              # Hetzner servers (control plane + workers)
│   ├── talos.tf                # Talos machine configs, bootstrap, kubeconfig
│   ├── talos_patches.tf        # Talos machine config patches
│   ├── cilium.tf               # Cilium CNI (inline manifest for Talos)
│   ├── hcloud_ccm.tf           # Hetzner Cloud Controller Manager
│   ├── csr_approver.tf         # Kubelet CSR auto-approver
│   ├── gateway_api.tf          # Gateway API CRDs + kubeconfig
│   ├── traefik.tf              # Traefik ingress controller
│   ├── cert_manager.tf         # cert-manager, ClusterIssuer, Gateway, Certificate
│   ├── dns.tf                  # Hetzner DNS zone and records
│   ├── monitoring.tf           # VictoriaMetrics, Grafana, Loki, Promtail, CSI
│   ├── arc.tf                  # GitHub Actions Runner Controller
│   ├── outputs.tf              # Terraform outputs
│   ├── locals.tf               # Local computed values
│   ├── terraform.tfvars.example
│   ├── backend.tfvars.example
│   └── charts/                 # Local Helm charts
│       └── hcloud-secret/      # Hetzner Cloud token secret
├── apps/                       # Application deployments
│   └── myapp/                  # Example application
│       ├── Dockerfile
│       ├── werf.yaml
│       └── .helm/              # Helm chart for the app
├── .github/workflows/          # CI/CD pipeline examples
│   ├── infra.yaml.example      # Terraform plan/apply workflow
│   └── deploy.yaml.example     # Werf deploy workflow
├── docs/                       # Documentation
│   ├── HETZNER_SETUP.md        # Hetzner Cloud preparation guide
│   └── BOOTSTRAP.md            # Step-by-step bootstrap guide
├── Makefile                    # Convenience commands
├── SECURITY.md                 # Security policy and considerations
└── LICENSE                     # Apache 2.0
```

## Deploying Applications

Each app lives in `apps/<name>/` with a Dockerfile and Helm chart:

```bash
# Create a new app from the example
make new-app NAME=my-service

# Edit apps/my-service/Dockerfile and .helm/values.yaml
# Push to main branch -- the deploy workflow handles the rest
```

## Customization

### Adding Workers

```hcl
# In terraform.tfvars
worker_count      = 2
worker_server_type = "cx33"
```

### Changing Server Types

See [Hetzner server types](https://www.hetzner.com/cloud/) for available options:
- `cx22` -- 2 vCPU, 4 GB RAM (~4.49 EUR/mo)
- `cx33` -- 3 vCPU, 8 GB RAM (~11.49 EUR/mo)
- `cx43` -- 4 vCPU, 16 GB RAM (~18.49 EUR/mo)

### Disabling Components

Components are modular Terraform files. To disable a component, remove or rename the file:

```bash
# Disable ARC (GitHub Actions runners)
mv terraform/arc.tf terraform/arc.tf.disabled

# Disable monitoring stack
mv terraform/monitoring.tf terraform/monitoring.tf.disabled
```

## Destroying the Cluster

```bash
cd terraform
terraform destroy
```

> **Warning:** This will permanently delete ALL cluster resources including volumes and data.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Open a pull request

## License

This project is licensed under the Apache License 2.0 -- see the [LICENSE](LICENSE) file for details.
