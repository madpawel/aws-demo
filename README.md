# AWS IP Display Application

A simple Python web application that displays client IP addresses, deployed on AWS using modern cloud-native architecture.

## 🌐 Architecture

```
User → CloudFront → ALB (Public Subnet) → ECS Fargate Tasks (Private Subnet)
                                            ↓
                                        ECR (Docker Images)
```

### Components

- **Application**: Flask-based Python web app displaying IP information
- **Container**: Dockerized application with multi-stage build
- **ECR**: Private Docker registry for image storage
- **ECS Fargate**: Serverless container orchestration
- **ALB**: Application Load Balancer for traffic distribution
- **CloudFront**: Global CDN with caching and SSL termination
- **VPC**: Isolated network with public/private subnets
- **Security Groups**: Network-level security rules
- **IAM**: Role-based access control
- **CloudWatch**: Application logging and monitoring

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker
- Python 3.11+ (for local development)

### 1. Clone and Setup

```bash
git clone <repository-url>
cd aws-demo
```

### 2. Deploy Infrastructure

```bash
cd infrastructure
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform plan
terraform apply
```

### 3. Build and Deploy Application

```bash
# Build Docker image
cd ../app
./build.sh

# Get ECR repository URL
ECR_URL=$(cd ../infrastructure && terraform output -raw ecr_repository_url)

# Tag and push to ECR
docker tag ip-display-app:latest $ECR_URL:latest
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest

# Update ECS service
aws ecs update-service --cluster ip-display-app-cluster --service ip-display-app-service --force-new-deployment
```

### 4. Access Application

```bash
# Get application URL
cd infrastructure
terraform output application_url
```

## 📁 Project Structure

```
aws-demo/
├── app/                          # Application code
│   ├── app.py                   # Flask application
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile              # Multi-stage Docker build
│   ├── .dockerignore           # Docker ignore file
│   └── build.sh                # Local build script
├── infrastructure/              # Terraform infrastructure
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── versions.tf             # Provider versions
│   ├── iam.tf                  # IAM roles and policies
│   ├── cloudfront.tf           # CloudFront distribution
│   ├── task-definition.json    # ECS task definition template
│   ├── terraform.tfvars.example # Example variables
│   └── README.md               # Infrastructure documentation
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions deployment
├── instructions.md             # Original requirements
└── README.md                   # This file
```

## 🔧 Local Development

### Run Application Locally

```bash
cd app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Visit `http://localhost:5000` to see the application.

### Test with Docker

```bash
cd app
./build.sh
```

This will build the Docker image and run tests locally.

## 🚀 Deployment Options

### Manual Deployment

Follow the Quick Start guide above for manual deployment.

### GitHub Actions Deployment

1. Set up GitHub repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. Trigger deployment manually:
   - Go to Actions tab in GitHub
   - Select "Deploy IP Display Application"
   - Click "Run workflow"

## 🔍 Monitoring and Troubleshooting

### View Logs

```bash
# Application logs
aws logs tail /ecs/ip-display-app --follow

# ECS service status
aws ecs describe-services --cluster ip-display-app-cluster --services ip-display-app-service
```

### Health Checks

- Application: `https://your-cloudfront-url/health`
- ALB Target Group: Check AWS Console → EC2 → Target Groups

### Common Issues

1. **ECS Tasks Not Starting**
   - Check CloudWatch logs
   - Verify ECR image exists
   - Check security group rules

2. **ALB Health Checks Failing**
   - Verify `/health` endpoint
   - Check container port configuration
   - Verify security groups

3. **CloudFront Issues**
   - Check ALB health
   - Verify origin configuration
   - Check cache behaviors

## 🛡️ Security Features

- **Network Isolation**: ECS tasks in private subnets
- **Least Privilege**: Minimal IAM permissions
- **Security Groups**: Restrictive network rules
- **HTTPS**: SSL termination at CloudFront
- **DDoS Protection**: CloudFront provides DDoS mitigation
- **Container Security**: Non-root user in containers

## 💰 Cost Optimization

- **Fargate Spot**: 50% of tasks use Spot pricing
- **CloudFront**: Global caching reduces origin requests
- **Auto Scaling**: Scale based on demand
- **Log Retention**: 7-day log retention policy
- **ECR Lifecycle**: Automatic cleanup of old images

## 🧹 Cleanup

To destroy all resources:

```bash
cd infrastructure
terraform destroy
```

**Warning**: This will delete all resources permanently.

## 📚 Additional Resources

- [Infrastructure Documentation](infrastructure/README.md)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Flask Documentation](https://flask.palletsprojects.com/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
