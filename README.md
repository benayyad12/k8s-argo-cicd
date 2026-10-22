# Kubernetes & ArgoCD Multi-Environment Deployment

Simple, practical setup to deploy any Docker application from JFrog to Kubernetes using ArgoCD.

## 📁 Quick Structure

```
.
├── README.md
├── .gitlab-ci.yml          # Build & Push to JFrog
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml         # Default values
│   ├── values-dev.yaml     # DEV overrides
│   ├── values-int.yaml     # INT overrides
│   ├── values-uat.yaml     # UAT overrides
│   └── values-prod.yaml    # PROD overrides
└── argocd/
    ├── app-dev.yaml        # DEV Application
    ├── app-int.yaml        # INT Application
    ├── app-uat.yaml        # UAT Application
    └── app-prod.yaml       # PROD Application
```

## 🚀 How to Use

### Step 1: Update Image Details

Edit `.gitlab-ci.yml` and set your image name:
```yaml
IMAGE_NAME: jfrog.artifactory.com/my-app  # Change this
```

### Step 2: Apply ArgoCD Applications

```bash
kubectl apply -f argocd/app-dev.yaml
kubectl apply -f argocd/app-int.yaml
kubectl apply -f argocd/app-uat.yaml
kubectl apply -f argocd/app-prod.yaml
```

### Step 3: Push Code & Watch Deployment

1. Push to `develop` branch → Auto-deploys to DEV
2. Merge to `main` → Manual approval for INT/UAT/PROD
3. ArgoCD auto-syncs and deploys

## 📝 Environment Differences

| | DEV | INT | UAT | PROD |
|---|---|---|---|---|
| **Image Tag** | latest | staging | staging | stable |
| **Replicas** | 1 | 2 | 2 | 3 |
| **Sync** | Auto | Manual | Manual | Manual |
| **Resources** | Low | Medium | Medium | High |
| **Ingress** | No | Yes | Yes | Yes |
| **Autoscaling** | No | Yes | Yes | Yes |

## 🔧 Customization

### Change Image for All Environments

Edit `helm/values.yaml`:
```yaml
image:
  registry: jfrog.artifactory.com
  repository: YOUR-APP-NAME  # Change this
  tag: latest
```

### Override for Specific Environment

Edit `helm/values-prod.yaml`:
```yaml
image:
  tag: stable
replicaCount: 3
```

### Add Environment Variables

Edit `helm/values-{env}.yaml`:
```yaml
env:
  LOG_LEVEL: INFO
  DATABASE_URL: "${DB_URL}"
  API_KEY: "${API_KEY}"
```

## ✅ Prerequisites

- Kubernetes cluster running
- ArgoCD installed: `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
- GitLab runner with Docker
- JFrog Artifactory access (username + password)

## 🔐 GitLab CI/CD Variables

Set these in GitLab project settings:

```
JFROG_REGISTRY = jfrog.artifactory.com
JFROG_USER = your-username
JFROG_PASSWORD = your-password
ARGOCD_SERVER = your-argocd-server
ARGOCD_PASSWORD = argocd-admin-password
SOARQUBE_URL = your-sonarqube-url (optional)
SOARQUBE_TOKEN = your-sonarqube-token (optional)
```

## 📋 Deployment Checklist

- [ ] Update `IMAGE_NAME` in `.gitlab-ci.yml`
- [ ] Update image repository in `helm/values.yaml`
- [ ] Set GitLab CI/CD variables
- [ ] Apply ArgoCD applications
- [ ] Push code to `develop` branch
- [ ] Check DEV deployment: `argocd app get app-dev`
- [ ] Create merge request to `main`
- [ ] Approve and sync INT/UAT/PROD manually

## 🐛 Troubleshooting

### Check ArgoCD Application Status
```bash
argocd app get app-dev
argocd app list
```

### View Application Logs
```bash
kubectl logs -f deployment/my-app -n dev
```

### Sync Application
```bash
argocd app sync app-dev
```

### See Pod Status
```bash
kubectl get pods -n dev -w
kubectl describe pod POD_NAME -n dev
```

## 📚 More Info

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Helm Docs](https://helm.sh/docs/)
- [JFrog Docs](https://jfrog.com/help/)

---

✨ **Done!** Your multi-environment K8s deployment is ready.
