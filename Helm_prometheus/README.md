# Prometheus and Grafana Monitoring Stack for EKS

This Helm chart deploys a complete monitoring stack with Prometheus and Grafana on your Amazon EKS cluster, configured to work with AWS Application Load Balancer (ALB) for external access.

## 🚀 Features

- **Prometheus Server** - Metrics collection and storage
- **Grafana** - Visualization and dashboards
- **AlertManager** - Alert handling and notifications
- **Node Exporter** - Node-level metrics
- **Kube State Metrics** - Kubernetes cluster metrics
- **AWS ALB Integration** - External access via Application Load Balancer
- **Multi-environment support** - Development and Production configurations
- **Pre-configured dashboards** - Ready-to-use Kubernetes monitoring dashboards
- **Persistent storage** - Data retention across pod restarts
- **High availability** - Production-ready configurations

## 📋 Prerequisites

1. **EKS Cluster** with AWS Load Balancer Controller installed
2. **kubectl** configured to access your cluster
3. **Helm 3.x** installed
4. **Appropriate IAM permissions** for ALB creation
5. **Storage classes** available (gp2/gp3)

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Internet      │    │   AWS ALB       │    │   EKS Cluster   │
│   Users         │───▶│   Load Balancer │───▶│   Monitoring    │
│                 │    │                 │    │   Stack         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                       ┌─────────────────┬─────────────┼─────────────────┐
                       │                 │             │                 │
                ┌──────▼──────┐   ┌──────▼──────┐   ┌──▼──────┐   ┌─────▼─────┐
                │ Prometheus  │   │   Grafana   │   │ Alert   │   │   Node    │
                │   Server    │   │             │   │ Manager │   │ Exporter  │
                └─────────────┘   └─────────────┘   └─────────┘   └───────────┘
```

## 🚀 Quick Start

### 1. Clone and Navigate
```bash
cd helm_prometheus
```

### 2. Deploy Monitoring Stack

#### For Development Environment:
```bash
./deploy-monitoring.sh deploy dev
```

#### For Production Environment:
```bash
./deploy-monitoring.sh deploy prod
```

### 3. Access the Services

After deployment, the script will show you the access URLs:

- **Prometheus**: `http://<alb-url>/` - Metrics and queries
- **Grafana**: `http://<alb-url>/` - Dashboards and visualization
- **AlertManager**: `http://<alb-url>/` - Alert management

## 📁 Directory Structure

```
helm_prometheus/
├── prometheus-grafana/           # Main Helm chart
│   ├── Chart.yaml               # Chart metadata
│   ├── values.yaml              # Default values
│   ├── values-dev.yaml          # Development overrides
│   ├── values-prod.yaml         # Production overrides
│   └── templates/               # Kubernetes templates
│       ├── _helpers.tpl         # Template helpers
│       ├── serviceaccount.yaml  # Service account
│       ├── prometheus-ingress.yaml
│       ├── grafana-ingress.yaml
│       ├── alertmanager-ingress.yaml
│       └── NOTES.txt           # Post-install notes
├── deploy-monitoring.sh         # Deployment script
└── README.md                   # This file
```

## ⚙️ Configuration

### Environment Configurations

#### Development (`values-dev.yaml`)
- **Resources**: Lower CPU/memory limits
- **Replicas**: Single instance
- **Storage**: Smaller persistent volumes
- **Retention**: 7 days
- **Security**: Relaxed for debugging

#### Production (`values-prod.yaml`)
- **Resources**: Higher CPU/memory limits
- **Replicas**: Multiple instances for HA
- **Storage**: Larger persistent volumes
- **Retention**: 90 days
- **Security**: Strict security contexts
- **Anti-affinity**: Spread across nodes

### Key Configuration Values

```yaml
# Cluster information (from your existing setup)
cluster:
  name: "my-cluster"
  region: "ap-south-1"
  environment: "production"

# Prometheus configuration
prometheus:
  enabled: true
  server:
    retention: "30d"
    persistentVolume:
      size: 50Gi
      storageClass: "gp3"

# Grafana configuration
grafana:
  enabled: true
  adminUser: admin
  adminPassword: "your-secure-password"
  persistence:
    size: 10Gi
```

## 🔧 Manual Deployment

If you prefer manual deployment:

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring

# Deploy for development
helm upgrade --install prometheus-grafana ./prometheus-grafana \
  --namespace monitoring \
  --values ./prometheus-grafana/values-dev.yaml \
  --wait --timeout=15m

# Deploy for production
helm upgrade --install prometheus-grafana ./prometheus-grafana \
  --namespace monitoring \
  --values ./prometheus-grafana/values-prod.yaml \
  --wait --timeout=15m
```

## 📊 Pre-configured Dashboards

The Grafana installation includes several pre-configured dashboards:

1. **Kubernetes Cluster Overview** (ID: 7249)
2. **Kubernetes Pods** (ID: 6417)
3. **Node Exporter Full** (ID: 1860)
4. **Prometheus Stats** (ID: 2)

## 🚨 Alerting

Production environment includes pre-configured alerts:

- **Node Not Ready** - Triggers when a node is unready for >5 minutes
- **Pod Crash Looping** - Detects pods in crash loop
- **High CPU Usage** - Alerts when CPU >80% for 5 minutes
- **High Memory Usage** - Alerts when memory >85% for 5 minutes

## 🔍 Monitoring Commands

```bash
# Check deployment status
./deploy-monitoring.sh status

# Get access URLs
./deploy-monitoring.sh urls

# View all pods
kubectl get pods -n monitoring

# View services
kubectl get svc -n monitoring

# View ingress
kubectl get ingress -n monitoring

# Check persistent volumes
kubectl get pvc -n monitoring

# View Prometheus logs
kubectl logs -l app.kubernetes.io/name=prometheus -n monitoring

# View Grafana logs
kubectl logs -l app.kubernetes.io/name=grafana -n monitoring
```

## 🔐 Security Considerations

### Production Security
- Change default Grafana admin password
- Use Kubernetes secrets for sensitive data
- Enable network policies
- Configure proper RBAC
- Use SSL certificates for HTTPS (add ACM certificate ARN)

### Development Security
- Anonymous access enabled for easier testing
- Relaxed security contexts for debugging
- Debug logging enabled

## 🛠️ Troubleshooting

### Common Issues

1. **ALB Not Ready**
   ```bash
   # Check ALB controller logs
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   
   # Verify ingress annotations
   kubectl describe ingress -n monitoring
   ```

2. **Pods Not Starting**
   ```bash
   # Check pod events
   kubectl describe pod <pod-name> -n monitoring
   
   # Check resource constraints
   kubectl top pods -n monitoring
   ```

3. **Storage Issues**
   ```bash
   # Check storage classes
   kubectl get storageclass
   
   # Check PVC status
   kubectl get pvc -n monitoring
   ```

4. **Grafana Login Issues**
   ```bash
   # Get Grafana admin password
   kubectl get secret prometheus-grafana-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
   ```

## 🔄 Upgrading

```bash
# Update Helm repositories
helm repo update

# Upgrade deployment
helm upgrade prometheus-grafana ./prometheus-grafana \
  --namespace monitoring \
  --values ./prometheus-grafana/values-prod.yaml
```

## 🗑️ Uninstalling

```bash
# Using the script
./deploy-monitoring.sh uninstall

# Manual uninstall
helm uninstall prometheus-grafana -n monitoring
kubectl delete namespace monitoring
```

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Kubernetes Monitoring Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/monitoring/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy Monitoring!** 🚀📊
