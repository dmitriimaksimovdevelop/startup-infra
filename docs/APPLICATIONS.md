# Application Deployment Guide

This project uses [Werf](https://werf.io/) to build Docker images and deploy applications to the Kubernetes cluster via Helm charts. Each application lives in `apps/<name>/` and follows a consistent structure.

## How It Works

```
push to main (apps/**)
       |
       v
GitHub Actions (deploy.yaml)
       |
       v
werf converge
  1. Builds Docker image from Dockerfile
  2. Pushes image to GitHub Container Registry (GHCR)
  3. Renders Helm chart with the built image tag
  4. Deploys to the Kubernetes cluster
```

Werf handles the entire CI/CD pipeline: build, tag, push, deploy, and cleanup of old images -- all in one tool.

## Application Structure

```
apps/myapp/
├── Dockerfile              # How to build the container image
├── werf.yaml               # Werf project config (links Dockerfile to Helm)
├── index.html              # Application source code (your files here)
└── .helm/
    ├── Chart.yaml           # Helm chart metadata + app-template dependency
    ├── templates/
    │   └── app.yaml         # Includes all resources from app-template
    └── values.yaml          # Application configuration
```

### Key Files Explained

#### `werf.yaml`

```yaml
project: myapp          # Must match the directory name
configVersion: 1

---
image: app              # Image name -- referenced in Helm templates
dockerfile: Dockerfile  # Path to Dockerfile
```

This tells Werf: "Build an image called `app` using `Dockerfile`." The built image is automatically available in Helm templates as `{{ .Values.werf.image.app }}`.

#### `.helm/Chart.yaml`

```yaml
apiVersion: v2
name: myapp
version: 0.1.0
type: application
dependencies:
  - name: app-template
    version: "0.1.0"
    repository: "file://../../../charts/app-template"
```

Uses the shared `app-template` library chart. This chart provides reusable templates for Deployment, Service, and Secret so you don't have to write boilerplate YAML for each app.

#### `.helm/values.yaml`

```yaml
replicas: 2

ports:
  - name: http
    containerPort: 80

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi
```

This is where you configure your application. All values are passed to the `app-template` chart templates.

#### `.helm/templates/app.yaml`

```yaml
{{ include "app-template.all" . }}
```

One line -- includes the Deployment + Service (+ Secret if defined) from the library chart.

## The `app-template` Library Chart

Located at `charts/app-template/`, this is a Helm [library chart](https://helm.sh/docs/topics/library_charts/) that generates Kubernetes resources from your `values.yaml`.

### What It Creates

| Resource | Condition |
|----------|-----------|
| `Deployment` | Always |
| `Service` | Unless `service.enabled: false` |
| `Secret` | Only if `secrets` map is defined |

### Supported Values

```yaml
# Replicas
replicas: 2

# Container image key (matches werf.yaml image name)
imageKey: app  # default: "app"

# Container ports
ports:
  - name: http
    containerPort: 80
    protocol: TCP  # default

# Service
service:
  type: ClusterIP     # or NodePort, LoadBalancer
  port: 80
  targetPort: 80      # defaults to service.port
  enabled: true       # set to false to skip Service creation

# Container resources
resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi

# Environment variables
env:
  - name: DATABASE_URL
    value: "postgres://..."
  - name: SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: secret-key

# Load env from ConfigMap/Secret
envFrom:
  - secretRef:
      name: my-app-secrets

# Secrets (creates a Kubernetes Secret resource)
secrets:
  API_KEY: "my-api-key"
  DB_PASSWORD: "my-db-password"

# Health checks
probes:
  liveness:
    httpGet:
      path: /healthz
      port: http
    initialDelaySeconds: 10
  readiness:
    httpGet:
      path: /ready
      port: http
    initialDelaySeconds: 5

# Command override
command: ["/bin/sh"]
args: ["-c", "my-entrypoint.sh"]

# Volumes
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-data
volumeMounts:
  - name: data
    mountPath: /data

# Scheduling
nodeSelector:
  kubernetes.io/arch: amd64
tolerations: []
affinity: {}

# Extra labels and annotations
labels:
  team: backend
podAnnotations:
  prometheus.io/scrape: "true"

# Image pull secrets (for private registries)
imagePullSecrets:
  - name: my-registry-secret
```

## Creating a New Application

### Option 1: Use the Makefile

```bash
make new-app NAME=my-api
```

This copies `apps/myapp/` to `apps/my-api/` and replaces all occurrences of `myapp` with `my-api`.

### Option 2: Create Manually

```bash
mkdir -p apps/my-api/.helm/templates
```

Create the files as described in [Application Structure](#application-structure).

### Then

1. Write your `Dockerfile`
2. Edit `.helm/values.yaml` with your ports, resources, env vars, etc.
3. Build Helm dependencies:
   ```bash
   cd apps/my-api/.helm && helm dependency build
   ```
4. Commit and push to `main`

## Local Development with Werf

You can test the deployment locally before pushing:

```bash
# Install werf: https://werf.io/installation.html

# Set kubeconfig
export KUBECONFIG=./kubeconfig

# Build and deploy
cd apps/myapp
werf converge --repo ghcr.io/YOUR_ORG/myapp

# Check the result
kubectl get pods
kubectl get svc

# Tear down
werf dismiss
```

## CI/CD Pipeline

The deploy workflow (`.github/workflows/deploy.yaml.example`) runs on every push to `main` that changes files in `apps/` or `charts/`:

1. **Checkout** -- full history (needed by werf for image tagging)
2. **Install werf** -- via official GitHub Action
3. **Login to GHCR** -- uses `GITHUB_TOKEN` (automatic)
4. **Set kubeconfig** -- from `KUBECONFIG` secret (base64-encoded)
5. **werf converge** -- builds image, deploys Helm chart
6. **werf cleanup** -- removes old unused images from GHCR

To enable it:
```bash
cp .github/workflows/deploy.yaml.example .github/workflows/deploy.yaml
```

## Advanced Examples

### API Service with Database Connection

```yaml
# apps/my-api/.helm/values.yaml
replicas: 3

ports:
  - name: http
    containerPort: 8080

service:
  port: 8080

env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: my-api
        key: DATABASE_URL
  - name: PORT
    value: "8080"

secrets:
  DATABASE_URL: "postgres://user:pass@db:5432/mydb"

resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

probes:
  liveness:
    httpGet:
      path: /healthz
      port: http
    initialDelaySeconds: 15
  readiness:
    httpGet:
      path: /ready
      port: http
    initialDelaySeconds: 5
```

### Static Site (like the included myapp)

```yaml
# apps/landing/.helm/values.yaml
replicas: 2

ports:
  - name: http
    containerPort: 80

service:
  port: 80

resources:
  requests:
    cpu: 50m
    memory: 32Mi
  limits:
    cpu: 100m
    memory: 64Mi
```
