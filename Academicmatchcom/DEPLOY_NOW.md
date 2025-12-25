# 🚀 Deploy AcademicMatch NOW - Quick Start

## ✅ Prerequisites Status:
- [x] Node.js v22.17.0 installed
- [x] AWS CLI v2.28.16 installed  
- [x] Docker Desktop v4.44.3 installed (starting up...)
- [x] All deployment files created

## 🔧 Final Setup Steps (2 minutes):

### Step 1: Configure AWS Credentials
```powershell
aws configure
```
**Enter when prompted:**
- AWS Access Key ID: `[Your AWS access key]`
- AWS Secret Access Key: `[Your AWS secret key]`  
- Default region name: `us-east-1`
- Default output format: `json`

### Step 2: Wait for Docker Desktop to Start
- Look for Docker Desktop icon in system tray
- Wait until it shows "Docker Desktop is running"

### Step 3: Deploy Everything (10-15 minutes)
```powershell
# Install CDK globally
npm install -g aws-cdk

# Navigate to project directory (if not already there)
cd "C:\Users\mehdi\OneDrive\Academicmatchcom"

# Deploy infrastructure first
cd aws-infrastructure
npm install
cdk bootstrap --region us-east-1
cdk deploy --require-approval never

# Return to project root and deploy app
cd ..
```

### Step 4: Build and Deploy Container
```powershell
# Get your AWS account ID
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$AWS_REGION = "us-east-1"

# Create ECR repository
aws ecr create-repository --repository-name academicmatch --region $AWS_REGION

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Build and push Docker image
docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/academicmatch:latest" .
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/academicmatch:latest"

# Update ECS service to use the new image
aws ecs update-service --cluster academicmatch-cluster --service academicmatch-service --force-new-deployment --region $AWS_REGION
```

### Step 5: Get Your Application URL
```powershell
# Wait a few minutes for deployment to complete, then get URL
aws ssm get-parameter --name "/academicmatch/alb/dns-name" --region us-east-1 --query 'Parameter.Value' --output text
```

## 🎯 Expected Timeline:
- **AWS Configure**: 1 minute
- **Infrastructure Deployment**: 8-12 minutes  
- **Container Build & Deploy**: 3-5 minutes
- **Service Stabilization**: 2-3 minutes

**Total: ~15-20 minutes**

## 🌐 Your App URL Will Be:
`http://AcademicMatch-LoadB-XXXXXXXXX-123456789.us-east-1.elb.amazonaws.com`

## ⚠️ If You Don't Have AWS Credentials:
1. Go to AWS Console: https://console.aws.amazon.com/
2. Create an IAM user with programmatic access
3. Attach policies: AmazonECS_FullAccess, AmazonRDS_FullAccess, AmazonEC2_FullAccess, IAMFullAccess
4. Note down the Access Key ID and Secret Access Key

---

**Ready to deploy? Run the commands above in order! 🚀**
