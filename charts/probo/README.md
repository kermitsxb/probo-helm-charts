# Probo Helm Chart

This Helm chart deploys Probo - an open-source SOC-2 compliance platform - on Kubernetes.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- External PostgreSQL database (AWS RDS, GCP Cloud SQL, Azure Database, etc.)
- S3 or S3-compatible object storage (AWS S3, GCS, DigitalOcean Spaces, MinIO, etc.)

## Installing the Chart

### Generate Required Secrets

```bash
# Generate required secrets
export ENCRYPTION_KEY=$(openssl rand -base64 32)
export COOKIE_SECRET=$(openssl rand -base64 32)
export PASSWORD_PEPPER=$(openssl rand -base64 32)
export TRUST_TOKEN_SECRET=$(openssl rand -base64 32)

echo "Save these secrets securely!"
```

### Install

```bash
helm install probo ./deploy/helm/probo \
  --set probo.hostname="probo.example.com" \
  --set probo.encryptionKey="$ENCRYPTION_KEY" \
  --set probo.auth.cookieSecret="$COOKIE_SECRET" \
  --set probo.auth.passwordPepper="$PASSWORD_PEPPER" \
  --set probo.trustAuth.tokenSecret="$TRUST_TOKEN_SECRET" \
  --set postgresql.host="postgres.example.com" \
  --set postgresql.password="<db-password>" \
  --set s3.bucket="probo-production" \
  --set s3.accessKeyId="<aws-access-key-id>" \
  --set s3.secretAccessKey="<aws-secret-access-key>"
```

### Production Deployment

For production, create a `values-production.yaml` file:

```yaml
# values-production.yaml
image:
  repository: ghcr.io/getprobo/probo
  tag: "0.74.7"

replicaCount: 3

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: probo.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: probo-tls
      hosts:
        - probo.example.com

probo:
  hostname: "probo.example.com"
  encryptionKey: "<secret>"
  cors:
    allowedOrigins:
      - "https://probo.example.com"
  auth:
    cookieDomain: "example.com"
    cookieSecret: "<secret>"
    passwordPepper: "<secret>"
  trustAuth:
    cookieDomain: "example.com"
    tokenSecret: "<secret>"
  mailer:
    senderEmail: "noreply@example.com"
    smtp:
      addr: "smtp.sendgrid.net:587"
      user: "apikey"
      password: "<smtp-password>"
      tlsRequired: true

postgresql:
  host: "postgres.example.com"
  password: "<db-password>"

s3:
  region: "us-east-1"
  bucket: "probo-production"
  accessKeyId: "<aws-access-key-id>"
  secretAccessKey: "<aws-secret-access-key>"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
```

Install with:

```bash
helm install probo ./deploy/helm/probo -f values-production.yaml
```

## Configuration

### Required Configuration

The following parameters **must** be configured:

| Parameter | Description |
|-----------|-------------|
| `probo.encryptionKey` | Base64-encoded encryption key (32+ bytes) |
| `probo.auth.cookieSecret` | Cookie signing secret (32+ bytes) |
| `probo.auth.passwordPepper` | Password hashing pepper (32+ bytes) |
| `probo.trustAuth.tokenSecret` | Trust token secret (32+ bytes) |
| `postgresql.host` | PostgreSQL hostname |
| `postgresql.password` | PostgreSQL password |
| `s3.accessKeyId` | S3 access key ID |
| `s3.secretAccessKey` | S3 secret access key |

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Probo image repository | `ghcr.io/getprobo/probo` |
| `image.tag` | Probo image tag | Chart appVersion |
| `replicaCount` | Number of Probo replicas | `1` |
| `probo.hostname` | Public hostname | `probo.example.com` |
| `postgresql.host` | PostgreSQL host | `""` (required) |
| `postgresql.port` | PostgreSQL port | `5432` |
| `postgresql.database` | Database name | `probod` |
| `postgresql.username` | Database user | `probod` |
| `s3.bucket` | S3 bucket name | `probod` |
| `s3.region` | AWS region | `us-east-1` |
| `s3.endpoint` | S3 endpoint (for S3-compatible) | `""` |
| `chrome.enabled` | Deploy Chrome | `true` |
| `chrome.external.addr` | External Chrome (if disabled) | `""` |
| `ingress.enabled` | Enable ingress | `false` |

See [values.yaml](values.yaml) for all available options.

## Components

The chart deploys the following:

- **Probo Application**: Main Go binary serving GraphQL APIs and SPAs
- **Chrome Headless**: For PDF generation (optional, can use external)
- **Ingress**: For external access with TLS (optional)

### External Dependencies (Required)

- **PostgreSQL**: Managed database service
- **S3 Storage**: Object storage for files and documents

## Database Management

### Migrations

Database migrations run automatically when Probo starts. No manual intervention is required.

### Backup

Use your PostgreSQL provider's backup solution (e.g., AWS RDS automated backups, GCP Cloud SQL backups).

## Upgrading

```bash
helm upgrade probo ./deploy/helm/probo -f values-production.yaml
```

## Uninstalling

```bash
helm uninstall probo
```

**Note:** This does not delete your external PostgreSQL database or S3 bucket.

## Troubleshooting

### View Logs

```bash
kubectl logs -f deployment/probo
```

### Check Configuration

```bash
kubectl describe configmap probo
kubectl get secret probo -o yaml
```

### Test Database Connection

Check the Probo logs for database connection errors. The application will fail to start if it cannot connect to PostgreSQL.

### Test S3 Connection

Check the Probo logs for S3 connection errors when uploading files.

## Examples

### AWS Deployment

```yaml
postgresql:
  host: "mydb.abc123.us-east-1.rds.amazonaws.com"
  password: "<rds-password>"

s3:
  region: "us-east-1"
  bucket: "my-probo-bucket"
  accessKeyId: "<aws-key>"
  secretAccessKey: "<aws-secret>"
  # Leave endpoint empty for AWS S3
```

### GCP Deployment

```yaml
postgresql:
  host: "10.0.0.5"  # Cloud SQL private IP
  password: "<cloudsql-password>"

s3:
  region: "us-east1"
  bucket: "my-probo-bucket"
  endpoint: "https://storage.googleapis.com"
  accessKeyId: "<hmac-access-key>"
  secretAccessKey: "<hmac-secret>"
```

### DigitalOcean Deployment

```yaml
postgresql:
  host: "db-postgresql-nyc1-12345.ondigitalocean.com"
  password: "<db-password>"

s3:
  region: "nyc3"
  bucket: "my-probo-bucket"
  endpoint: "https://nyc3.digitaloceanspaces.com"
  accessKeyId: "<spaces-access-key>"
  secretAccessKey: "<spaces-secret>"

```

### Using External Chrome Service

By default, Chrome is deployed in the cluster. To use an external Chrome service:

```yaml
chrome:
  enabled: false
  external:
    addr: "chrome.browserless.io:3000"
```

## Security Best Practices

1. **Use External Secrets**: Integrate with External Secrets Operator, Sealed Secrets, or cloud provider secret management
2. **Enable TLS**: Always use HTTPS in production via Ingress + cert-manager
3. **Network Policies**: Implement Kubernetes Network Policies to restrict traffic
4. **Database Encryption**: Use encrypted connections to PostgreSQL (set `postgresql.caCertBundle` if needed)
5. **Regular Updates**: Keep the Probo image updated with security patches
6. **RBAC**: Use minimal service account permissions

## Support

- GitHub: https://github.com/getprobo/probo
- Discord: https://discord.gg/8qfdJYfvpY
- Website: https://getprobo.com

## License

MIT License - see the [LICENSE](../../../LICENSE) file for details.
