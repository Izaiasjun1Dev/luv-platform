#!/bin/bash
set -e

# Configuration
ENV="homolog"
AWS_REGION="us-east-1"
PROJECT_NAME="luv"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO_NAME="${PROJECT_NAME}-${ENV}-backend"
IMAGE_TAG="manual-$(date +%s)"

echo "🚀 Starting manual deploy for ${ENV} via Terraform..."

# Check requirements
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform could not be found. Please install it."
    exit 1
fi

# 1. Login to ECR
echo "🔑 Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# 2. Build & Push Docker Image
echo "📦 Building Docker image..."
cd back
docker build --platform linux/amd64 -t ${ECR_REPO_NAME}:${IMAGE_TAG} .
docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}

echo "⬆️ Pushing to ECR..."
docker push ${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}
cd ..

# 3. Update Infrastructure via Terraform
echo "🏗️ Applying Terraform (Targeting Lambda only)..."
cd infra

# Init with correct backend key for homolog
# We must match the key used in CI/CD to avoid state conflicts
terraform init \
  -backend-config="backend.hcl" \
  -backend-config="key=${ENV}/terraform.tfstate" \
  -reconfigure

# Apply changes to Lambda using the new image tag
# We use -target=module.lambda to avoid touching other resources (like Amplify) that might require extra vars
# define build_image=false because we already built and pushed manually above
terraform apply \
  -var-file="envs/${ENV}.tfvars" \
  -var="image_tag=${IMAGE_TAG}" \
  -var="build_image=false" \
  -target="module.lambda" \
  -auto-approve

echo "✅ Backend deployed successfully via Terraform!"
