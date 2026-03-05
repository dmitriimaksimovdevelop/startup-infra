# Hetzner Cloud Setup

Before running Terraform, you need to manually prepare a few resources in Hetzner Cloud.

## 1. API Token

1. Open [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Select your project (or create a new one)
3. Go to **Security > API Tokens**
4. Create a token with **Read & Write** permissions
5. Save the token -- it will be used as `hcloud_token` in your `terraform.tfvars`

## 2. Object Storage (S3 Bucket for Terraform State)

1. Go to **Object Storage** in the Hetzner console
2. Create a bucket (e.g., `my-project-tfstate`) in your preferred location
3. Generate S3 credentials (Access Key + Secret Key)
4. These keys will be used in `backend.tfvars` and as `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
5. Update the `bucket` name in `terraform/backend.tf` to match your bucket

## 3. Talos Linux Image

Upload a Talos Linux image as a Hetzner snapshot:

```bash
# Download Talos image for Hetzner Cloud
wget https://github.com/siderolabs/talos/releases/download/v1.9.5/hcloud-amd64.raw.xz

# Decompress
xz -d hcloud-amd64.raw.xz

# Upload to Hetzner via hcloud CLI
hcloud image create --source hcloud-amd64.raw --description "Talos v1.9.5" --architecture x86
```

Note the resulting snapshot ID -- it will be used as `talos_image_id` in your `terraform.tfvars`.

> **Tip:** Make sure the Talos version in the snapshot matches the `talos_version` variable (default: `v1.9.5`).

## 4. Object Storage for Loki (Optional)

If you want centralized log storage with Loki:

1. Create another S3 bucket (e.g., `my-project-loki`)
2. Generate separate S3 credentials
3. Fill in `loki_s3_*` variables in your `terraform.tfvars`

## 5. Domain (Optional)

If you want Hetzner DNS management:

1. Register a domain or transfer DNS to Hetzner
2. Set the `domain` variable in your `terraform.tfvars`
3. Terraform will create A records pointing to the Traefik load balancer

## 6. GitHub Secrets (for CI/CD)

If using the GitHub Actions workflows, add these secrets to your repository:

| Secret | Description |
|--------|-------------|
| `HCLOUD_TOKEN` | Hetzner Cloud API token |
| `TALOS_IMAGE_ID` | Snapshot ID with Talos Linux |
| `ALLOWED_IPS` | JSON list of allowed CIDRs (e.g., `'["1.2.3.4/32"]'`) |
| `S3_ACCESS_KEY` | Access Key for Object Storage (Terraform state) |
| `S3_SECRET_KEY` | Secret Key for Object Storage (Terraform state) |
| `ARC_GITHUB_CONFIG_URL` | Repository/organization URL for ARC runners |
| `ARC_GITHUB_PAT` | GitHub PAT with runner registration permissions |
| `KUBECONFIG` | Base64-encoded kubeconfig (after first `terraform apply`) |
| `LOKI_S3_ACCESS_KEY` | S3 access key for Loki |
| `LOKI_S3_SECRET_KEY` | S3 secret key for Loki |

And these repository variables:

| Variable | Description |
|----------|-------------|
| `DOMAIN` | Your domain name |
| `ACME_EMAIL` | Email for Let's Encrypt |
| `LOKI_S3_BUCKET_NAME` | S3 bucket name for Loki |
| `LOKI_S3_ENDPOINT` | S3 endpoint for Loki |
