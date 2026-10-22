# K8s ArgoCD CI/CD Pipeline

🚀 **Production-ready Kubernetes deployment with ArgoCD, Vault, and JFrog**

## 📋 Architecture Overview

This repository provides a complete CI/CD pipeline for deploying any Docker image from JFrog to Kubernetes across multiple environments (DEV, INT, UAT, PROD) using:

- **GitLab CI/CD**: Build & push Docker images to JFrog
- **JFrog Artifactory**: Docker image registry
- **ArgoCD**: GitOps-based Kubernetes deployments
- **Vault**: Secrets management
- **Helm**: Templated Kubernetes manifests

## 🏗️ Project Structure

```
k8s-argo-cicd/
├── .gitlab-ci.yml              # CI/CD Pipeline (Build → Push to JFrog → Deploy via ArgoCD)
├── requirements.txt            # Python dependencies (optional, for reference)
├── helm/                       # Generic Helm Chart
│   ├── Chart.yaml              # Helm chart metadata
│   ├── values.yaml             # Default values
│   └── templates/              # K8s templates
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── hpa.yaml
│       ├── configmap.yaml
│       └── serviceaccount.yaml
├── argocd/
│   └── applications/           # ArgoCD Application manifests
│       ├── app-dev.yaml        # DEV environment
│       ├── app-int.yaml        # INT environment
│       ├── app-uat.yaml        # UAT environment
│       └── app-prod.yaml       # PROD environment
├── vault/                      # Vault configuration
│   ├── policies.yaml           # IAM policies per environment
│   └── k8s-auth-setup.sh       # K8s auth setup script
└── README.md
```

## 🔄 CI/CD Pipeline Flow

### 1. **Build Stage** (GitLab CI)
- ✅ Unit tests
- ✅ Code quality scan (SonarQube)
- ✅ Build & push Docker image to JFrog

### 2. **Deployment Stage** (ArgoCD)
- ✅ ArgoCD pulls Helm values from this repo
- ✅ Automatically deploys to DEV/INT/UAT
- ✅ Manual sync for PROD
- ✅ Vault provides secrets at runtime

## 📦 Environment Principles

### DEV
- **Image tag**: `latest` (Always pull)
- **Replicas**: 1
- **Debug**: Enabled
- **Resources**: Minimal (50m CPU, 128Mi RAM)
- **Metrics**: Disabled
- **Vault**: HTTP (insecure, dev-only)

### INT
- **Image tag**: `staging` (IfNotPresent)
- **Replicas**: 2
- **Debug**: Disabled
- **Resources**: Standard (100m CPU, 256Mi RAM)
- **Metrics**: Enabled
- **Ingress**: Yes (staging cert)
- **Autoscaling**: 2-5 replicas
- **Vault**: HTTP

### UAT
- **Image tag**: `staging` (IfNotPresent)
- **Replicas**: 2 (production-like)
- **Debug**: Disabled
- **Resources**: Standard (100m CPU, 256Mi RAM)
- **Metrics**: Enabled
- **Tracing**: Enabled (10% sampling)
- **Ingress**: Yes (prod cert)
- **Security**: Pod security context enforced
- **Autoscaling**: 2-5 replicas
- **Vault**: HTTPS

### PROD
- **Image tag**: `stable` (IfNotPresent)
- **Replicas**: 3 (High Availability)
- **Debug**: Disabled
- **Resources**: High (250m CPU, 512Mi RAM)
- **Metrics**: Enabled
- **Tracing**: Enabled (5% sampling)
- **Ingress**: Yes (prod cert, multiple domains)
- **Security**: Hardened (read-only FS, non-root)
- **Autoscaling**: 3-10 replicas (CPU & Memory)
- **Pod Disruption Budget**: Min 2 available
- **Node Affinity**: production nodes only
- **Vault**: HTTPS
- **Sync Policy**: Manual (no auto-sync)

## 🚀 Quick Start

### 1. **Setup Vault**
```bash
# Apply Vault policies
kubectl apply -f vault/policies.yaml

# Setup K8s authentication
kubectl apply -f vault/k8s-auth-setup.sh
```

### 2. **Setup ArgoCD**
```bash
# Install ArgoCD (if not already installed)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply ArgoCD Applications
kubectl apply -f argocd/applications/
```

### 3. **Configure JFrog Credentials**
```bash
# Set GitLab CI/CD variables (in GitLab UI or CLI):
JFROG_REGISTRY=jfrog.artifactory.com
JFROG_USER=<your-user>
JFROG_PASSWORD=<your-password>
ARGOCD_SERVER=<argocd-server-url>
ARGOCD_TOKEN=<argocd-api-token>
SOARQUBE_URL=<sonarqube-url>
SOARQUBE_TOKEN=<sonarqube-token>
```

### 4. **Deploy Any Docker Image**

To deploy a different Docker image, simply update the ArgoCD Application manifest:

```yaml
# argocd/applications/app-dev.yaml
image:
  registry: jfrog.artifactory.com
  repository: my-custom-app  # Change this
  tag: "latest"
```

Or override at deployment time:
```bash
argocd app set python-app-dev \
  -p image.repository=my-custom-app \
  -p image.tag=v1.2.3
```

## 🔐 Vault Integration

### Secret Retrieval
Applications automatically authenticate to Vault using Kubernetes ServiceAccount:

1. Pod authenticates via K8s auth method
2. Vault returns a token
3. App reads secrets from `secret/data/{env}/*`
4. Database credentials from `database/creds/{env}-app`

### Example Python Code
```python
import hvac
import os

vault_addr = os.getenv('VAULT_ADDR')
vault_role = os.getenv('VAULT_ROLE')

client = hvac.Client(url=vault_addr)
secrets = client.secrets.kv.read_secret_version(path=f'secret/{vault_role}')
db_creds = secrets['data']['data']
```

## 📊 Monitoring & Metrics

### Prometheus Metrics
Metrics are exposed on `:8000/metrics` and scraped by Prometheus:

```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "8000"
prometheus.io/path: "/metrics"
```

### Health Checks
- **Liveness Probe**: `/health` (restart if unhealthy)
- **Readiness Probe**: `/ready` (remove from load balancer if not ready)
- **Startup Probe**: `/health` (wait for app startup, PROD only)

## 🔄 GitLab CI/CD Pipeline

### Stages
1. **build**: Unit tests + code quality scan
2. **test**: Pytest coverage
3. **scan**: SonarQube analysis
4. **deploy-dev**: Auto-deploy to DEV
5. **deploy-int**: Manual-sync to INT
6. **deploy-uat**: Manual-sync to UAT
7. **deploy-prod**: Manual-sync to PROD (main branch only)

### Pipeline Triggers
- **DEV**: Auto-deploy on `develop` branch push
- **INT/UAT/PROD**: Manual approval required
- **PROD**: `main` branch only + manual sync

## 🛠️ Customization

### Change Image Repository
```bash
# Update all ArgoCD apps
for env in dev int uat prod; do
  kubectl patch app python-app-$env -n argocd \
    -p '{"spec":{"source":{"helm":{"values":"image:\n  repository: my-app\n"}}}}'
done
```

### Modify Resource Limits
Edit Helm values in ArgoCD Application:
```yaml
resources:
  requests:
    cpu: 200m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 2Gi
```

### Add Environment Variables
```yaml
env:
  MY_VAR: "value"
  DATABASE_URL: "${DB_URL}"  # From Vault
```

## 📈 Scaling

### Horizontal Pod Autoscaling (HPA)

**INT/UAT**: 2-5 replicas (CPU 70%)
```yaml
minReplicas: 2
maxReplicas: 5
targetCPUUtilizationPercentage: 70
```

**PROD**: 3-10 replicas (CPU 70%, Memory 80%)
```yaml
minReplicas: 3
maxReplicas: 10
targetCPUUtilizationPercentage: 70
targetMemoryUtilizationPercentage: 80
```

## 🔒 Security

### Pod Security
- ✅ Non-root user (UID 1000)
- ✅ Read-only root filesystem (UAT/PROD)
- ✅ No privileged escalation
- ✅ Dropped all capabilities

### Network Security
- ✅ TLS/HTTPS for UAT/PROD
- ✅ Rate limiting on Ingress
- ✅ Network policies (custom, per env)

### Secret Management
- ✅ Vault for sensitive data
- ✅ K8s auth (no manual tokens)
- ✅ TTL-based credentials (1h default)
- ✅ Separate policies per environment

## 📝 Environment Variables Reference

### Common
| Variable | Example | Note |
|----------|---------|------|
| `ENVIRONMENT` | `dev` | Auto-set |
| `LOG_LEVEL` | `DEBUG` | Per environment |
| `DEBUG` | `false` | PROD only |
| `API_TIMEOUT` | `60` | Seconds |
| `DATABASE_POOL_SIZE` | `20` | Connections |

### Vault
| Variable | Value |
|----------|-------|
| `VAULT_ADDR` | `http://vault.vault.svc.cluster.local:8200` |
| `VAULT_ROLE` | `{env}-app` (dev-app, int-app, etc.) |
| `VAULT_TOKEN_FILE` | `/var/run/secrets/vault/token` |

## 🐛 Troubleshooting

### Pod not starting?
```bash
kubectl logs -f python-app-{env}-xxx -n {env}
kubectl describe pod python-app-{env}-xxx -n {env}
```

### ArgoCD sync failed?
```bash
argocd app get python-app-{env}
argocd app sync python-app-{env}
```

### Vault auth issues?
```bash
kubectl logs -f vault-0 -n vault
vault read auth/kubernetes/role/dev-app  # Check policy
```

## 📚 References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Vault Kubernetes Auth](https://www.vaultproject.io/docs/auth/kubernetes)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

## 👥 Contributing

1. Create a feature branch from `develop`
2. Make changes
3. Push to GitLab
4. Create Merge Request
5. Approval required for `main` branch (PROD)

## 📄 License

MIT License
