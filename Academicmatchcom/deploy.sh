#!/bin/bash

# AcademicMatch AWS Deployment Script
# This script handles the complete deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPOSITORY="academicmatch"
ECS_CLUSTER="academicmatch-cluster"
ECS_SERVICE="academicmatch-service"

echo -e "${BLUE}🚀 AcademicMatch AWS Deployment Script${NC}"
echo -e "${BLUE}======================================${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is required but not installed.${NC}"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is required but not installed.${NC}"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is required but not installed.${NC}"
        exit 1
    fi
    
    # Check CDK
    if ! command -v cdk &> /dev/null; then
        echo -e "${YELLOW}⚠️  CDK not found, installing globally...${NC}"
        npm install -g aws-cdk
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo -e "${RED}❌ AWS credentials not configured. Run 'aws configure' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo -e "${YELLOW}🏗️  Deploying infrastructure...${NC}"
    
    cd aws-infrastructure
    
    # Install dependencies
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}📦 Installing CDK dependencies...${NC}"
        npm install
    fi
    
    # Bootstrap CDK if needed
    echo -e "${YELLOW}🔧 Bootstrapping CDK...${NC}"
    cdk bootstrap --region $AWS_REGION
    
    # Deploy stack
    echo -e "${YELLOW}🚀 Deploying CloudFormation stack...${NC}"
    cdk deploy --require-approval never --region $AWS_REGION
    
    cd ..
    echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"
}

# Build and push Docker image
build_and_push_image() {
    echo -e "${YELLOW}🐳 Building and pushing Docker image...${NC}"
    
    # Get ECR login
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Create ECR repository if it doesn't exist
    aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION 2>/dev/null || \
    aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION
    
    # Build image
    echo -e "${YELLOW}🔨 Building Docker image...${NC}"
    ECR_URI=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    IMAGE_TAG=$(git rev-parse HEAD 2>/dev/null || echo "manual-$(date +%s)")
    
    docker build -t $ECR_URI/$ECR_REPOSITORY:$IMAGE_TAG .
    docker build -t $ECR_URI/$ECR_REPOSITORY:latest .
    
    # Push image
    echo -e "${YELLOW}📤 Pushing Docker image to ECR...${NC}"
    docker push $ECR_URI/$ECR_REPOSITORY:$IMAGE_TAG
    docker push $ECR_URI/$ECR_REPOSITORY:latest
    
    echo -e "${GREEN}✅ Docker image built and pushed successfully${NC}"
    echo "Image URI: $ECR_URI/$ECR_REPOSITORY:$IMAGE_TAG"
}

# Update ECS service
update_ecs_service() {
    echo -e "${YELLOW}🔄 Updating ECS service...${NC}"
    
    ECR_URI=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    IMAGE_TAG=$(git rev-parse HEAD 2>/dev/null || echo "latest")
    IMAGE_URI="$ECR_URI/$ECR_REPOSITORY:$IMAGE_TAG"
    
    # Get current task definition
    TASK_DEFINITION=$(aws ecs describe-task-definition \
        --task-definition $ECS_SERVICE \
        --query 'taskDefinition' \
        --region $AWS_REGION)
    
    # Create new task definition with updated image
    NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | jq --arg IMAGE "$IMAGE_URI" '
        .containerDefinitions[0].image = $IMAGE |
        del(.taskDefinitionArn) |
        del(.revision) |
        del(.status) |
        del(.requiresAttributes) |
        del(.placementConstraints) |
        del(.compatibilities) |
        del(.registeredAt) |
        del(.registeredBy)
    ')
    
    # Register new task definition
    NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEFINITION | aws ecs register-task-definition \
        --cli-input-json file:///dev/stdin \
        --region $AWS_REGION \
        --query 'taskDefinition.taskDefinitionArn' \
        --output text)
    
    # Update ECS service
    aws ecs update-service \
        --cluster $ECS_CLUSTER \
        --service $ECS_SERVICE \
        --task-definition $NEW_TASK_DEF_ARN \
        --region $AWS_REGION > /dev/null
    
    echo -e "${GREEN}✅ ECS service updated successfully${NC}"
}

# Wait for deployment
wait_for_deployment() {
    echo -e "${YELLOW}⏳ Waiting for deployment to stabilize...${NC}"
    
    aws ecs wait services-stable \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --region $AWS_REGION
    
    echo -e "${GREEN}✅ Deployment completed successfully${NC}"
}

# Get application URL
get_application_url() {
    echo -e "${YELLOW}🌐 Getting application URL...${NC}"
    
    LOAD_BALANCER_DNS=$(aws ssm get-parameter \
        --name "/academicmatch/alb/dns-name" \
        --region $AWS_REGION \
        --query 'Parameter.Value' \
        --output text 2>/dev/null || echo "Not available yet")
    
    echo ""
    echo -e "${GREEN}🎉 Deployment Summary${NC}"
    echo -e "${GREEN}===================${NC}"
    echo -e "${GREEN}✅ AcademicMatch deployed successfully!${NC}"
    echo -e "${BLUE}🌐 Application URL: http://$LOAD_BALANCER_DNS${NC}"
    echo -e "${BLUE}📊 AWS Console: https://$AWS_REGION.console.aws.amazon.com/ecs/home?region=$AWS_REGION#/clusters/$ECS_CLUSTER/services${NC}"
    echo ""
}

# Main deployment flow
main() {
    case "${1:-all}" in
        "infra")
            check_prerequisites
            deploy_infrastructure
            ;;
        "app")
            check_prerequisites
            build_and_push_image
            update_ecs_service
            wait_for_deployment
            get_application_url
            ;;
        "all")
            check_prerequisites
            deploy_infrastructure
            build_and_push_image
            update_ecs_service
            wait_for_deployment
            get_application_url
            ;;
        *)
            echo "Usage: $0 [infra|app|all]"
            echo "  infra - Deploy only infrastructure"
            echo "  app   - Deploy only application (requires existing infrastructure)"
            echo "  all   - Deploy everything (default)"
            exit 1
            ;;
    esac
}

main "$@"
