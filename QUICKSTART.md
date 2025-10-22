# Probo Helm Chart - Quick Start Guide

## Prerequisites

Before you begin, ensure you have:
- ✅ Kubernetes cluster (1.23+)
- ✅ Helm installed (3.8+)
- ✅ PostgreSQL database (managed service recommended)
- ✅ S3 or S3-compatible storage

## Deploy in 3 Steps

### Step 1: Generate Secrets

```bash
export ENCRYPTION_KEY=$(openssl rand -base64 32)
export COOKIE_SECRET=$(openssl rand -base64 32)
export PASSWORD_PEPPER=$(openssl rand -base64 32)
export TRUST_TOKEN_SECRET=$(openssl rand -base64 32)

# Save these somewhere secure!
echo "ENCRYPTION_KEY=$ENCRYPTION_KEY"
echo "COOKIE_SECRET=$COOKIE_SECRET"
echo "PASSWORD_PEPPER=$PASSWORD_PEPPER"
echo "TRUST_TOKEN_SECRET=$TRUST_TOKEN_SECRET"
```

### Step 2: Install

```bash
helm install my-probo ./charts/probo \
  --set probo.hostname="probo.example.com" \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.host="your-postgres-host.com" \
  --set postgresql.password="your-db-password" \
  --set s3.bucket="your-bucket-name" \
  --set s3.accessKeyId="your-access-key" \
  --set s3.secretAccessKey="your-secret-key"
```

### Step 3: Access

```bash
kubectl port-forward svc/my-probo 8080:8080
```

Then visit: **http://localhost:8080**

## Production Deployment

For production, use a values file:

```bash
# 1. Copy the example
cp ./charts/probo/values-production.yaml.example values-prod.yaml

# 2. Edit values-prod.yaml with your settings

# 3. Install
helm install my-probo ././charts/probo -f values-prod.yaml
```

## Common Tasks

### View Logs
```bash
kubectl logs -f deployment/probo
```

### Check Status
```bash
kubectl get pods
kubectl get svc
```

### Upgrade
```bash
helm upgrade probo ././charts/probo -f values-prod.yaml
```

### Uninstall
```bash
helm uninstall my-probo
```

## Cloud Provider Quick Setup

### AWS

```bash
# Prerequisites:
# - Amazon RDS PostgreSQL instance
# - S3 bucket created

helm install my-probo ././charts/probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.host="mydb.abc123.us-east-1.rds.amazonaws.com" \
  --set postgresql.password="<rds-password>" \
  --set s3.region="us-east-1" \
  --set s3.bucket="my-probo-bucket" \
  --set s3.accessKeyId="<aws-access-key>" \
  --set s3.secretAccessKey="<aws-secret-key>"
```

### GCP

```bash
# Prerequisites:
# - Cloud SQL PostgreSQL instance
# - Cloud Storage bucket with HMAC keys

helm install my-probo ././charts/probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.host="10.0.0.5" \
  --set postgresql.password="<cloudsql-password>" \
  --set s3.endpoint="https://storage.googleapis.com" \
  --set s3.bucket="my-probo-bucket" \
  --set s3.accessKeyId="<hmac-access-key>" \
  --set s3.secretAccessKey="<hmac-secret>"
```

### DigitalOcean

```bash
# Prerequisites:
# - Managed PostgreSQL Database
# - Spaces bucket

helm install my-probo ././charts/probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.host="db-postgresql-nyc1-12345.ondigitalocean.com" \
  --set postgresql.password="<db-password>" \
  --set s3.region="nyc3" \
  --set s3.endpoint="https://nyc3.digitaloceanspaces.com" \
  --set s3.bucket="my-probo-bucket" \
  --set s3.accessKeyId="<spaces-key>" \
  --set s3.secretAccessKey="<spaces-secret>"
```

## Troubleshooting

### Pod Not Starting?

```bash
# Check logs
kubectl logs deployment/probo

# Describe pod
kubectl describe pod -l app.kubernetes.io/name=probo
```

### Database Connection Issues?

```bash
# Test connection from cluster
kubectl run -it --rm debug --image=postgres:17 --restart=Never -- \
  psql -h <your-db-host> -U probod -d probod
```

### Need Help?

- 📖 [Full Documentation](charts/probo/README.md)
- 🧪 [Testing Guide](TESTING.md)
- 💬 [Discord](https://discord.gg/8qfdJYfvpY)
- 🐛 [GitHub Issues](https://github.com/getprobo/probo/issues)

## Next Steps

1. ✅ Configure ingress for external access
2. ✅ Enable TLS with cert-manager
3. ✅ Set up SMTP for email delivery
4. ✅ Configure autoscaling for production
5. ✅ Set up monitoring with Prometheus
