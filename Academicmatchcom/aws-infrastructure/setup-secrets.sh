#!/bin/bash

# AcademicMatch AWS Secrets Setup Script
# This script sets up the necessary secrets in AWS Secrets Manager

set -e

echo "🔐 Setting up AcademicMatch AWS Secrets..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Get the current region
REGION=$(aws configure get region || echo "us-east-1")
echo "📍 Using AWS region: $REGION"

# Function to create or update secret
create_or_update_secret() {
    local secret_name=$1
    local secret_value=$2
    local description=$3
    
    if aws secretsmanager describe-secret --secret-id "$secret_name" --region "$REGION" > /dev/null 2>&1; then
        echo "🔄 Updating existing secret: $secret_name"
        aws secretsmanager update-secret \
            --secret-id "$secret_name" \
            --secret-string "$secret_value" \
            --description "$description" \
            --region "$REGION" > /dev/null
    else
        echo "✅ Creating new secret: $secret_name"
        aws secretsmanager create-secret \
            --name "$secret_name" \
            --secret-string "$secret_value" \
            --description "$description" \
            --region "$REGION" > /dev/null
    fi
}

# Set up database URL secret (this will be updated after RDS is created)
echo "🗄️  Setting up database credentials secret..."
create_or_update_secret \
    "academicmatch-db-credentials" \
    '{"username":"academicmatch_admin","password":"PLACEHOLDER_PASSWORD","engine":"postgres","host":"PLACEHOLDER_HOST","port":"5432","dbname":"academicmatch"}' \
    "Database credentials for AcademicMatch PostgreSQL instance"

# Generate and set JWT secret
echo "🔑 Generating JWT secret..."
JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
create_or_update_secret \
    "academicmatch-jwt-secret" \
    "$JWT_SECRET" \
    "JWT signing secret for AcademicMatch authentication"

# Create SSM parameters for configuration
echo "⚙️  Creating SSM parameters..."

# Environment configuration
aws ssm put-parameter \
    --name "/academicmatch/config/node-env" \
    --value "production" \
    --type "String" \
    --description "Node.js environment setting" \
    --region "$REGION" \
    --overwrite 2>/dev/null || echo "Parameter already exists"

aws ssm put-parameter \
    --name "/academicmatch/config/port" \
    --value "5000" \
    --type "String" \
    --description "Application port" \
    --region "$REGION" \
    --overwrite 2>/dev/null || echo "Parameter already exists"

echo ""
echo "✅ Secrets and parameters setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Deploy the infrastructure with CDK"
echo "2. Update the database credentials secret with the actual RDS endpoint"
echo "3. Deploy your application container"
echo ""
echo "🔍 To view secrets:"
echo "aws secretsmanager list-secrets --region $REGION"
echo ""
echo "🔍 To view parameters:"
echo "aws ssm get-parameters-by-path --path \"/academicmatch\" --region $REGION"
