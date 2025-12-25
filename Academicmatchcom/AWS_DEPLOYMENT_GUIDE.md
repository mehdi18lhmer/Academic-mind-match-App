# AcademicMatch AWS Deployment Guide

This guide provides step-by-step instructions for deploying AcademicMatch to AWS using Docker, ECS Fargate, RDS PostgreSQL, and Application Load Balancer.

## 🏗️ Architecture Overview

```
Internet Gateway
    │
Application Load Balancer (Public Subnets)
    │
ECS Fargate Tasks (Private Subnets)
    │
RDS PostgreSQL (Private Isolated Subnets)
```

### AWS Services Used
- **ECS Fargate**: Container orchestration
- **Application Load Balancer**: Traffic distribution and SSL termination
- **RDS PostgreSQL**: Managed database
- **ECR**: Container image registry
- **CloudWatch**: Monitoring and logging
- **Secrets Manager**: Secure credential storage
- **VPC**: Network isolation
- **Auto Scaling**: Automatic scaling based on demand

## 🔧 Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Docker** installed and running
4. **Node.js 18+** and npm
5. **Git** (optional, for versioning)

### AWS CLI Setup
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Choose your preferred region (e.g., us-east-1)
# Choose output format (json recommended)
```

## 🚀 Deployment Methods

### Method 1: Automated Deployment (Recommended)

Use the provided deployment script for a fully automated deployment:

```bash
# Make the script executable (Linux/Mac)
chmod +x deploy.sh

# Deploy everything (infrastructure + application)
./deploy.sh all

# Deploy only infrastructure
./deploy.sh infra

# Deploy only application (requires existing infrastructure)
./deploy.sh app
```

### Method 2: Manual Step-by-Step Deployment

#### Step 1: Set up Secrets (Optional but Recommended)

```bash
# Make the secrets script executable
chmod +x aws-infrastructure/setup-secrets.sh

# Run the secrets setup
./aws-infrastructure/setup-secrets.sh
```

#### Step 2: Deploy Infrastructure

```bash
cd aws-infrastructure

# Install CDK dependencies
npm install

# Install CDK globally (if not already installed)
npm install -g aws-cdk

# Bootstrap CDK (one-time setup per region)
cdk bootstrap --region us-east-1

# Deploy the infrastructure stack
cdk deploy --require-approval never
```

#### Step 3: Build and Push Container Image

```bash
# Return to project root
cd ..

# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"  # or your preferred region

# Create ECR repository
aws ecr create-repository --repository-name academicmatch --region $AWS_REGION

# Get ECR login token
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and tag the Docker image
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/academicmatch:latest .

# Push the image to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/academicmatch:latest
```

#### Step 4: Update ECS Service

The ECS service will automatically pull the latest image from ECR. You can force a new deployment:

```bash
aws ecs update-service \
    --cluster academicmatch-cluster \
    --service academicmatch-service \
    --force-new-deployment \
    --region $AWS_REGION
```

## 🌐 CI/CD with GitHub Actions

### Setup GitHub Repository Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

### Trigger Deployments

- **Application Deployment**: Push to `main` or `master` branch
- **Infrastructure Deployment**: Include `[deploy-infra]` in commit message
- **Full Deployment**: Include `[full-deploy]` in commit message

Example:
```bash
git commit -m "Update database schema [deploy-infra]"
git push origin main
```

## 🔍 Monitoring and Troubleshooting

### Access Your Application

After successful deployment, get your application URL:

```bash
# Get the load balancer DNS name
aws ssm get-parameter \
    --name "/academicmatch/alb/dns-name" \
    --region us-east-1 \
    --query 'Parameter.Value' \
    --output text
```

### CloudWatch Dashboard

Access the monitoring dashboard at:
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=AcademicMatch-Production
```

### Common Commands

```bash
# View ECS service status
aws ecs describe-services \
    --cluster academicmatch-cluster \
    --services academicmatch-service \
    --region us-east-1

# View application logs
aws logs tail /aws/ecs/academicmatch --follow --region us-east-1

# Check database status
aws rds describe-db-instances \
    --db-instance-identifier academicmatch-database \
    --region us-east-1

# List secrets
aws secretsmanager list-secrets --region us-east-1

# Update database credentials (after RDS is created)
aws secretsmanager update-secret \
    --secret-id academicmatch-db-credentials \
    --secret-string '{"username":"academicmatch_admin","password":"your-password","engine":"postgres","host":"your-rds-endpoint","port":"5432","dbname":"academicmatch"}' \
    --region us-east-1
```

## 💰 Cost Management

### Estimated Monthly Costs (us-east-1)

- **ECS Fargate** (2 tasks, 0.5 vCPU, 1GB RAM): ~$30-40
- **Application Load Balancer**: ~$22
- **RDS PostgreSQL** (db.t3.micro): ~$12-15
- **NAT Gateway**: ~$45
- **Data Transfer**: Variable based on usage
- **CloudWatch Logs**: ~$1-5

**Total Estimated**: ~$110-127/month

### Cost Optimization Tips

1. **Use Spot Instances**: Consider ECS Fargate Spot for non-critical workloads
2. **Schedule Downtime**: Use scheduled scaling for development environments
3. **Monitor Usage**: Set up billing alerts
4. **Rightsizing**: Adjust instance sizes based on actual usage

## 🔒 Security Best Practices

### Network Security
- ✅ Private subnets for application and database tiers
- ✅ Security groups with minimal required access
- ✅ WAF (Web Application Firewall) can be added for additional protection

### Data Security
- ✅ Secrets Manager for credentials
- ✅ Encryption in transit and at rest
- ✅ Regular security updates through automated deployments

### Access Control
- ✅ IAM roles with least privilege principle
- ✅ No hardcoded credentials in code

## 🆘 Troubleshooting

### Common Issues

#### 1. ECS Tasks Failing to Start
```bash
# Check ECS service events
aws ecs describe-services --cluster academicmatch-cluster --services academicmatch-service

# Check task logs
aws logs describe-log-streams --log-group-name /aws/ecs/academicmatch
```

#### 2. Database Connection Issues
```bash
# Verify security groups allow ECS to RDS traffic
# Check if DATABASE_URL secret is properly formatted
aws secretsmanager get-secret-value --secret-id academicmatch-db-credentials
```

#### 3. Load Balancer Health Check Failures
- Ensure your application responds to health checks on `/health` endpoint
- Check that the container port (5000) matches the target group configuration

### Cleanup / Destroy Resources

```bash
# Destroy all infrastructure
cd aws-infrastructure
cdk destroy --force

# Delete ECR images (manual)
aws ecr delete-repository --repository-name academicmatch --force --region us-east-1

# Delete secrets (manual)
aws secretsmanager delete-secret --secret-id academicmatch-db-credentials --force-delete-without-recovery --region us-east-1
aws secretsmanager delete-secret --secret-id academicmatch-jwt-secret --force-delete-without-recovery --region us-east-1
```

## 📞 Support

For additional support:

1. **AWS Documentation**: https://docs.aws.amazon.com/
2. **ECS Troubleshooting**: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html
3. **CDK Documentation**: https://docs.aws.amazon.com/cdk/

## 🔄 Updates and Maintenance

### Application Updates
- Push code changes to trigger automatic deployment
- Monitor CloudWatch metrics after deployments
- Use blue/green deployment strategy for zero-downtime updates

### Infrastructure Updates
- Modify CDK code and redeploy with `cdk deploy`
- Test changes in a staging environment first
- Keep CDK and AWS CLI updated to latest versions

---

**✅ Deployment Complete!** 

Your AcademicMatch application is now running on AWS with:
- High availability across multiple AZs
- Auto-scaling based on demand  
- Comprehensive monitoring and alerting
- Secure credential management
- Automated CI/CD pipeline
