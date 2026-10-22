# Vault Kubernetes Auth Configuration
# Enable K8s auth for service accounts

apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-k8s-auth-config
  namespace: vault
data:
  config.sh: |
    #!/bin/bash
    set -e
    
    VAULT_ADDR=${VAULT_ADDR:-http://vault.vault.svc.cluster.local:8200}
    VAULT_TOKEN=${VAULT_TOKEN}
    
    # Enable K8s auth method
    vault auth enable kubernetes || true
    
    # Configure K8s auth
    vault write auth/kubernetes/config \
      kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" \
      kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
      token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token
    
    # Create roles for each environment
    for ENV in dev int uat prod; do
      vault write auth/kubernetes/role/${ENV}-app \
        bound_service_account_names=python-app-${ENV} \
        bound_service_account_namespaces=${ENV} \
        policies=${ENV}-app \
        ttl=1h
    done
