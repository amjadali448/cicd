#!/bin/bash

set -e  # Exit immediately if a command fails

# Ensure that the private key is available
mkdir -p ~/.ssh
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa  # Secure private key

# Add the server to known hosts to avoid SSH authenticity warnings
ssh-keyscan -H 10.1.41.75 >> ~/.ssh/known_hosts

# Copy the Kubernetes manifest to the remote server
scp manifest.yml inara@10.1.41.75:/tmp/

# Apply the manifest on Kubernetes
ssh inara@10.1.41.75 "kubectl apply -f /tmp/manifest.yml"

# Set the new image for the deployment dynamically
NEW_IMAGE="amjad123ali/django:$IMAGE_TAG"
ssh inara@10.1.41.75 "kubectl set image deployment/cicd-deployment cicd-container=$NEW_IMAGE --record"

# Force a Kubernetes rollout restart to apply changes
ssh inara@10.1.41.75 "kubectl rollout restart deployment/cicd-deployment"

# Print the deployment status
ssh inara@10.1.41.75 "kubectl get deployments cicd-deployment"
