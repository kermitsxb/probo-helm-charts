# Probo Kubernetes Deployment

This directory contains the Helm chart for deploying Probo on Kubernetes with external managed services.

## Quick Links

- [Helm Chart Documentation](charts/probo/README.md)
- [Values Reference](charts/probo/values.yaml)
- [Quick Start](QUICKSTART.md)

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
helm install probo probo/probo -n probo --create-namespace --values values.yaml
```

To update versions:

```
helm repo update probo
helm upgrade probo probo/probo -n probo --values values.yaml
```

#### Using Local Chart

##### Generate Secrets

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

##### Install using Chart and set values

```bash
helm install my-probo ./charts/probo \
  --set probo.hostname="probo.example.com" \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.enabled=true \
  --set postgres.auth.postgresUser="probod" \
  --set postgres.auth.postgresPassword="your-db-password" \
  --set postgres.auth.database="probod" \
  --set minio.enabled=true \
  --set s3.bucket="your-bucket-name" \
  --set s3.accessKeyId="your-access-key" \
  --set s3.secretAccessKey="your-secret-key"
```

##### Install using Chart and values file


```bash
helm install my-probo ./charts/probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  -f ./charts/probo/values.yaml
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
   cp charts/probo/values.yaml charts/probo/values-k8s-production.yaml
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
   helm install probo ./charts/probo -f ./charts/probo/values-k8s-production.yaml
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


## Cloud Provider Examples

### AWS
- PostgreSQL: Amazon RDS for PostgreSQL
- Storage: Amazon S3
- Kubernetes: Amazon EKS

#### Exemple
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
- PostgreSQL: Cloud SQL for PostgreSQL
- Storage: Cloud Storage with S3 compatibility
- Kubernetes: Google Kubernetes Engine (GKE)

#### Exemple

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

### Azure
- PostgreSQL: Azure Database for PostgreSQL
- Storage: Azure Blob Storage (with S3 compatibility)
- Kubernetes: Azure Kubernetes Service (AKS)

#### Exemple 


```bash
# Prerequisites:
# - Azure Database for PostgreSQL instance
# - Azure Blob Storage container with S3 compatibility
helm install my-probo ././charts/probo \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.host="mydb.postgres.database.azure.com" \
  --set postgresql.password="<azure-db-password>" \
  --set s3.endpoint="https://<your-storage-account>.blob.core.windows.net" \
  --set s3.bucket="my-probo-bucket" \
  --set s3.accessKeyId="<azure-access-key>" \
  --set s3.secretAccessKey="<azure-secret-key>"
```

### DigitalOcean
- PostgreSQL: Managed PostgreSQL Database
- Storage: DigitalOcean Spaces
- Kubernetes: DigitalOcean Kubernetes (DOKS)

#### Exemple
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
