# Probo Kubernetes Deployment

This directory contains the Helm chart for deploying Probo on Kubernetes with external managed services.

## Quick Links

- [Helm Chart Documentation](charts/probo/README.md)
- [Values Reference](charts/probo/values.yaml)
- [Production Example](charts/probo/values-production.yaml.example)
- [Quick Start](QUICKSTART.md)
- [Testing Guide](TESTING.md)

## Prerequisites

Before deploying Probo, ensure you have:

1. **Kubernetes Cluster** - Version 1.23+
2. **Helm** - Version 3.8+
3. **PostgreSQL Database** - Managed service (AWS RDS, GCP Cloud SQL, Azure Database, etc.)
4. **S3 Storage** - AWS S3 or S3-compatible storage (GCS, DigitalOcean Spaces, MinIO, etc.)

## Quick Start

### 1. Generate Secrets

```bash
export ENCRYPTION_KEY=$(openssl rand -base64 32)
export COOKIE_SECRET=$(openssl rand -base64 32)
export PASSWORD_PEPPER=$(openssl rand -base64 32)
export TRUST_TOKEN_SECRET=$(openssl rand -base64 32)

echo "Save these secrets securely!"
```

### 2. Install

## Install

#### Using Official Chart Repository
> Have Helm 3 [installed](https://helm.sh/docs/intro/install).

```sh
helm repo add probo https://getprobo.github.io/probo-helm-charts/
helm install myprobo probo/probo -n probo --create-namespace --values values.yaml
```

To update versions:

```
helm repo update probo
helm upgrade myprobo probo/probo -n probo --values values.yaml
```

#### Using Local Chart

```bash
helm install probo ./charts/probo \
  --set probo.hostname="probo.example.com" \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.host="your-postgres-host" \
  --set postgresql.password="<db-password>" \
  --set s3.bucket="your-bucket" \
  --set s3.accessKeyId="<access-key>" \
  --set s3.secretAccessKey="<secret-key>"
```

### 3. Access

```bash
kubectl port-forward svc/probo 8080:8080
# Visit http://localhost:8080
```

## Production Deployment

For production deployments, we recommend:

1. **Copy the production template:**
   ```bash
   cp probo/values-production.yaml.example values-production.yaml
   ```

2. **Edit the configuration:**
   - Set your domain name
   - Configure external PostgreSQL connection
   - Configure S3 storage credentials
   - Add SMTP settings for email
   - Enable ingress with TLS
   - Configure autoscaling

3. **Install:**
   ```bash
   helm install probo ./probo -f values-production.yaml
   ```

## Architecture

### What Gets Deployed

- **Probo Application** - Main Go binary serving GraphQL APIs and React frontends
- **Chrome Headless** - For PDF generation (optional, can use external service)
- **Ingress** - For external access with TLS (optional)

### External Dependencies (Required)

- **PostgreSQL** - Managed database for compliance data
- **S3 Storage** - Object storage for files and documents

The chart is designed to work with managed cloud services, ensuring reliability and scalability.

## Configuration

### Required Configuration

All deployments require:

- `probo.encryptionKey` - For data encryption at rest
- `probo.auth.cookieSecret` - For session management
- `probo.auth.passwordPepper` - For password hashing
- `probo.trustAuth.tokenSecret` - For trust center tokens
- `postgresql.host` - PostgreSQL server hostname
- `postgresql.password` - Database password
- `s3.accessKeyId` - S3 access credentials
- `s3.secretAccessKey` - S3 secret key

See [values.yaml](charts/probo/values.yaml) for all available options.

## Common Operations

### View Logs
```bash
kubectl logs -f deployment/probo
```

### Upgrade
```bash
helm upgrade probo ./charts/probo -f values-production.yaml
```

### Uninstall
```bash
helm uninstall probo
```

## Cloud Provider Examples

### AWS
- PostgreSQL: Amazon RDS for PostgreSQL
- Storage: Amazon S3
- Kubernetes: Amazon EKS

### GCP
- PostgreSQL: Cloud SQL for PostgreSQL
- Storage: Cloud Storage with S3 compatibility
- Kubernetes: Google Kubernetes Engine (GKE)

### Azure
- PostgreSQL: Azure Database for PostgreSQL
- Storage: Azure Blob Storage (with S3 compatibility)
- Kubernetes: Azure Kubernetes Service (AKS)

### DigitalOcean
- PostgreSQL: Managed PostgreSQL Database
- Storage: DigitalOcean Spaces
- Kubernetes: DigitalOcean Kubernetes (DOKS)

## Troubleshooting

### Application Won't Start

Check the logs:
```bash
kubectl logs deployment/probo
```

Common issues:
- Database connection failure (check host, password, network)
- S3 credentials invalid (check access key and secret)
- Missing required secrets (check all secrets are set)

### Connection Issues

Test connectivity from within the cluster:
```bash
# Test PostgreSQL connection
kubectl run -it --rm debug --image=postgres:17 --restart=Never -- \
  psql -h <postgresql.host> -U <postgresql.username> -d <postgresql.database>

# Test S3 access (requires AWS CLI)
kubectl run -it --rm aws-cli --image=amazon/aws-cli --restart=Never -- \
  s3 ls s3://<bucket-name>
```

## Security

### Best Practices

1. **Secrets Management**: Use External Secrets Operator or cloud provider's secret management
2. **Network Security**: Implement Network Policies to restrict pod communication
3. **TLS**: Always enable TLS via Ingress + cert-manager for production
4. **Database**: Use SSL/TLS connections to PostgreSQL
5. **RBAC**: Use minimal required permissions for service accounts
6. **Updates**: Keep Probo and dependencies updated

### Using External Secrets Operator

Example with AWS Secrets Manager:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: probo-secrets
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: probo
  data:
    - secretKey: encryption-key
      remoteRef:
        key: probo/encryption-key
    - secretKey: db-password
      remoteRef:
        key: probo/db-password
```

## Support

- **Documentation**: https://github.com/getprobo/probo
- **Issues**: https://github.com/getprobo/probo/issues
- **Discord**: https://discord.gg/8qfdJYfvpY
- **Website**: https://getprobo.com
