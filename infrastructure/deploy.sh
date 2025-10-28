#!/bin/bash

# Complete Terraform deployment script for IP Display Application
# This script handles S3 backend setup, Terraform init, plan, and apply

set -e

echo "🚀 Starting Terraform deployment for IP Display Application..."
echo "================================================================"

# Check if AWS CLI is configured
echo "🔍 Checking AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials not configured!"
    echo "Please run: aws configure"
    echo "You'll need:"
    echo "  - AWS Access Key ID"
    echo "  - AWS Secret Access Key"
    echo "  - Default region: us-east-1"
    echo "  - Default output format: json"
    exit 1
fi

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
echo "✅ AWS credentials configured"
echo "   Account ID: $AWS_ACCOUNT_ID"
echo "   Region: $AWS_REGION"

# Configuration
BUCKET_NAME="ip-display-app-terraform-state-${AWS_ACCOUNT_ID}"
DYNAMODB_TABLE="ip-display-app-terraform-locks"

echo ""
echo "📦 Setting up S3 backend for Terraform state..."

# Check if S3 bucket exists, create if not
if ! aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
    echo "Creating S3 bucket: $BUCKET_NAME"
    aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
    
    # Enable versioning
    aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
    
    # Enable server-side encryption
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
    aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    echo "✅ S3 bucket created and configured"
else
    echo "✅ S3 bucket already exists: $BUCKET_NAME"
fi

# Check if DynamoDB table exists, create if not
if ! aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $AWS_REGION > /dev/null 2>&1; then
    echo "Creating DynamoDB table: $DYNAMODB_TABLE"
    aws dynamodb create-table \
        --table-name $DYNAMODB_TABLE \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region $AWS_REGION
    
    # Wait for table to be active
    echo "⏳ Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name $DYNAMODB_TABLE --region $AWS_REGION
    echo "✅ DynamoDB table created"
else
    echo "✅ DynamoDB table already exists: $DYNAMODB_TABLE"
fi

# Create backend configuration
echo "📝 Creating backend configuration..."
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

echo "✅ Backend configuration created"

echo ""
echo "🔧 Initializing Terraform..."
terraform init

echo ""
echo "📋 Running Terraform plan..."
terraform plan -out=tfplan

echo ""
echo "🚀 Applying Terraform configuration..."
echo "This will create the following AWS resources:"
echo "  - VPC with public/private subnets"
echo "  - ECR repository"
echo "  - ECS Fargate cluster"
echo "  - Application Load Balancer"
echo "  - CloudFront distribution"
echo "  - Security groups and IAM roles"
echo ""
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply tfplan
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📊 Getting deployment outputs..."
    terraform output
    
    echo ""
    echo "🔗 Application URL:"
    terraform output -raw application_url
    
    echo ""
    echo "📝 Next steps:"
    echo "1. Build and push Docker image to ECR:"
    echo "   cd ../app"
    echo "   ./build.sh"
    echo "   ECR_URL=\$(cd ../infrastructure && terraform output -raw ecr_repository_url)"
    echo "   docker tag ip-display-app:latest \$ECR_URL:latest"
    echo "   aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin \$ECR_URL"
    echo "   docker push \$ECR_URL:latest"
    echo ""
    echo "2. Update ECS service:"
    echo "   aws ecs update-service --cluster ip-display-app-cluster --service ip-display-app-service --force-new-deployment"
    echo ""
    echo "3. Monitor deployment:"
    echo "   aws ecs describe-services --cluster ip-display-app-cluster --services ip-display-app-service"
    echo ""
else
    echo "❌ Deployment cancelled"
    exit 1
fi
