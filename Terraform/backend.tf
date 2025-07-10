terraform {
backend "s3" {
bucket         = "my-tf-state-bucket-eks"
key            = "eks/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "my-tf-lock-table"
encrypt        = true
}
}