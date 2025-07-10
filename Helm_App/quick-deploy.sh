#!/bin/bash

# Quick deployment script with progress monitoring
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Starting deployment..."

# Clean up any previous failed deployments
echo -e "${BLUE}[INFO]${NC} Cleaning up any previous deployments..."
helm uninstall code-dev-app -n code-dev 2>/dev/null || echo "No previous deployment found"
kubectl delete namespace code-dev 2>/dev/null || echo "Namespace doesn't exist"

# Wait a moment for cleanup
sleep 5

echo -e "${BLUE}[INFO]${NC} Starting fresh deployment..."

# Deploy with progress monitoring
helm upgrade --install code-dev-app ./my-app \
    --namespace code-dev \
    --values ./my-app/values.yaml \
    --create-namespace \
    --timeout 10m \
    --wait &

HELM_PID=$!

# Monitor progress
COUNTER=0
while kill -0 $HELM_PID 2>/dev/null; do
    COUNTER=$((COUNTER + 1))
    echo -e "${YELLOW}[PROGRESS]${NC} Deployment in progress... (${COUNTER}0 seconds elapsed)"
    
    # Show pod status if namespace exists
    if kubectl get namespace code-dev &>/dev/null; then
        echo -e "${BLUE}[INFO]${NC} Current pod status:"
        kubectl get pods -n code-dev 2>/dev/null || echo "No pods yet..."
    fi
    
    sleep 10
done

# Get helm exit code
wait $HELM_PID
HELM_EXIT_CODE=$?

if [ $HELM_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Deployment completed successfully!"
    
    echo -e "${BLUE}[INFO]${NC} Checking deployment status..."
    kubectl get pods -n code-dev
    kubectl get svc -n code-dev
    kubectl get ingress -n code-dev
    
    echo -e "${GREEN}[SUCCESS]${NC} Your application is now running!"

    echo -e "${BLUE}[INFO]${NC} Waiting for ALB to be provisioned..."
    sleep 30

    # Get ALB URL
    ALB_URL=$(kubectl get ingress -n code-dev -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

    if [ ! -z "$ALB_URL" ]; then
        echo -e "${GREEN}[SUCCESS]${NC} Your application is accessible at:"
        echo -e "${YELLOW}http://$ALB_URL${NC}"
        echo ""
        echo -e "${BLUE}[INFO]${NC} It may take a few more minutes for the ALB to be fully ready."
    else
        echo -e "${YELLOW}[INFO]${NC} ALB is still being provisioned. To get the URL later, run:"
        echo -e "${BLUE}kubectl get ingress -n code-dev -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'${NC}"
    fi
else
    echo -e "${RED}[ERROR]${NC} Deployment failed!"
    echo -e "${BLUE}[INFO]${NC} Checking for issues..."
    kubectl get events -n code-dev --sort-by='.lastTimestamp' | tail -10
    exit 1
fi
