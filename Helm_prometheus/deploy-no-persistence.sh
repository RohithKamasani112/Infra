#!/bin/bash

# Simple Prometheus and Grafana Deployment - NO PERSISTENCE
# Prometheus: NodePort (internal access)
# Grafana: ALB LoadBalancer (external access)
# No persistent volumes - data will be lost on pod restart

set -e

# Configuration
NAMESPACE="monitoring"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to add Helm repositories
add_helm_repos() {
    print_status "Adding Helm repositories..."
    
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
    helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
    helm repo update
    
    print_success "Helm repositories ready"
}

# Function to create namespace
create_namespace() {
    print_status "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace $NAMESPACE is ready"
}

# Function to deploy Prometheus (NodePort, no persistence)
deploy_prometheus() {
    print_status "Deploying Prometheus with NodePort (no persistence)..."
    
    helm upgrade --install prometheus prometheus-community/prometheus \
        --namespace $NAMESPACE \
        --set server.service.type=NodePort \
        --set server.service.nodePort=30090 \
        --set server.persistentVolume.enabled=false \
        --set server.retention=6h \
        --set alertmanager.enabled=true \
        --set alertmanager.service.type=NodePort \
        --set alertmanager.service.nodePort=30093 \
        --set alertmanager.persistentVolume.enabled=false \
        --set nodeExporter.enabled=true \
        --set kubeStateMetrics.enabled=true \
        --set pushgateway.enabled=false
    
    print_success "Prometheus deployed successfully!"
}

# Function to deploy Grafana (ClusterIP for ALB, no persistence)
deploy_grafana() {
    print_status "Deploying Grafana for ALB access (no persistence)..."
    
    helm upgrade --install grafana grafana/grafana \
        --namespace $NAMESPACE \
        --set adminPassword=admin123 \
        --set persistence.enabled=false \
        --set service.type=ClusterIP \
        --set datasources."datasources\.yaml".apiVersion=1 \
        --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
        --set datasources."datasources\.yaml".datasources[0].type=prometheus \
        --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server:80 \
        --set datasources."datasources\.yaml".datasources[0].access=proxy \
        --set datasources."datasources\.yaml".datasources[0].isDefault=true
    
    print_success "Grafana deployed successfully!"
}

# Function to create Grafana ALB ingress
create_grafana_ingress() {
    print_status "Creating ALB ingress for Grafana..."
    
    # Wait for Grafana service to be ready
    sleep 30
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: $NAMESPACE
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/healthcheck-path: /login
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "30"
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "10"
    alb.ingress.kubernetes.io/healthy-threshold-count: "2"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "5"
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 80
EOF

    print_success "Grafana ALB ingress created!"
}

# Function to check deployment status
check_status() {
    print_status "Checking deployment status..."
    
    echo ""
    echo "📊 PODS STATUS:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo "🌐 SERVICES:"
    kubectl get svc -n $NAMESPACE
    
    echo ""
    echo "🔗 INGRESS:"
    kubectl get ingress -n $NAMESPACE
    
    echo ""
    echo "🎯 ACCESS INFORMATION:"
    echo "======================"
    
    # Get NodePort for Prometheus
    PROMETHEUS_NODEPORT=$(kubectl get svc prometheus-server -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "Not ready")
    if [ "$PROMETHEUS_NODEPORT" != "Not ready" ]; then
        echo "📊 Prometheus (NodePort - Internal Access):"
        echo "   NodePort: $PROMETHEUS_NODEPORT"
        echo "   URL: http://<node-ip>:$PROMETHEUS_NODEPORT"
        echo "   Port Forward: kubectl port-forward svc/prometheus-server 9090:80 -n $NAMESPACE"
    else
        echo "📊 Prometheus: Service not ready yet"
    fi
    
    # Get ALB URL for Grafana
    GRAFANA_URL=$(kubectl get ingress grafana -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "ALB provisioning")
    if [ "$GRAFANA_URL" != "ALB provisioning" ] && [ ! -z "$GRAFANA_URL" ]; then
        echo ""
        echo "📈 Grafana (ALB - External Access):"
        echo "   URL: http://$GRAFANA_URL"
        echo "   Username: admin"
        echo "   Password: admin123"
    else
        echo ""
        echo "📈 Grafana: ALB still provisioning (wait 2-3 minutes)"
    fi
    
    echo ""
    echo "⚠️  WARNING: NO PERSISTENCE ENABLED"
    echo "=================================="
    echo "• Data will be lost when pods restart"
    echo "• Prometheus retention: 6 hours only"
    echo "• Grafana dashboards will reset on restart"
    echo "• This is for testing/demo purposes only"
    
    echo ""
    echo "📋 USEFUL COMMANDS:"
    echo "==================="
    echo "Check pods: kubectl get pods -n $NAMESPACE"
    echo "Watch pods: watch kubectl get pods -n $NAMESPACE"
    echo "Grafana logs: kubectl logs -l app.kubernetes.io/name=grafana -n $NAMESPACE"
    echo "Prometheus logs: kubectl logs -l app.kubernetes.io/name=prometheus -n $NAMESPACE"
    echo "Port forward Prometheus: kubectl port-forward svc/prometheus-server 9090:80 -n $NAMESPACE"
    echo "Port forward Grafana: kubectl port-forward svc/grafana 3000:80 -n $NAMESPACE"
}

# Function to get access URLs
get_urls() {
    print_status "Getting access URLs..."
    
    echo ""
    echo "🎯 MONITORING STACK ACCESS:"
    echo "==========================="
    
    # Prometheus NodePort
    PROMETHEUS_NODEPORT=$(kubectl get svc prometheus-server -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "Not ready")
    if [ "$PROMETHEUS_NODEPORT" != "Not ready" ]; then
        echo "📊 Prometheus (Internal):"
        echo "   NodePort: $PROMETHEUS_NODEPORT"
        echo "   Port Forward: kubectl port-forward svc/prometheus-server 9090:80 -n $NAMESPACE"
        echo "   Then access: http://localhost:9090"
    fi
    
    # Grafana ALB
    GRAFANA_URL=$(kubectl get ingress grafana -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "ALB provisioning")
    if [ "$GRAFANA_URL" != "ALB provisioning" ] && [ ! -z "$GRAFANA_URL" ]; then
        echo ""
        echo "📈 Grafana (External):"
        echo "   URL: http://$GRAFANA_URL"
        echo "   Username: admin"
        echo "   Password: admin123"
    else
        echo ""
        echo "📈 Grafana: ALB still provisioning"
        echo "   Check again in 2-3 minutes with: $0 urls"
    fi
}

# Function to clean up
cleanup() {
    print_warning "This will remove the entire monitoring stack!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up monitoring stack..."
        helm uninstall prometheus -n $NAMESPACE 2>/dev/null || true
        helm uninstall grafana -n $NAMESPACE 2>/dev/null || true
        kubectl delete ingress --all -n $NAMESPACE 2>/dev/null || true
        print_success "Monitoring stack removed"
        
        read -p "Delete namespace as well? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl delete namespace $NAMESPACE
            print_success "Namespace $NAMESPACE deleted"
        fi
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to show help
show_help() {
    echo "Simple Prometheus and Grafana Deployment (No Persistence)"
    echo ""
    echo "Configuration:"
    echo "• Prometheus: NodePort 30090 (internal access)"
    echo "• Grafana: ALB LoadBalancer (external access)"
    echo "• No persistent volumes (data lost on restart)"
    echo "• Prometheus retention: 6 hours"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy          Deploy monitoring stack"
    echo "  status          Show deployment status"
    echo "  urls            Get access URLs"
    echo "  cleanup         Remove monitoring stack"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy       # Deploy everything"
    echo "  $0 status       # Check status"
    echo "  $0 urls         # Get URLs"
    echo "  $0 cleanup      # Remove everything"
}

# Main script logic
main() {
    local command=${1:-"help"}
    
    case $command in
        "deploy")
            add_helm_repos
            create_namespace
            deploy_prometheus
            deploy_grafana
            create_grafana_ingress
            check_status
            ;;
        "status")
            check_status
            ;;
        "urls")
            get_urls
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
