#!/bin/bash
set -e

# Hanzo Stack Deployment Script
# Supports both Docker Compose and Kubernetes deployments

DEPLOY_MODE="${1:-docker}"
ENVIRONMENT="${2:-production}"

echo "🚀 Deploying Hanzo Stack"
echo "Mode: $DEPLOY_MODE"
echo "Environment: $ENVIRONMENT"
echo ""

case $DEPLOY_MODE in
  docker)
    echo "📦 Deploying with Docker Compose..."
    
    # Check if .env exists
    if [ ! -f .env ]; then
      echo "⚠️  No .env file found. Copying from .env.$ENVIRONMENT..."
      cp .env.$ENVIRONMENT .env
    fi
    
    # Pull latest images
    echo "🔄 Pulling latest images..."
    docker compose pull
    
    # Start services
    echo "🚀 Starting services..."
    docker compose up -d
    
    # Wait for services to be healthy
    echo "⏳ Waiting for services to be healthy..."
    sleep 10
    
    # Check status
    echo "✅ Deployment complete!"
    docker compose ps
    ;;
    
  k8s|kubernetes)
    echo "☸️  Deploying to Kubernetes..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
      echo "❌ kubectl not found. Please install kubectl first."
      exit 1
    fi
    
    # Apply namespace
    echo "📁 Creating namespace..."
    kubectl apply -f k8s/base/namespace.yaml
    
    # Apply secrets (ensure you've updated them first!)
    echo "🔐 Applying secrets..."
    echo "⚠️  WARNING: Make sure you've updated k8s/base/secrets.yaml with real values!"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      kubectl apply -f k8s/base/secrets.yaml
    else
      echo "❌ Deployment cancelled"
      exit 1
    fi
    
    # Apply all manifests
    echo "🚀 Applying manifests..."
    kubectl apply -f k8s/base/
    
    # Wait for deployments
    echo "⏳ Waiting for deployments to be ready..."
    kubectl -n hanzo wait --for=condition=available --timeout=300s deployment --all
    
    echo "✅ Deployment complete!"
    kubectl -n hanzo get all
    ;;
    
  helm)
    echo "⎈ Deploying with Helm..."
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
      echo "❌ helm not found. Please install helm first."
      exit 1
    fi
    
    # Add Bitnami repo
    echo "📦 Adding Helm repositories..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    # Create namespace
    kubectl create namespace hanzo --dry-run=client -o yaml | kubectl apply -f -
    
    # Install/upgrade chart
    echo "🚀 Installing Hanzo Stack..."
    helm upgrade --install hanzo-stack ./helm/hanzo-stack \
      --namespace hanzo \
      --values ./helm/hanzo-stack/values.$ENVIRONMENT.yaml \
      --wait
    
    echo "✅ Deployment complete!"
    helm -n hanzo list
    kubectl -n hanzo get all
    ;;
    
  *)
    echo "❌ Unknown deployment mode: $DEPLOY_MODE"
    echo "Usage: $0 [docker|k8s|kubernetes|helm] [development|production]"
    exit 1
    ;;
esac

echo ""
echo "🎉 Hanzo Stack is ready!"
echo ""
echo "📝 Next steps:"
echo "  - Docker: Access services at http://localhost:PORT"
echo "  - K8s: Configure ingress or use kubectl port-forward"
echo "  - Check logs: docker compose logs -f OR kubectl -n hanzo logs -f deployment/NAME"