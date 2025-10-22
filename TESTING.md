# Testing the Probo Helm Chart

This guide explains how to test the Helm chart locally before deploying to production.

## Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) 3.8+
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- A Kubernetes cluster (kind, minikube, k3s, or cloud provider)

## Validation

### 1. Lint the Chart

```bash
cd deploy/helm
helm lint probo
```

### 2. Template Validation

Generate and review the Kubernetes manifests:

```bash
# Generate manifests with default values
helm template probo ./probo > /tmp/probo-manifests.yaml

# Review the output
cat /tmp/probo-manifests.yaml
```

### 3. Dry Run

Test the installation without actually deploying:

```bash
helm install probo ./probo \
  --dry-run \
  --debug \
  --set probo.encryptionKey="test-encryption-key-AAAAAAAAAAAAAAAAAAAA=" \
  --set probo.auth.cookieSecret="test-cookie-secret-AAAAAAAAAAAAAAAAAAAAAA=" \
  --set probo.auth.passwordPepper="test-password-pepper-AAAAAAAAAAAAAAAA=" \
  --set probo.trustAuth.tokenSecret="test-trust-token-secret-AAAAAAAAAAAAAAA="
```

## Local Testing

### Using kind (Kubernetes in Docker)

1. **Create a kind cluster:**

```bash
kind create cluster --name probo-test
```

2. **Generate secrets:**

```bash
export ENCRYPTION_KEY=$(openssl rand -base64 32)
export COOKIE_SECRET=$(openssl rand -base64 32)
export PASSWORD_PEPPER=$(openssl rand -base64 32)
export TRUST_TOKEN_SECRET=$(openssl rand -base64 32)
```

3. **Install the chart:**

```bash
helm install probo ./probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set probo.hostname="localhost:8080" \
  --set image.tag="latest"
```

4. **Wait for pods to be ready:**

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=probo --timeout=300s
```

5. **Port forward and test:**

```bash
kubectl port-forward svc/probo 8080:8080
# Visit http://localhost:8080
```

6. **Check logs:**

```bash
kubectl logs -f deployment/probo
```

### Using minikube

1. **Start minikube:**

```bash
minikube start
```

2. **Follow steps 2-6 from the kind section above**

## Testing Scenarios

### Test 1: Default Installation with Bundled Dependencies

```bash
helm install probo ./probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET"

# Verify all components are running
kubectl get pods
# Should show: probo, probo-postgresql, probo-minio, probo-chrome
```

### Test 2: External PostgreSQL

```bash
# First, deploy a test PostgreSQL
kubectl run postgres --image=postgres:17.4 \
  --env="POSTGRES_DB=probod" \
  --env="POSTGRES_USER=probod" \
  --env="POSTGRES_PASSWORD=testpass"

kubectl expose pod postgres --port=5432

# Install Probo with external PostgreSQL
helm install probo ./probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.enabled=false \
  --set postgresql.external.host=postgres \
  --set postgresql.external.password=testpass
```

### Test 3: Ingress Configuration

```bash
# Install nginx-ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Install Probo with ingress
helm install probo ./probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set probo.hostname="probo.local" \
  --set probo.auth.cookieDomain="probo.local" \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=probo.local \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix

# Add to /etc/hosts
echo "127.0.0.1 probo.local" | sudo tee -a /etc/hosts

# Test
curl http://probo.local
```

### Test 4: Autoscaling

```bash
# Install metrics-server (required for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Install with autoscaling enabled
helm install probo ./probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=5

# Check HPA
kubectl get hpa
```

## Verification Checklist

After installation, verify:

- [ ] All pods are running: `kubectl get pods`
- [ ] Service is accessible: `kubectl get svc`
- [ ] ConfigMap is created: `kubectl get configmap probo -o yaml`
- [ ] Secret is created: `kubectl get secret probo`
- [ ] Logs show no errors: `kubectl logs -f deployment/probo`
- [ ] Database connection works (check logs for migration messages)
- [ ] Application responds to HTTP requests
- [ ] Metrics endpoint is accessible: `curl http://localhost:8081/metrics`

## Cleanup

```bash
# Uninstall the release
helm uninstall probo

# Delete PVCs
kubectl delete pvc -l app.kubernetes.io/name=probo

# Delete test PostgreSQL (if created)
kubectl delete pod postgres
kubectl delete svc postgres

# Delete kind cluster
kind delete cluster --name probo-test

# Or stop minikube
minikube stop
minikube delete
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Database Connection Issues

```bash
# Check if PostgreSQL is ready
kubectl logs deployment/probo-postgresql

# Test connection from Probo pod
kubectl exec -it deployment/probo -- sh
# If the image doesn't have shell, check init container logs
kubectl logs deployment/probo -c wait-for-db
```

### Configuration Issues

```bash
# View the generated config
kubectl exec -it deployment/probo -- cat /etc/probo/config.yaml

# Check environment variables
kubectl exec -it deployment/probo -- env | grep -E '(DB_|S3_|ENCRYPTION_KEY|COOKIE_SECRET)'
```

### Image Pull Issues

```bash
# If using GHCR, you might need to authenticate
kubectl create secret docker-registry ghcr \
  --docker-server=ghcr.io \
  --docker-username=<github-username> \
  --docker-password=<github-token>

# Update values to use the secret
helm upgrade probo ./probo \
  --reuse-values \
  --set imagePullSecrets[0].name=ghcr
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test Helm Chart
on: [pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/setup-helm@v4
      - name: Lint chart
        run: helm lint deploy/helm/probo
      - name: Template chart
        run: |
          helm template probo deploy/helm/probo \
            --set probo.encryptionKey="test" \
            --set probo.auth.cookieSecret="test" \
            --set probo.auth.passwordPepper="test" \
            --set probo.trustAuth.tokenSecret="test"
```

## Package and Share

### Create Helm Package

```bash
helm package ./probo
# Creates: probo-0.1.0.tgz
```

### Create Helm Repository

```bash
# Create index
helm repo index . --url https://charts.getprobo.com

# Upload probo-0.1.0.tgz and index.yaml to your chart repository
```
