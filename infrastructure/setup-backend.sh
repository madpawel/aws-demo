#!/bin/bash

# Script to set up S3 backend for Terraform state
# Run this after configuring AWS credentials

set -e

# Configuration
BUCKET_NAME="ip-display-app-terraform-state-$(date +%s)"
REGION="us-east-1"
DYNAMODB_TABLE="ip-display-app-terraform-locks"

echo "🚀 Setting up Terraform S3 backend..."

# Create S3 bucket for Terraform state
echo "📦 Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable versioning
echo "🔄 Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "🔒 Enabling server-side encryption"
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'

# Block public access
echo "🛡️ Blocking public access"
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table for state locking
echo "🔐 Creating DynamoDB table for state locking"
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION

# Wait for table to be active
echo "⏳ Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists --table-name $DYNAMODB_TABLE --region $REGION

# Create backend configuration file
echo "📝 Creating backend configuration"
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

echo ""
echo "✅ S3 backend setup complete!"
echo ""
echo "📋 Configuration details:"
echo "   S3 Bucket: $BUCKET_NAME"
echo "   DynamoDB Table: $DYNAMODB_TABLE"
echo "   Region: $REGION"
echo ""
echo "📁 Created backend.tf file"
echo ""
echo "🔧 Next steps:"
echo "   1. Run: terraform init"
echo "   2. Run: terraform plan"
echo "   3. Run: terraform apply"
echo ""
echo "⚠️  Important: Keep the bucket name '$BUCKET_NAME' safe - you'll need it for future deployments!"
