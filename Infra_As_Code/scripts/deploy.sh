#!/bin/bash

#==================================================================================
# Azure Bicep Deployment Script (Bash)
# Created by: Shaun Hardneck
# Website: thatlazyadmin.com
# Description: Deploys Azure resources using Bicep templates
#==================================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Banner
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}Azure Bicep Deployment Script${NC}"
echo -e "${CYAN}Created by: Shaun Hardneck${NC}"
echo -e "${CYAN}Website: thatlazyadmin.com${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# Parse command line arguments
RESOURCE_GROUP=""
TEMPLATE_FILE=""
PARAMETER_FILE=""
LOCATION="eastus"
WHAT_IF=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        --template-file)
            TEMPLATE_FILE="$2"
            shift 2
            ;;
        --parameter-file)
            PARAMETER_FILE="$2"
            shift 2
            ;;
        --location)
            LOCATION="$2"
            shift 2
            ;;
        --what-if)
            WHAT_IF=true
            shift
            ;;
        *)
            print_error "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$RESOURCE_GROUP" ]] || [[ -z "$TEMPLATE_FILE" ]]; then
    print_error "Missing required parameters"
    echo "Usage: ./deploy.sh --resource-group <name> --template-file <file> [--parameter-file <file>] [--location <location>] [--what-if]"
    exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it from https://aka.ms/installazurecli"
    exit 1
fi
print_success "Azure CLI is installed"

# Check if logged in to Azure
print_warning "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Initiating login..."
    az login
fi

ACCOUNT_INFO=$(az account show)
ACCOUNT_NAME=$(echo $ACCOUNT_INFO | jq -r '.user.name')
SUBSCRIPTION_NAME=$(echo $ACCOUNT_INFO | jq -r '.name')
print_success "Logged in as: $ACCOUNT_NAME"
print_success "Subscription: $SUBSCRIPTION_NAME"

# Validate template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    print_error "Template file not found: $TEMPLATE_FILE"
    exit 1
fi
print_success "Template file found: $TEMPLATE_FILE"

# Validate parameter file if provided
if [[ -n "$PARAMETER_FILE" ]]; then
    if [[ ! -f "$PARAMETER_FILE" ]]; then
        print_error "Parameter file not found: $PARAMETER_FILE"
        exit 1
    fi
    print_success "Parameter file found: $PARAMETER_FILE"
fi

# Check if resource group exists
print_warning "Checking resource group..."
if ! az group exists --name "$RESOURCE_GROUP" | grep -q "true"; then
    print_warning "Resource group '$RESOURCE_GROUP' does not exist. Creating..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
    print_success "Resource group created successfully"
else
    print_success "Resource group '$RESOURCE_GROUP' exists"
fi

# Prepare deployment
print_warning "Preparing deployment..."
DEPLOYMENT_NAME="deploy-$(date +%Y%m%d-%H%M%S)"

# Build deployment command
DEPLOY_CMD="az deployment group create \
    --name $DEPLOYMENT_NAME \
    --resource-group $RESOURCE_GROUP \
    --template-file \"$TEMPLATE_FILE\""

if [[ -n "$PARAMETER_FILE" ]]; then
    DEPLOY_CMD="$DEPLOY_CMD --parameters \"@$PARAMETER_FILE\""
fi

if [[ "$WHAT_IF" == true ]]; then
    DEPLOY_CMD="$DEPLOY_CMD --what-if"
    print_info "Running in WHAT-IF mode (no changes will be made)"
fi

print_info "Deployment command:"
echo "$DEPLOY_CMD"

# Execute deployment
print_warning "Starting deployment..."
print_info "Deployment name: $DEPLOYMENT_NAME"

if eval "$DEPLOY_CMD"; then
    if [[ "$WHAT_IF" == true ]]; then
        print_success "What-if analysis completed successfully"
    else
        print_success "Deployment completed successfully"
        
        # Get deployment outputs
        print_warning "Retrieving deployment outputs..."
        OUTPUTS=$(az deployment group show \
            --name "$DEPLOYMENT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --query properties.outputs \
            --output json)
        
        if [[ "$OUTPUTS" != "null" ]] && [[ -n "$OUTPUTS" ]]; then
            print_info "Deployment Outputs:"
            echo "$OUTPUTS" | jq '.'
        fi
    fi
else
    print_error "Deployment failed"
    exit 1
fi

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}Deployment script completed${NC}"
echo -e "${CYAN}=========================================${NC}"
