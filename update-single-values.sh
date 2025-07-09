#!/bin/bash

# Script to update cluster values in single values.yaml files
# Updates only the main values.yaml files (no dev/prod files)

set -e

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

# Check if terraform directory exists
if [ ! -d "terraform" ]; then
    print_error "Terraform directory not found. Please run this script from the project root."
    exit 1
fi

# Get Terraform outputs
print_status "Getting Terraform outputs..."

cd terraform

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    print_error "Terraform state file not found. Please run 'terraform apply' first."
    exit 1
fi

# Get cluster details from terraform outputs
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint 2>/dev/null || echo "")
CLUSTER_CA_DATA=$(terraform output -raw cluster_certificate_authority_data 2>/dev/null || echo "")
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
PRIVATE_SUBNETS=$(terraform output -json private_subnets 2>/dev/null || echo "[]")
PUBLIC_SUBNETS=$(terraform output -json public_subnets 2>/dev/null || echo "[]")

cd ..

# Validate outputs
if [ -z "$CLUSTER_NAME" ]; then
    print_error "Could not get cluster_name from terraform outputs"
    exit 1
fi

print_success "Retrieved cluster details:"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Cluster Endpoint: $CLUSTER_ENDPOINT"
echo "  VPC ID: $VPC_ID"

# Function to update values file
update_values_file() {
    local file_path="$1"
    local temp_file="${file_path}.tmp"
    
    if [ ! -f "$file_path" ]; then
        print_warning "File not found: $file_path"
        return 1
    fi
    
    print_status "Updating $file_path..."
    
    # Use sed to update the values
    sed -e "s/name: \"my-eks-cluster\"/name: \"$CLUSTER_NAME\"/" \
        -e "s/endpoint: \"\"/endpoint: \"$CLUSTER_ENDPOINT\"/" \
        -e "s/certificateAuthorityData: \"\"/certificateAuthorityData: \"$CLUSTER_CA_DATA\"/" \
        -e "s/vpcId: \"\"/vpcId: \"$VPC_ID\"/" \
        -e "s/privateSubnets: \[\]/privateSubnets: $PRIVATE_SUBNETS/" \
        -e "s/publicSubnets: \[\]/publicSubnets: $PUBLIC_SUBNETS/" \
        "$file_path" > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$file_path"
    
    print_success "Updated $file_path"
}

# Update Helm App values file
print_status "Updating Helm App values file..."
if [ -f "Helm_App/my-app/values.yaml" ]; then
    update_values_file "Helm_App/my-app/values.yaml"
else
    print_warning "Helm_App/my-app/values.yaml not found"
fi

# Update Helm Prometheus values file
print_status "Updating Helm Prometheus values file..."
if [ -f "Helm_prometheus/prometheus-grafana/values.yaml" ]; then
    update_values_file "Helm_prometheus/prometheus-grafana/values.yaml"
else
    print_warning "Helm_prometheus/prometheus-grafana/values.yaml not found"
fi

print_success "All values files updated successfully!"

echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo "1. Review the updated values files to ensure correctness"
echo "2. Deploy your applications:"
echo "   - For Helm App: helm upgrade --install my-app Helm_App/my-app --namespace default"
echo "   - For Monitoring: cd Helm_prometheus && ./deploy-no-persistence.sh deploy"
echo ""
echo "📋 UPDATED FILES:"
echo "================="
echo "✅ Helm_App/my-app/values.yaml"
echo "✅ Helm_prometheus/prometheus-grafana/values.yaml"
echo ""
echo "🔍 CLUSTER DETAILS APPLIED:"
echo "==========================="
echo "Cluster Name: $CLUSTER_NAME"
echo "Cluster Endpoint: $CLUSTER_ENDPOINT"
echo "VPC ID: $VPC_ID"
echo "Private Subnets: $PRIVATE_SUBNETS"
echo "Public Subnets: $PUBLIC_SUBNETS"
echo ""
echo "✅ SINGLE VALUES FILES ONLY - NO DEV/PROD SEPARATION!"
