#!/bin/bash

# Test Script for Comprehensive Snowflake Account Objects Example
# This script demonstrates how to use the comprehensive example

set -e

echo "🚀 Testing Comprehensive Snowflake Account Objects Example"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

print_status "Terraform version: $(terraform version | head -n 1)"

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    print_error "Please run this script from the examples/comprehensive directory"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found. Creating from example..."
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your actual Snowflake credentials"
        print_warning "Or set environment variables: SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_REGION"
        exit 1
    else
        print_error "terraform.tfvars.example not found"
        exit 1
    fi
fi

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate configuration
print_status "Validating configuration..."
terraform validate

# Show what will be created
print_status "Planning deployment..."
terraform plan

print_success "Configuration is valid and ready for deployment!"

echo ""
echo "📋 Next Steps:"
echo "=============="
echo "1. Review the plan above"
echo "2. Run: terraform apply"
echo "3. After deployment, run: terraform output testing_commands"
echo "4. Execute the SQL commands to grant roles and test access"
echo ""
echo "🧪 Testing Commands:"
echo "==================="
echo "After deployment, you can test with:"
echo "  terraform output testing_commands"
echo "  terraform output role_usage_examples"
echo ""
echo "🔧 Manual Role Assignment:"
echo "========================="
echo "After deployment, you'll need to manually grant roles to users:"
echo "  GRANT ROLE <project>_<env>_READER_ROLE TO USER ANALYST_<ENV>;"
echo "  GRANT ROLE <project>_<env>_WRITER_ROLE TO USER ENGINEER_<ENV>;"
echo "  GRANT ROLE <project>_<env>_ADMIN_ROLE TO USER ADMIN_<ENV>;"
echo ""
echo "🧹 Cleanup:"
echo "==========="
echo "To destroy all resources: terraform destroy"
echo ""
print_success "Test script completed successfully!" 