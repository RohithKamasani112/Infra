# My App Helm Chart

This Helm chart deploys a containerized application to Kubernetes with support for multiple environments.

## Prerequisites

- Kubernetes cluster (EKS recommended)
- Helm 3.x installed
- kubectl configured to access your cluster
- AWS Load Balancer Controller installed in the cluster
- ECR repository with your application image

## Quick Start

### 1. ECR Registry Information (Already Configured)

Your ECR image is already configured:

```yaml
image:
  registry: "992878410375.dkr.ecr.ap-south-1.amazonaws.com"
  repository: "code_dev"
  tag: "latest"
```

### 2. Deploy to Development

```bash
# Make the deploy script executable
chmod +x deploy.sh

# Deploy to development environment
./deploy.sh dev my-app-dev my-app-dev
```

### 3. Deploy to Production

```bash
# Deploy to production environment
./deploy.sh prod my-app-prod my-app-prod
```

## Manual Deployment

### Install/Upgrade

```bash
# Development
helm upgrade --install my-app ./my-app \
  --namespace my-app-dev \
  --values ./my-app/values-dev.yaml \
  --create-namespace

# Production
helm upgrade --install my-app ./my-app \
  --namespace my-app-prod \
  --values ./my-app/values-prod.yaml \
  --create-namespace
```

### Uninstall

```bash
helm uninstall my-app --namespace my-app-dev
```

## Configuration

### Image Configuration

Update your ECR image details in the values files:

```yaml
image:
  registry: "123456789012.dkr.ecr.us-west-2.amazonaws.com"
  repository: "my-app"
  tag: "v1.0.0"
  pullPolicy: IfNotPresent
```

### Environment Variables

Configure environment variables in the values files:

```yaml
env:
  - name: NODE_ENV
    value: "production"
  - name: DATABASE_URL
    value: "postgresql://..."
```

### Ingress Configuration

Update the ingress configuration for your domain:

```yaml
ingress:
  enabled: true
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:region:account:certificate/cert-id"
  hosts:
    - host: my-app.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Resource Limits

Adjust resource limits based on your application needs:

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

## ECR Integration

### 1. Create ECR Repository

```bash
aws ecr create-repository --repository-name my-app --region us-west-2
```

### 2. Build and Push Docker Image

```bash
# Get ECR login token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com

# Build your image
docker build -t my-app .

# Tag for ECR
docker tag my-app:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest

# Push to ECR
docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest
```

### 3. Update Helm Values

Update the image tag in your values file and deploy:

```bash
# Update values-prod.yaml with new image tag
# Then deploy
./deploy.sh prod my-app-prod my-app-prod
```

## Monitoring and Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l "app.kubernetes.io/name=my-app" -n my-app-dev
```

### View Logs

```bash
kubectl logs -l "app.kubernetes.io/name=my-app" -n my-app-dev --tail=100 -f
```

### Check Ingress

```bash
kubectl get ingress -n my-app-dev
kubectl describe ingress my-app -n my-app-dev
```

### Check HPA (if enabled)

```bash
kubectl get hpa -n my-app-dev
kubectl describe hpa my-app -n my-app-dev
```

## Customization

### Adding Secrets

1. Create a secret in Kubernetes:
```bash
kubectl create secret generic my-app-secret \
  --from-literal=database-password=secretpassword \
  --namespace my-app-dev
```

2. Update values.yaml:
```yaml
secret:
  enabled: true
  data:
    database-password: "c2VjcmV0cGFzc3dvcmQ="  # base64 encoded
```

### Adding ConfigMaps

Update the configMap section in values.yaml:

```yaml
configMap:
  enabled: true
  data:
    app.properties: |
      server.port=8080
      database.host=localhost
      database.port=5432
```

### Persistent Storage

Enable persistence in values.yaml:

```yaml
persistence:
  enabled: true
  storageClass: "gp3"
  accessMode: ReadWriteOnce
  size: 20Gi
  mountPath: /app/data
```

## Environment-Specific Configurations

- **values-dev.yaml**: Development environment with debug logging, single replica
- **values-prod.yaml**: Production environment with multiple replicas, strict security, SSL
- **values.yaml**: Default values used as base configuration

## Security Features

- Non-root user execution
- Read-only root filesystem
- Security contexts
- Network policies (optional)
- Pod disruption budgets
- Resource limits

## Support

For issues and questions:
1. Check the pod logs
2. Verify ingress configuration
3. Check AWS Load Balancer Controller logs
4. Validate ECR image accessibility
