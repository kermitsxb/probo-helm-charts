# Probo Helm Chart - Quick Start

## Quick Local Testing with Included Services

The easiest way to test Probo on Kubernetes is using the included PostgreSQL and MinIO services.

### 1. Install Dependencies

```bash
cd /Users/thomas/Projets/Probo/probo-helm-charts/charts/probo
helm dependency update
```

### 2. Install with Test Values

```bash
cd /Users/thomas/Projets/Probo/probo-helm-charts/charts

helm install my-probo ./probo \
  -f probo/values-test.yaml \
  --namespace probo-test \
  --create-namespace
```

This installs:
- **Probo application** - Main application pod
- **PostgreSQL** - Bitnami PostgreSQL chart (testing only)
- **MinIO** - Bitnami MinIO chart (testing only)
- **Chrome** - Headless browser for PDF generation

### 3. Check Status

```bash
kubectl get pods -n probo-test

# Expected output:
# NAME                          READY   STATUS    RESTARTS   AGE
# my-probo-xxxxxxxxx-xxxxx      1/1     Running   0          1m
# my-probo-chrome-xxxxx-xxxxx   1/1     Running   0          1m
# my-probo-postgresql-0         1/1     Running   0          1m
# my-probo-minio-xxxxx-xxxxx    1/1     Running   0          1m
```

### 4. Access Probo

```bash
# Port-forward to access locally
kubectl port-forward -n probo-test svc/my-probo 8080:8080

# Open browser to http://localhost:8080
```

### 5. Verify Configuration

Check the generated config inside the pod:

```bash
kubectl exec -n probo-test deployment/my-probo -- cat /etc/probod/config.yml
```

You should see:
- Database: `my-probo-postgresql:5432`
- S3 endpoint: `http://my-probo-minio:9000`

### 6. View Logs

```bash
# Probo application logs
kubectl logs -n probo-test deployment/my-probo -f

# PostgreSQL logs
kubectl logs -n probo-test my-probo-postgresql-0 -f

# MinIO logs
kubectl logs -n probo-test deployment/my-probo-minio -f
```

### 7. Clean Up

```bash
helm uninstall my-probo --namespace probo-test
kubectl delete namespace probo-test
```

## Production Deployment

**Important:** Never use the included PostgreSQL or MinIO in production!

For production, disable the internal services and provide external ones:

```bash
# Generate secure secrets
export ENCRYPTION_KEY=$(openssl rand -base64 32)
export COOKIE_SECRET=$(openssl rand -base64 32)
export PASSWORD_PEPPER=$(openssl rand -base64 32)
export TRUST_TOKEN_SECRET=$(openssl rand -base64 32)

# Install with external services
helm install probo ./probo \
  --namespace probo-prod \
  --create-namespace \
  --set postgresql.enabled=false \
  --set postgresql.host="your-rds.amazonaws.com" \
  --set postgresql.password="secure-db-password" \
  --set minio.enabled=false \
  --set s3.bucket="your-s3-bucket" \
  --set s3.accessKeyId="AKIA..." \
  --set s3.secretAccessKey="..." \
  --set probo.hostname="probo.company.com" \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=probo.company.com
```

See `values-production.yaml.example` for a complete production configuration template.

## Troubleshooting

### Pods not starting

```bash
# Check events
kubectl get events -n probo-test --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod -n probo-test <pod-name>
```

### Database connection issues

```bash
# Test database connection
kubectl run -it --rm psql --image=postgres:17 --restart=Never -n probo-test -- \
  psql -h my-probo-postgresql -U probod -d probod
# Password: probod-test-password
```

### S3/MinIO connection issues

```bash
# Check MinIO is accessible
kubectl run -it --rm mc --image=minio/mc --restart=Never -n probo-test -- \
  mc alias set minio http://my-probo-minio:9000 minio-admin minio-test-password

kubectl run -it --rm mc --image=minio/mc --restart=Never -n probo-test -- \
  mc ls minio
```

## Next Steps

- Read the full [TESTING.md](./TESTING.md) guide for advanced testing scenarios
- Check [probo/README.md](./probo/README.md) for detailed configuration options
- Review `values-production.yaml.example` for production deployment
