#!/bin/bash

# Ensure that the private key is available
mkdir -p ~/.ssh
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa  # Ensure the private key is secure

# Add the server to known hosts to avoid SSH authenticity warnings
ssh-keyscan -H 10.1.41.75 >> ~/.ssh/known_hosts

# Set the new image for the deployment (replace with your image tag)
NEW_IMAGE="$IMAGE_NAME:$CI_COMMIT_SHORT_SHA"  # Use the dynamic image tag
ssh inara@10.1.41.75 "kubectl set image deployment/cicd-deployment cicd-container=$NEW_IMAGE"

# Force a Kubernetes rollout restart to apply changes
ssh inara@10.1.41.75 "kubectl rollout restart deployment/cicd-deployment"

# Print the deployment status
ssh inara@10.1.41.75 "kubectl get deployments cicd-deployment"
