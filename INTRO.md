# AWS Infrastructure Overview - IP Display Application

## 🎯 Project Overview

This project demonstrates a complete AWS infrastructure setup for a containerized Python Flask application that displays client IP addresses. The application showcases modern cloud architecture patterns including containerization, serverless computing, CDN distribution, and infrastructure as code.

## 🏗️ Architecture Overview

### High-Level Architecture
```
Internet → CloudFront → ALB → ECS Fargate → Flask App
```

### Component Flow
1. **CloudFront CDN** - Global content delivery and SSL termination
2. **Application Load Balancer (ALB)** - Traffic distribution and health checks
3. **ECS Fargate** - Serverless container orchestration
4. **ECR** - Private container registry
5. **VPC** - Network isolation and security
6. **CloudWatch** - Logging and monitoring

## 📁 Project Structure

```
aws-demo/
├── app/                    # Application code
│   ├── app.py             # Flask application
│   ├── Dockerfile         # Multi-stage container build
│   ├── requirements.txt   # Python dependencies
│   └── build.sh          # Local build and test script
├── infrastructure/        # Terraform infrastructure code
│   ├── main.tf           # Core infrastructure resources
│   ├── alb.tf            # Application Load Balancer
│   ├── cloudfront.tf     # CloudFront distribution
│   ├── iam.tf            # IAM roles and policies
│   ├── backend.tf        # Terraform state backend
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── versions.tf       # Provider versions
│   ├── deploy.sh         # Complete deployment script
│   ├── setup-backend.sh  # Backend setup script
│   └── task-definition.json # ECS task definition
└── INTRO.md              # This documentation
```

## 🔧 Infrastructure Components

### 1. Networking (VPC)
- **VPC CIDR**: `10.0.0.0/16`
- **Availability Zones**: `us-east-1a`, `us-east-1b`
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24`
- **Private Subnets**: `10.0.10.0/24`, `10.0.20.0/24`
- **DNS Support**: Enabled
- **NAT Gateway**: Disabled (cost optimization)

### 2. Container Registry (ECR)
- **Repository**: `ip-display-app-repository`
- **Type**: Private
- **Lifecycle Policy**: Keeps last 10 tagged images
- **Encryption**: Server-side encryption enabled

### 3. Compute (ECS Fargate)
- **Cluster**: `ip-display-app-cluster`
- **Service**: `ip-display-app-service`
- **Task Definition**: `ip-display-app-task`
- **CPU**: 256 units
- **Memory**: 512 MB
- **Desired Count**: 1
- **Scaling**: 1-3 tasks (configurable)

### 4. Load Balancing (ALB)
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Port**: 80 (HTTP)
- **Health Check**: `/health` endpoint
- **Target Group**: IP-based targets on port 5000

### 5. Content Delivery (CloudFront)
- **Origin**: ALB DNS name
- **Protocol**: HTTP-only origin, HTTPS viewer
- **Caching**: Disabled for dynamic content
- **Price Class**: PriceClass_100 (US, Canada, Europe)
- **SSL**: CloudFront default certificate

### 6. Security Groups
- **ALB Security Group**: 
  - Inbound: HTTP (80), HTTPS (443) from anywhere
  - Outbound: All traffic
- **ECS Security Group**:
  - Inbound: HTTP (5000) from ALB only
  - Outbound: All traffic

### 7. IAM Roles
- **ECS Task Execution Role**: 
  - ECR access for pulling images
  - CloudWatch Logs access
- **ECS Task Role**: 
  - CloudWatch Logs write access

### 8. Monitoring (CloudWatch)
- **Log Group**: `/ecs/ip-display-app`
- **Retention**: 7 days
- **Log Stream**: ECS task-based streams

## 🚀 Deployment Process

### Prerequisites
1. **AWS CLI** configured with appropriate permissions
2. **Docker** installed and running
3. **Terraform** >= 1.0 installed
4. **AWS Account** with sufficient permissions

### Required AWS Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "ecr:*",
        "elasticloadbalancing:*",
        "cloudfront:*",
        "iam:*",
        "logs:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Step-by-Step Deployment

#### 1. Infrastructure Deployment
```bash
cd infrastructure
./deploy.sh
```

This script will:
- Verify AWS credentials
- Create S3 bucket for Terraform state
- Create DynamoDB table for state locking
- Initialize Terraform
- Plan and apply infrastructure

#### 2. Application Deployment
```bash
cd app
./build.sh
```

This script will:
- Build Docker image locally
- Test the application
- Verify health endpoints

#### 3. Push to ECR and Deploy
```bash
# Get ECR repository URL
ECR_URL=$(cd ../infrastructure && terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# Tag and push image
docker tag ip-display-app:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Update ECS service
aws ecs update-service --cluster ip-display-app-cluster --service ip-display-app-service --force-new-deployment
```

## 🔍 Application Details

### Flask Application (`app.py`)
- **Framework**: Flask
- **Port**: 5000
- **Endpoints**:
  - `/` - Main page displaying IP information
  - `/health` - Health check endpoint
- **Features**:
  - Displays client IP from X-Forwarded-For header
  - Shows direct connecting IP
  - Responsive HTML interface
  - Timestamp display

### Container Configuration
- **Base Image**: Python 3.11-slim
- **Multi-stage Build**: Optimized for size and security
- **Non-root User**: Security best practice
- **Health Check**: Built-in container health monitoring
- **Port Exposure**: 5000

## 📊 Monitoring and Logging

### CloudWatch Logs
- **Log Group**: `/ecs/ip-display-app`
- **Stream Prefix**: `ecs`
- **Retention**: 7 days
- **Access**: AWS Console or CLI

### Health Checks
- **ALB Health Check**: `/health` endpoint
- **Container Health Check**: Built-in Docker health check
- **ECS Service Health**: Automatic task replacement on failure

## 🔧 Configuration Management

### Environment Variables
- `PORT`: Application port (default: 5000)
- `AWS_REGION`: AWS region for resources
- `PROJECT_NAME`: Project identifier
- `ENVIRONMENT`: Environment name (dev/prod)

### Terraform Variables
Key configurable variables in `variables.tf`:
- `aws_region`: AWS region
- `project_name`: Project name
- `environment`: Environment
- `container_cpu`: ECS task CPU
- `container_memory`: ECS task memory
- `desired_count`: Number of ECS tasks

## 🛠️ Development Workflow

### Local Development
1. **Run locally**:
   ```bash
   cd app
   python app.py
   ```

2. **Test with Docker**:
   ```bash
   cd app
   ./build.sh
   ```

### Infrastructure Changes
1. **Modify Terraform files**
2. **Plan changes**:
   ```bash
   terraform plan
   ```
3. **Apply changes**:
   ```bash
   terraform apply
   ```

### Application Updates
1. **Update application code**
2. **Build and test locally**
3. **Push to ECR**
4. **Update ECS service**

## 🔒 Security Considerations

### Network Security
- VPC isolation
- Security groups with minimal required access
- No direct internet access to ECS tasks

### Container Security
- Non-root user execution
- Multi-stage builds to reduce attack surface
- Regular base image updates

### Infrastructure Security
- S3 bucket encryption
- DynamoDB encryption at rest
- IAM roles with least privilege

## 💰 Cost Optimization

### Current Optimizations
- **Fargate Spot**: Not enabled (can be added)
- **No NAT Gateway**: Public subnets only
- **Minimal Resources**: 256 CPU, 512 MB memory
- **CloudFront**: PriceClass_100 for cost-effective global distribution

### Potential Optimizations
- Enable Fargate Spot for non-critical workloads
- Implement auto-scaling based on metrics
- Use reserved capacity for predictable workloads
- Optimize CloudFront caching policies

## 🚨 Troubleshooting

### Common Issues

#### 1. ECS Service Not Starting
```bash
# Check service status
aws ecs describe-services --cluster ip-display-app-cluster --services ip-display-app-service

# Check task logs
aws logs get-log-events --log-group-name /ecs/ip-display-app --log-stream-name <stream-name>
```

#### 2. Health Check Failures
```bash
# Test health endpoint directly
curl http://<alb-dns-name>/health

# Check ALB target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

#### 3. CloudFront Issues
```bash
# Check distribution status
aws cloudfront get-distribution --id <distribution-id>

# Test origin connectivity
curl -H "Host: <alb-dns-name>" http://<alb-dns-name>/health
```

### Useful Commands
```bash
# Get all outputs
terraform output

# Get specific output
terraform output -raw application_url

# Check ECS cluster status
aws ecs describe-clusters --clusters ip-display-app-cluster

# View CloudWatch logs
aws logs tail /ecs/ip-display-app --follow
```

## 📚 Additional Resources

### AWS Documentation
- [ECS Fargate](https://docs.aws.amazon.com/ecs/latest/userguide/what-is-fargate.html)
- [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [CloudFront](https://docs.aws.amazon.com/cloudfront/)
- [ECR](https://docs.aws.amazon.com/ecr/)

### Terraform Documentation
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Module](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest)
- [VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)

## 🤝 Team Onboarding Checklist

### First Day
- [ ] Access to AWS account with appropriate permissions
- [ ] AWS CLI configured locally
- [ ] Docker installed and running
- [ ] Terraform installed
- [ ] Git repository cloned

### First Week
- [ ] Review this documentation
- [ ] Deploy infrastructure using `deploy.sh`
- [ ] Build and test application locally
- [ ] Understand the architecture flow
- [ ] Access CloudWatch logs

### First Month
- [ ] Make a small application change
- [ ] Deploy infrastructure change
- [ ] Understand monitoring and alerting
- [ ] Review security configurations
- [ ] Understand cost implications

## 📞 Support and Contacts

### Internal Resources
- **Infrastructure Team**: [Contact Information]
- **DevOps Team**: [Contact Information]
- **Security Team**: [Contact Information]

### External Resources
- **AWS Support**: [Support Plan Details]
- **Terraform Community**: [Community Forums]
- **Docker Documentation**: [Docker Hub]

---

*This document is maintained by the Infrastructure Team. Last updated: [Current Date]*
*For questions or updates, please contact the Infrastructure Team or create an issue in the repository.*
