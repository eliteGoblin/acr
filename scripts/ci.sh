#!/bin/bash
set -euo pipefail

##############################################################################
# CI/CD Script for Azure Container Registry Terraform Module
#
# This script performs common CI operations:
# - terraform fmt (formatting check and fix)
# - tflint (Terraform linting)
# - terraform-docs (generate documentation)
##############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
MODULE_DIR="${PROJECT_ROOT}/modules/acr"

echo -e "${BLUE}🚀 Starting CI pipeline for ACR Terraform Module${NC}"
echo -e "${BLUE}Project root: ${PROJECT_ROOT}${NC}"
echo -e "${BLUE}Module directory: ${MODULE_DIR}${NC}"

##############################################################################
# Function: Check if command exists
##############################################################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

##############################################################################
# Function: Install tools if missing
##############################################################################
install_tools() {
    echo -e "${YELLOW}📦 Checking and installing required tools...${NC}"
    
    # Check terraform
    if ! command_exists terraform; then
        echo -e "${RED}❌ terraform not found. Please install terraform first.${NC}"
        exit 1
    fi
    
    # Check tflint
    if ! command_exists tflint; then
        echo -e "${YELLOW}⚠️  tflint not found. Installing...${NC}"
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    fi
    
    # Check terraform-docs
    if ! command_exists terraform-docs; then
        echo -e "${YELLOW}⚠️  terraform-docs not found. Installing...${NC}"
        curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-linux-amd64.tar.gz
        tar -xzf terraform-docs.tar.gz
        chmod +x terraform-docs
        sudo mv terraform-docs /usr/local/bin/
        rm terraform-docs.tar.gz
    fi
    
    echo -e "${GREEN}✅ All tools are available${NC}"
}

##############################################################################
# Function: Format Terraform code
##############################################################################
format_terraform() {
    echo -e "${YELLOW}🔧 Running terraform fmt...${NC}"
    
    # Format root directory
    if terraform fmt -check -recursive "${PROJECT_ROOT}"; then
        echo -e "${GREEN}✅ Terraform code is properly formatted${NC}"
    else
        echo -e "${YELLOW}⚠️  Formatting Terraform code...${NC}"
        terraform fmt -recursive "${PROJECT_ROOT}"
        echo -e "${GREEN}✅ Terraform code formatted${NC}"
    fi
}

##############################################################################
# Function: Run tflint
##############################################################################
run_tflint() {
    echo -e "${YELLOW}🔍 Running tflint...${NC}"
    
    # Initialize tflint
    tflint --init
    
    # Run tflint on module
    if tflint "${MODULE_DIR}"; then
        echo -e "${GREEN}✅ tflint passed${NC}"
    else
        echo -e "${RED}❌ tflint failed${NC}"
        return 1
    fi
    
    # Run tflint on root
    if tflint "${PROJECT_ROOT}"; then
        echo -e "${GREEN}✅ tflint passed for root configuration${NC}"
    else
        echo -e "${RED}❌ tflint failed for root configuration${NC}"
        return 1
    fi
}

##############################################################################
# Function: Generate documentation
##############################################################################
generate_docs() {
    echo -e "${YELLOW}📚 Generating module documentation...${NC}"
    
    # Generate README for module
    terraform-docs markdown table --output-file README.md "${MODULE_DIR}"
    
    if [[ -f "${MODULE_DIR}/README.md" ]]; then
        echo -e "${GREEN}✅ Module documentation generated: ${MODULE_DIR}/README.md${NC}"
    else
        echo -e "${RED}❌ Failed to generate module documentation${NC}"
        return 1
    fi
}

##############################################################################
# Function: Validate Terraform
##############################################################################
validate_terraform() {
    echo -e "${YELLOW}🔍 Running terraform validate...${NC}"
    
    # Initialize and validate module
    cd "${MODULE_DIR}"
    terraform init -backend=false
    
    if terraform validate; then
        echo -e "${GREEN}✅ Module validation passed${NC}"
    else
        echo -e "${RED}❌ Module validation failed${NC}"
        return 1
    fi
    
    # Validate root configuration
    cd "${PROJECT_ROOT}"
    terraform init -backend=false
    
    if terraform validate; then
        echo -e "${GREEN}✅ Root configuration validation passed${NC}"
    else
        echo -e "${RED}❌ Root configuration validation failed${NC}"
        return 1
    fi
}

##############################################################################
# Main execution
##############################################################################
main() {
    echo -e "${BLUE}Starting CI pipeline...${NC}"
    
    # Install required tools
    install_tools
    
    # Format code
    format_terraform
    
    # Validate Terraform
    validate_terraform
    
    # Run tflint
    run_tflint
    
    # Generate documentation  
    generate_docs
    
    echo -e "${GREEN}🎉 CI pipeline completed successfully!${NC}"
}

# Execute main function
main "$@"