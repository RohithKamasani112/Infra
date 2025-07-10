in # 🔧 Cluster Values Update Guide

This guide explains how to update cluster details in your Helm values files after running Terraform.

## 📋 Files That Need Cluster Details

### **Helm Application Folder:**
1. `Helm_App/my-app/values.yaml`

### **Helm Prometheus Folder:**
2. `Helm_prometheus/prometheus-grafana/values.yaml`

**Note: Using single values.yaml files only - no separate dev/prod files needed!**

## 🎯 Variables to Update

### **From Terraform Outputs:**

| Terraform Output | Variable in values.yaml | Description |
|------------------|-------------------------|-------------|
| `cluster_name` | `cluster.name` | EKS cluster name |
| `cluster_endpoint` | `cluster.endpoint` | EKS cluster API endpoint |
| `cluster_certificate_authority_data` | `cluster.certificateAuthorityData` | Cluster CA certificate |
| `vpc_id` | `cluster.vpcId` | VPC ID where cluster is deployed |
| `private_subnets` | `cluster.privateSubnets` | Private subnet IDs |
| `public_subnets` | `cluster.publicSubnets` | Public subnet IDs |

### **Manual Variables (from AWS Console):**

| Variable | Example Value | Where to Find |
|----------|---------------|---------------|
| `cluster.region` | `"ap-south-1"` | Your AWS region |
| `image.registry` | `"992878410375.dkr.ecr.ap-south-1.amazonaws.com"` | ECR registry URL |

## 🚀 Quick Update Methods

### **Method 1: Automated Script (Recommended)**

```bash
# Run this script after terraform apply
./update-cluster-values.sh
```

This script will:
- ✅ Get all Terraform outputs automatically
- ✅ Update all values files in both helm folders
- ✅ Show you what was updated

### **Method 2: Manual Update**

1. **Get Terraform outputs:**
   ```bash
   cd terraform
   terraform output cluster_name
   terraform output cluster_endpoint
   terraform output vpc_id
   terraform output private_subnets
   terraform output public_subnets
   ```

2. **Update each values.yaml file** with the cluster section:

```yaml
# Cluster Configuration (Update these values from Terraform outputs)
cluster:
  name: "YOUR_CLUSTER_NAME"                 # From terraform output: cluster_name
  region: "ap-south-1"                      # Your AWS region
  endpoint: "YOUR_CLUSTER_ENDPOINT"         # From terraform output: cluster_endpoint
  certificateAuthorityData: "YOUR_CA_DATA" # From terraform output: cluster_certificate_authority_data
  vpcId: "YOUR_VPC_ID"                      # From terraform output: vpc_id
  privateSubnets: ["subnet-xxx", "subnet-yyy"] # From terraform output: private_subnets
  publicSubnets: ["subnet-aaa", "subnet-bbb"]  # From terraform output: public_subnets
  environment: "production"                 # Environment name
```

## 📁 Exact Variable Locations

### **In Helm_App/my-app/values.yaml:**
```yaml
# Lines 4-13
cluster:
  name: "my-eks-cluster"                    # UPDATE THIS
  region: "ap-south-1"                      # UPDATE THIS
  endpoint: ""                              # UPDATE THIS
  certificateAuthorityData: ""              # UPDATE THIS
  vpcId: ""                                 # UPDATE THIS
  privateSubnets: []                        # UPDATE THIS
  publicSubnets: []                         # UPDATE THIS
  environment: "production"                 # UPDATE THIS
```

### **In helm_prometheus/prometheus-grafana/values.yaml:**
```yaml
# Lines 9-18
cluster:
  name: "my-eks-cluster"                    # UPDATE THIS
  region: "ap-south-1"                      # UPDATE THIS
  endpoint: ""                              # UPDATE THIS
  certificateAuthorityData: ""              # UPDATE THIS
  vpcId: ""                                 # UPDATE THIS
  privateSubnets: []                        # UPDATE THIS
  publicSubnets: []                         # UPDATE THIS
  environment: "production"                 # UPDATE THIS
```

**Note: Only single values.yaml files are used - no separate dev/prod files!**

## 🔄 Workflow After Terraform Apply

1. **Run Terraform:**
   ```bash
   cd terraform
   terraform apply
   ```

2. **Update Cluster Values:**
   ```bash
   # Option A: Automated (Recommended)
   ./update-cluster-values.sh
   
   # Option B: Manual
   # Edit each values.yaml file with terraform outputs
   ```

3. **Deploy Applications:**
   ```bash
   # Deploy main application using single values.yaml
   cd Helm_App
   ./quick-deploy.sh

   # Or deploy manually
   helm upgrade --install code-dev-app Helm_App/my-app \
     --namespace code-dev \
     --values Helm_App/my-app/values.yaml \
     --create-namespace

   # Deploy monitoring stack
   cd Helm_prometheus
   ./deploy-monitoring.sh deploy prod
   ```

## ✅ Verification

After updating, verify the values are correct:

```bash
# Check Helm App values
grep -A 10 "cluster:" Helm_App/my-app/values.yaml

# Check Prometheus values
grep -A 10 "cluster:" helm_prometheus/prometheus-grafana/values.yaml
```

## 🚨 Important Notes

- **Always update values after terraform apply** - Cluster details may change
- **Use the automated script** - It's faster and less error-prone
- **Verify ECR registry URL** - Make sure it matches your AWS account and region
- **Check environment names** - Ensure dev/prod environments are correctly set
- **Backup values files** - Before making changes, consider backing up your files

## 🔍 Troubleshooting

### **Script Permission Error:**
```bash
chmod +x update-cluster-values.sh
```

### **Terraform Outputs Not Found:**
```bash
cd terraform
terraform refresh
terraform output
```

### **Values Not Updating:**
- Check file paths are correct
- Ensure you're in the project root directory
- Verify terraform state file exists

---

**Happy Deploying!** 🚀
