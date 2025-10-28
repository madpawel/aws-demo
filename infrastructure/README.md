# AWS IP Display Application - Infrastructure

This directory contains the Terraform configuration for deploying the IP Display Application to AWS.

## Architecture

The infrastructure deploys the following AWS components:

```
User → CloudFront → ALB (Public Subnet) → ECS Fargate Tasks (Private Subnet)
                                            ↓
                                        ECR (Docker Images)
```

### Components

- **VPC**: Custom VPC with public and private subnets across 2 AZs
- **ECR**: Private Docker registry for storing application images
- **ECS**: Fargate cluster running the application containers
- **ALB**: Application Load Balancer distributing traffic to ECS tasks
- **CloudFront**: CDN for global distribution and caching
- **Security Groups**: Network security rules for ALB and ECS
- **IAM Roles**: Permissions for ECS task execution and logging
- **CloudWatch**: Log groups for application monitoring

## Prerequisites

1. **AWS CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **AWS Account** with appropriate permissions
4. **Docker** installed (for building application images)

## Setup Instructions

### 1. Configure AWS Credentials

```bash
aws configure
```

### 2. Initialize Terraform

```bash
cd infrastructure
terraform init
```

### 3. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred values
```

### 4. Plan Deployment

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

### 6. Get Outputs

After deployment, get the important outputs:

```bash
terraform output
```

Key outputs:
- `application_url`: The CloudFront URL for your application
- `ecr_repository_url`: ECR repository URL for pushing Docker images
- `alb_dns_name`: ALB DNS name (for debugging)

## Building and Deploying the Application

### 1. Build Docker Image

```bash
cd ../app
./build.sh
```

### 2. Tag for ECR

```bash
# Get ECR repository URL from terraform output
ECR_URL=$(cd ../infrastructure && terraform output -raw ecr_repository_url)

# Tag the image
docker tag ip-display-app:latest $ECR_URL:latest
```

### 3. Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# Push the image
docker push $ECR_URL:latest
```

### 4. Update ECS Service

```bash
# Force new deployment
aws ecs update-service --cluster ip-display-app-cluster --service ip-display-app-service --force-new-deployment
```

## Monitoring

### CloudWatch Logs

Application logs are available in CloudWatch:

```bash
aws logs describe-log-groups --log-group-name-prefix "/ecs/ip-display-app"
```

### ECS Service Status

```bash
aws ecs describe-services --cluster ip-display-app-cluster --services ip-display-app-service
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources and data. Make sure you have backups if needed.

## Troubleshooting

### Common Issues

1. **ECS Tasks Not Starting**
   - Check CloudWatch logs: `/ecs/ip-display-app`
   - Verify ECR image exists and is accessible
   - Check security group rules

2. **ALB Health Checks Failing**
   - Verify application is listening on port 5000
   - Check `/health` endpoint responds with 200
   - Verify security groups allow traffic

3. **CloudFront Not Working**
   - Check ALB is healthy and responding
   - Verify CloudFront origin configuration
   - Check cache behaviors

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster ip-display-app-cluster --services ip-display-app-service

# View application logs
aws logs tail /ecs/ip-display-app --follow

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw alb_target_group_arn)

# Test application directly
curl $(terraform output -raw alb_dns_name)
```

## Security Notes

- ECS tasks run in private subnets without public IPs
- ALB is in public subnets but only accepts traffic from CloudFront
- Security groups follow least privilege principle
- IAM roles have minimal required permissions
- CloudFront provides DDoS protection and SSL termination
