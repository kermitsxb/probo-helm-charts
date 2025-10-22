# Helm Chart Local Testing Guide

This guide shows you how to test the Probo Helm chart locally without needing to push it to a Helm repository.

## Prerequisites

- Helm 3.x installed
- kubectl configured (for actual installations)
- A Kubernetes cluster (for actual installations): minikube, kind, k3s, or remote cluster

## Testing Methods

### 1. Validate Chart Structure

Check if the chart is well-formed:

```bash
cd /Users/thomas/Projets/Probo/probo-helm-charts/charts
helm lint probo
```

### 2. Render Templates (Dry Run)

See what Kubernetes manifests would be generated without installing:

```bash
# Using test values file
helm template my-probo ./charts/probo -f probo/values-test.yaml --namespace probo-test

# Show only specific template
helm template my-probo ./charts/probo -f probo/values-test.yaml --show-only templates/configmap.yaml

# Show only deployment
helm template my-probo ./charts/probo -f probo/values-test.yaml --show-only templates/deployment.yaml
```

### 3. View Generated Config File

Check the generated `/etc/probod/config.yml`:

```bash
helm template my-probo ./charts/probo -f probo/values-test.yaml \
  --show-only templates/configmap.yaml | grep -A 100 "config.yml:"
```

### 4. Install in a Test Namespace

Actually install the chart in a Kubernetes cluster:

```bash
# Create test namespace
kubectl create namespace probo-test

# Install chart
helm install my-probo ./charts/probo \
  -f probo/values-test.yaml \
  --namespace probo-test

# Check installation status
helm status my-probo --namespace probo-test

# List resources
kubectl get all -n probo-test

# Check the ConfigMap
kubectl get configmap my-probo -n probo-test -o yaml

# Check the generated config inside the pod
kubectl exec -n probo-test deployment/my-probo -- cat /etc/probod/config.yml
```

### 5. Upgrade Installation

Test upgrading the chart:

```bash
# Make changes to values or templates, then:
helm upgrade my-probo ./charts/probo \
  -f probo/values-test.yaml \
  --namespace probo-test

# Or use upgrade with install flag
helm upgrade --install my-probo ./charts/probo \
  -f probo/values-test.yaml \
  --namespace probo-test
```

### 6. Diff Before Upgrade

See what would change before upgrading (requires helm-diff plugin):

```bash
# Install plugin if needed
helm plugin install https://github.com/databus23/helm-diff

# Show diff
helm diff upgrade my-probo ./charts/probo \
  -f probo/values-test.yaml \
  --namespace probo-test
```

### 7. Test with Different Values

Override specific values for testing:

```bash
# Enable persistence
helm template my-probo ./charts/probo \
  -f probo/values-test.yaml \
  --set persistence.enabled=true \
  --set persistence.size=5Gi

# Disable Chrome
helm template my-probo ./charts/probo \
  -f probo/values-test.yaml \
  --set chrome.enabled=false \
  --set chrome.external.addr="external-chrome:9222"

# Enable tracing
helm template my-probo ./charts/probo \
  -f probo/values-test.yaml \
  --set probo.tracing.enabled=true \
  --set probo.tracing.addr="tempo:4317"
```

### 8. Package Chart

Create a `.tgz` package:

```bash
cd /Users/thomas/Projets/Probo/probo-helm-charts/charts
helm package probo
# Creates: probo-0.1.0.tgz
```

### 9. Install from Package

Install from the packaged chart:

```bash
helm install my-probo probo-0.1.0.tgz \
  -f probo/values-test.yaml \
  --namespace probo-test
```

### 10. Uninstall

Clean up test installation:

```bash
helm uninstall my-probo --namespace probo-test
kubectl delete namespace probo-test
```

## Testing Specific Features

### Test Persistence

```bash
# With persistence enabled
helm template test-pvc ./charts/probo \
  -f probo/values-test.yaml \
  --set persistence.enabled=true \
  --show-only templates/pvc.yaml

# With existing claim
helm template test-pvc ./charts/probo \
  -f probo/values-test.yaml \
  --set persistence.enabled=true \
  --set persistence.existingClaim="my-existing-pvc" \
  --show-only templates/pvc.yaml
```

### Test Ingress

```bash
helm template test-ingress ./charts/probo \
  -f probo/values-test.yaml \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=probo.example.com \
  --show-only templates/ingress.yaml
```

### Test Autoscaling

```bash
helm template test-hpa ./charts/probo \
  -f probo/values-test.yaml \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=5 \
  --show-only templates/hpa.yaml
```

### Test Service Monitor (Prometheus)

```bash
helm template test-metrics ./charts/probo \
  -f probo/values-test.yaml \
  --set metrics.serviceMonitor.enabled=true \
  --show-only templates/servicemonitor.yaml
```

## Quick Test Commands

```bash
# Full dry-run with all templates
cd /Users/thomas/Projets/Probo/probo-helm-charts/charts
helm template my-probo ./charts/probo -f probo/values-test.yaml > /tmp/probo-manifests.yaml

# View the generated manifests
cat /tmp/probo-manifests.yaml

# Count resources
grep -c "^kind:" /tmp/probo-manifests.yaml

# Install for real testing
helm install my-probo ./charts/probo -f probo/values-test.yaml -n probo-test --create-namespace

# Watch pod startup
kubectl get pods -n probo-test -w

# View logs
kubectl logs -n probo-test deployment/my-probo -f

# Port-forward to access locally
kubectl port-forward -n probo-test svc/my-probo 8080:8080
```

## Verifying Config Generation

To verify the config file is correctly mounted in the container:

```bash
# Exec into the pod
kubectl exec -it -n probo-test deployment/my-probo -- sh

# Inside the container:
ls -la /etc/probod/
cat /etc/probod/config.yml

# Check if probod is using the config
ps aux | grep probod
```

## Common Issues

### Chart not linting

```bash
# Check for template syntax errors
helm lint probo --debug
```

### Templates not rendering

```bash
# Add --debug flag to see detailed errors
helm template my-probo ./charts/probo -f probo/values-test.yaml --debug
```

### Missing required values

Ensure all required values are set in your values file or via `--set` flags:
- `probo.encryptionKey`
- `probo.auth.cookieSecret`
- `probo.auth.passwordPepper`
- `probo.trustAuth.tokenSecret`
- `postgresql.host`
- `postgresql.password`
- `s3.accessKeyId`
- `s3.secretAccessKey`

## Next Steps

Once local testing is complete:
1. Push chart to a Helm repository (ChartMuseum, Harbor, GitHub Pages, etc.)
2. Use in CI/CD pipelines
3. Deploy to staging/production environments
