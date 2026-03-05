# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please send an email to: **security@YOUR_DOMAIN** (replace with your contact).

We will acknowledge receipt within 48 hours and provide a detailed response within 7 days.

## Security Considerations

This project provisions real cloud infrastructure. Before using it, review the following:

### Secrets Management

- **Never commit secrets** to version control. All sensitive values are passed via `terraform.tfvars` (gitignored) or environment variables.
- Use GitHub Actions secrets for CI/CD pipelines.
- Rotate API tokens and access keys regularly.
- The Hetzner Cloud token has full read/write access to your project -- treat it accordingly.

### Network Security

- The firewall restricts Kubernetes API (6443) and Talos API (50000) access to IPs listed in `allowed_ips`.
- HTTP (80) and HTTPS (443) are open to the internet for ingress traffic.
- Nodes communicate over a private Hetzner network (not public internet).
- Consider restricting `allowed_ips` to your specific IP ranges instead of `0.0.0.0/0`.

### Cluster Security

- **Talos Linux** is an immutable, minimal OS designed for Kubernetes. There is no SSH access, no shell, no package manager.
- **Cilium** replaces kube-proxy and provides network policies, eBPF-based networking, and Hubble observability.
- **cert-manager** automatically provisions and renews TLS certificates via Let's Encrypt.
- **kubelet-csr-approver** auto-approves kubelet certificate signing requests (scoped to cluster nodes).

### CI/CD Security

- GitHub Actions runners (ARC) run inside the cluster on ephemeral pods.
- The `KUBECONFIG` secret grants full cluster access -- restrict repository access accordingly.
- Werf uses `GITHUB_TOKEN` (auto-generated, scoped to the repository) for GHCR access.

### State File Security

- Terraform state is stored in an S3-compatible object storage bucket.
- The state file contains sensitive data (tokens, certificates). Ensure the bucket has:
  - No public access
  - Access restricted to CI/CD and authorized operators only
  - Versioning enabled (recommended)

### Recommended Hardening

1. Set `allowed_ips` to specific IP addresses/ranges, not `0.0.0.0/0`
2. Enable Terraform state encryption at rest
3. Use short-lived tokens where possible
4. Regularly update Talos, Kubernetes, and Helm chart versions
5. Monitor cluster access via Grafana dashboards (VictoriaMetrics + Loki)
6. Review and apply Cilium NetworkPolicies for workload isolation
