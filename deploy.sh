#!/bin/bash
set -e  # Exit on error
set -x  # Debug mode - prints each command before running

echo "Starting deployment script..."
echo "Using IMAGE_TAG: $IMAGE_TAG"

# Ensure the private key is available
mkdir -p ~/.ssh
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Skip ssh-keyscan if failing, assuming known_hosts is already set.
echo "Skipping ssh-keyscan... Assuming known_hosts is already set."

# Test SSH connection
echo "Testing SSH connection..."
ssh -o StrictHostKeyChecking=no -v inara@10.1.41.75 "echo 'SSH connection successful'" || { echo "SSH connection failed!"; exit 1; }

# Copy Kubernetes manifest
echo "Copying Kubernetes manifest..."
scp manifest.yml inara@10.1.41.75:/tmp/ || { echo "SCP failed"; exit 1; }

# Apply the Kubernetes manifest
echo "Applying Kubernetes manifest..."
ssh inara@10.1.41.75 "IMAGE_TAG=$IMAGE_TAG envsubst < /tmp/manifest.yml | kubectl apply -f -" || { echo "K8s apply failed"; exit 1; }

# Update deployment with new image
NEW_IMAGE="amjad123ali/django:$IMAGE_TAG"
echo "Updating Kubernetes deployment with image: $NEW_IMAGE"
ssh inara@10.1.41.75 "kubectl set image deployment/cicd-deployment cicd-container=$NEW_IMAGE --record" || { echo "Image update failed"; exit 1; }

# Restart deployment
echo "Restarting deployment..."
ssh inara@10.1.41.75 "kubectl rollout restart deployment/cicd-deployment" || { echo "Rollout restart failed"; exit 1; }

# Get deployment status
echo "Checking deployment status..."
ssh inara@10.1.41.75 "kubectl get deployments cicd-deployment"

echo "Deployment completed successfully!"
