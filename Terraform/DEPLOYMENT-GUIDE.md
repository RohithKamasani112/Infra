# Complete Deployment Guide

## 🎯 Overview

This guide will help you deploy your application (`992878410375.dkr.ecr.ap-south-1.amazonaws.com/code_dev:latest`) to your EKS cluster using Helm charts and set up ArgoCD for GitOps.

## 📋 Prerequisites

✅ **EKS Cluster**: `my-eks-cluster` (Running)  
✅ **AWS Load Balancer Controller**: Installed  
✅ **ECR Image**: `992878410375.dkr.ecr.ap-south-1.amazonaws.com/code_dev:latest`  
✅ **Helm Charts**: Created and configured  

## 🚀 Deployment Steps

### Step 1: Configure kubectl for EKS

```bash
# Configure kubectl to use your EKS cluster
aws eks update-kubeconfig --region ap-south-1 --name my-eks-cluster

# Verify connection
kubectl get nodes
```

### Step 2: Deploy Application with Helm

```bash
# Navigate to helm directory
cd helm

# Make deploy script executable
chmod +x deploy.sh

# Deploy using quick deploy script
./quick-deploy.sh

# Or deploy manually
helm upgrade --install code-dev-app ./my-app \
  --namespace code-dev \
  --values ./my-app/values.yaml \
  --create-namespace
```

### Step 3: Verify Deployment

```bash
# Check pods
kubectl get pods -n code-dev

# Check service
kubectl get svc -n code-dev

# Check ingress (ALB)
kubectl get ingress -n code-dev

# View logs
kubectl logs -l app.kubernetes.io/name=my-app -n code-dev
```

### Step 4: Access Your Application

```bash
# Get ALB DNS name
kubectl get ingress -n code-dev -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'

# Your application will be accessible at:
# http://[ALB-DNS-NAME]
```

## 🔄 GitOps with ArgoCD

### Step 1: Install ArgoCD

```bash
# Navigate to argocd directory
cd argocd

# Make setup script executable
chmod +x setup-argocd.sh

# Run ArgoCD setup
./setup-argocd.sh
```

### Step 2: Access ArgoCD UI

```bash
# Port forward to ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Visit: https://localhost:8080
# Username: admin
# Password: (provided by setup script)
```

### Step 3: Configure Git Repository

1. **Push your code to Git repository**:
```bash
git add .
git commit -m "Add Helm charts and ArgoCD configuration"
git push origin main
```

2. **Update ArgoCD application**:
Edit `argocd/application.yaml` and update the Git repository URL:
```yaml
source:
  repoURL: https://github.com/your-username/your-repo.git
```

3. **Deploy ArgoCD application**:
```bash
kubectl apply -f argocd/application.yaml
```

### Step 4: Monitor GitOps Deployment

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# View application details
kubectl describe application code-dev-app -n argocd
```

## 🔧 Configuration Details

### Current Image Configuration
```yaml
image:
  registry: "992878410375.dkr.ecr.ap-south-1.amazonaws.com"
  repository: "code_dev"
  tag: "latest"
```

### Cluster Information
```yaml
cluster_endpoint: "https://B31D14B61F47CAD3CC9C3FEE9DD319C8.gr7.us-west-2.eks.amazonaws.com"
cluster_name: "my-eks-cluster"
vpc_id: "vpc-0907daf9696d0b68b"
```

### Network Configuration
- **Public Subnets**: `subnet-07d3be7e07c1b4a8e`, `subnet-07767866c137382c6`
- **Private Subnets**: `subnet-0f9e062cc874c6832`, `subnet-0a057ce17f4cdcbb2`
- **Region**: `ap-south-1`

## 📊 Monitoring and Troubleshooting

### Check Application Health
```bash
# Pod status
kubectl get pods -n code-dev

# Application logs
kubectl logs -l app.kubernetes.io/name=my-app -n code-dev --tail=100

# Service endpoints
kubectl get endpoints -n code-dev

# Ingress status
kubectl describe ingress -n code-dev
```

### Common Issues and Solutions

#### 1. Image Pull Errors
```bash
# Check ECR permissions
aws ecr describe-repositories --region ap-south-1

# Verify image exists
aws ecr describe-images --repository-name code_dev --region ap-south-1
```

#### 2. ALB Not Creating
```bash
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

#### 3. Pod Not Starting
```bash
# Describe pod for events
kubectl describe pod [POD-NAME] -n code-dev

# Check resource limits
kubectl top pods -n code-dev
```

## 🔄 Update Workflow

### Manual Updates
```bash
# Update image tag in values file
# Deploy new version
helm upgrade code-dev-app ./my-app \
  --namespace code-dev \
  --values ./my-app/values.yaml
```

### GitOps Updates (with ArgoCD)
```bash
# 1. Update image tag in values.yaml
# 2. Commit and push to Git
git add .
git commit -m "Update to version X.Y.Z"
git push origin main

# 3. ArgoCD automatically syncs changes
# 4. Monitor in ArgoCD UI
```

## 🏗️ Production Deployment

### Deploy to Production
```bash
# Deploy to production namespace using single values.yaml
# You can override specific values for production using --set flags
helm upgrade --install code-dev-prod-app ./my-app \
  --namespace code-dev-prod \
  --values ./my-app/values.yaml \
  --set replicaCount=3 \
  --set env[0].value="production" \
  --create-namespace
```

### Production Considerations
- Use specific image tags (not `latest`)
- Configure SSL certificates for ingress
- Set up monitoring and alerting
- Configure backup strategies
- Implement proper RBAC

## 📚 Additional Resources

- **Helm Documentation**: [helm.sh](https://helm.sh/docs/)
- **ArgoCD Documentation**: [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/)
- **AWS Load Balancer Controller**: [kubernetes-sigs.github.io](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- **EKS Best Practices**: [aws.github.io/aws-eks-best-practices/](https://aws.github.io/aws-eks-best-practices/)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review pod logs and events
3. Verify AWS permissions and resources
4. Check network connectivity and security groups

## 🎉 Success Checklist

- [ ] EKS cluster is accessible
- [ ] Application deployed via Helm
- [ ] ALB ingress is working
- [ ] Application is accessible externally
- [ ] ArgoCD is installed and configured
- [ ] GitOps workflow is set up
- [ ] Monitoring is in place
