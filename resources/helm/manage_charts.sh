#!/bin/bash

# Check if namespace is provided as a parameter
if [ -z "$1" ]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

NAMESPACE=$1

# Function to check the status of the previous command
check_result() {
  if [ $? -ne 0 ]; then
    echo "========================================"
    echo "-=========== Operation failed ===========-"
    echo "========================================"
    exit 1
  fi
}

# Function to install or upgrade a service
install_or_update() {
  local service_name=$1
  if [ -z "$service_name" ]; then
    echo "Service name not set"
    exit 1
  fi

  # Define Helm chart path based on service type
  local helm_chart="stripo/$service_name"
  [[ "$service_name" == "coediting-core-service" || "$service_name" == "env-adapter-service" || "$service_name" == "merge-service" ]] && helm_chart="stripo/go-template-service"

  # Install or upgrade the service
  if ! helm list --namespace="$NAMESPACE" | grep -q "$service_name"; then
    echo "-= Installing $service_name =-"
    helm install "$service_name" "$helm_chart" -f "charts/$service_name.yaml" --namespace "$NAMESPACE"
  else
    echo "-= Upgrading $service_name =-"
    helm upgrade --install "$service_name" "$helm_chart" -f "charts/$service_name.yaml" --namespace "$NAMESPACE"
  fi

  # Wait for the deployment to complete
  kubectl rollout status deploy/"$service_name" --namespace="$NAMESPACE"
  check_result

  echo "-= Operation for $service_name completed successfully =-"
}

# Start the process
echo "-== Starting installation or update for namespace: $NAMESPACE ==-"
helm repo update stripo

# Ensure the namespace exists
kubectl get namespace "$NAMESPACE" || kubectl create namespace "$NAMESPACE"

# Apply DockerHub secret
kubectl apply -f ./resources/secrets/docker-hub-secret.yaml -n "$NAMESPACE"
check_result

# List of services to install or update
services=(
  "stripo-security-service"
  "amp-validator-service"
  "countdowntimer"
  "screenshot-service"
  "stripe-html-cleaner-service"
  "stripe-html-gen-service"
  "stripo-plugin-api-gateway"
  "stripo-plugin-custom-blocks-service"
  "stripo-plugin-details-service"
  "stripo-plugin-documents-service"
  "stripo-plugin-image-bank-service"
  "stripo-plugin-proxy-service"
  "stripo-plugin-statistics-service"
  "stripo-timer-api"
  "ai-service"
  "ui-editor-widgets-registry-service"
  "convo-core-chat-server"

  #---------------------------------------------------
  # Uncomment after configuring the Calendar Link Generator access token
  # (README Step 12) - the service does not start without calendar-link.token.
  # Request the token from the Stripo team and set it in
  # charts/stripo-calendar-link-service.yaml
  #"stripo-calendar-link-service"
  #---------------------------------------------------

  #---------------------------------------------------
  # Uncomment after following README Step 13 (Play-in-email / V2 only).
  # Optional: the editor works without it. Default 2 CPU / 2Gi and
  # service.video.url on the api-gateway. No extra token or database.
  # charts/stripo-video-processing-service.yaml
  #"stripo-video-processing-service"
  #---------------------------------------------------

  #---------------------------------------------------
  # Comment to run ONLY Stripo editor V2 microservices
  "stripo-plugin-drafts-service"
  "patches-service"
  #---------------------------------------------------

  #------------------------------------------------
  # Uncomment to run Stripo editor V2 microservices
  #"coediting-core-service"
  #"env-adapter-service"
  #"merge-service"
  #------------------------------------------------
)

# Install or update each service
for i in "${!services[@]}"; do
  progress=$(( (i + 1) * 100 / ${#services[@]} ))
  echo -ne "Progress: $progress%\r"

  install_or_update "${services[i]}"
done

echo "========================================"
echo "-========= All operations completed ==========-"
echo "========================================"
