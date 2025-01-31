#!/bin/bash
set -e  # Exit script on error

# Debugging: Print which commands are being run
echo "Starting deployment script..."
echo "Using IMAGE_TAG: $IMAGE_TAG"

# Ensure that the private key is available
mkdir -p ~/.ssh
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa  # Secure private key

# Debugging: Print SSH Key Fingerprint
echo "Checking SSH key..."
ssh-keygen -lf ~/.ssh/id_rsa || echo "SSH key not valid!"

# Add the server to known hosts to avoid SSH authenticity warnings
echo "Adding remote host to known_hosts..."
ssh-keyscan -H 10.1.41.75 >> ~/.ssh/known_hosts

# Debugging: Check if SSH works
echo "Testing SSH connection..."
ssh -v inara@10.1.41.75 "echo 'SSH connection successful'"

# Copy the Kubernetes manifest to the remote server
echo "Copying Kubernetes manifest..."
scp manifest.yml inara@10.1.41.75:/tmp/ || { echo "SCP failed"; exit 1; }

# Apply the manifest on Kubernetes
echo "Applying Kubernetes manifest..."
ssh inara@10.1.41.75 "kubectl apply -f /tmp/manifest.yml" || { echo "K8s apply failed"; exit 1; }

# Set the new image for the deployment dynamically
NEW_IMAGE="amjad123ali/django:$IMAGE_TAG"
echo "Updating Kubernetes deployment with image: $NEW_IMAGE"
ssh inara@10.1.41.75 "kubectl set image deployment/cicd-deployment cicd-container=$NEW_IMAGE --record" || { echo "Image update failed"; exit 1; }

# Force a Kubernetes rollout restart to apply changes
echo "Restarting deployment..."
ssh inara@10.1.41.75 "kubectl rollout restart deployment/cicd-deployment" || { echo "Rollout restart failed"; exit 1; }

# Print the deployment status
echo "Checking deployment status..."
ssh inara@10.1.41.75 "kubectl get deployments cicd-deployment"

echo "Deployment completed successfully!"

