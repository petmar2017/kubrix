#!/bin/bash

# Source environment variables
source .env

# Export all KUBRIX variables
export KUBRIX_CUSTOMER_REPO
export KUBRIX_CUSTOMER_REPO_TOKEN
export KUBRIX_CUSTOMER_TARGET_TYPE
export KUBRIX_CUSTOMER_DNS_PROVIDER
export KUBRIX_CUSTOMER_DOMAIN

echo "Environment variables set:"
echo "KUBRIX_CUSTOMER_REPO=$KUBRIX_CUSTOMER_REPO"
echo "KUBRIX_CUSTOMER_REPO_TOKEN=***hidden***"
echo "KUBRIX_CUSTOMER_TARGET_TYPE=$KUBRIX_CUSTOMER_TARGET_TYPE"
echo "KUBRIX_CUSTOMER_DNS_PROVIDER=$KUBRIX_CUSTOMER_DNS_PROVIDER"
echo "KUBRIX_CUSTOMER_DOMAIN=$KUBRIX_CUSTOMER_DOMAIN"
echo ""

# Run the bootstrap script
exec ./scripts/bootstrap-kubrix.sh