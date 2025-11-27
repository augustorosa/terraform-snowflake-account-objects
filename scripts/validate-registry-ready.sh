#!/bin/bash

# 🚀 Terraform Registry Readiness Validator
# This script validates that your module meets Terraform Registry requirements

set -e

echo "🔍 Validating Terraform Registry Readiness..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
check_pass() {
    echo -e "✅ ${GREEN}PASS${NC}: $1"
    ((PASSED++))
}

check_fail() {
    echo -e "❌ ${RED}FAIL${NC}: $1"
    ((FAILED++))
}

check_warn() {
    echo -e "⚠️  ${YELLOW}WARN${NC}: $1"
    ((WARNINGS++))
}

echo
echo "📋 Checking Required Files..."
echo "-----------------------------"

# Check required files
if [ -f "LICENSE" ]; then
    check_pass "LICENSE file exists"
else
    check_fail "LICENSE file missing"
fi

if [ -f "README.md" ]; then
    check_pass "README.md exists"
    
    # Check README content
    if grep -q "## Requirements" README.md; then
        check_pass "README contains Requirements section"
    else
        check_warn "README missing Requirements section"
    fi
    
    if grep -q "## Providers" README.md; then
        check_pass "README contains Providers section"
    else
        check_warn "README missing Providers section"
    fi
    
    if grep -q "## Inputs" README.md; then
        check_pass "README contains Inputs section"
    else
        check_warn "README missing Inputs section"
    fi
    
    if grep -q "## Outputs" README.md; then
        check_pass "README contains Outputs section"
    else
        check_warn "README missing Outputs section"
    fi
else
    check_fail "README.md missing"
fi

if [ -f "main.tf" ]; then
    check_pass "main.tf exists"
else
    check_fail "main.tf missing"
fi

if [ -f "variables.tf" ]; then
    check_pass "variables.tf exists"
else
    check_fail "variables.tf missing"
fi

if [ -f "outputs.tf" ]; then
    check_pass "outputs.tf exists"
else
    check_fail "outputs.tf missing"
fi

if [ -f "versions.tf" ]; then
    check_pass "versions.tf exists"
    
    # Check versions.tf content
    if grep -q "required_version" versions.tf; then
        check_pass "Terraform version constraint specified"
    else
        check_warn "No Terraform version constraint found"
    fi
    
    if grep -q "required_providers" versions.tf; then
        check_pass "Provider requirements specified"
    else
        check_fail "No provider requirements found"
    fi
else
    check_fail "versions.tf missing"
fi

echo
echo "📁 Checking Directory Structure..."
echo "---------------------------------"

if [ -d "examples" ]; then
    check_pass "examples/ directory exists"
    
    # Count examples
    EXAMPLE_COUNT=$(find examples -mindepth 1 -maxdepth 1 -type d | wc -l)
    if [ "$EXAMPLE_COUNT" -gt 0 ]; then
        check_pass "Found $EXAMPLE_COUNT example(s)"
        
        # Check each example
        for example_dir in examples/*/; do
            if [ -d "$example_dir" ]; then
                example_name=$(basename "$example_dir")
                if [ -f "${example_dir}main.tf" ]; then
                    check_pass "Example '$example_name' has main.tf"
                else
                    check_warn "Example '$example_name' missing main.tf"
                fi
                
                if [ -f "${example_dir}README.md" ]; then
                    check_pass "Example '$example_name' has README.md"
                else
                    check_warn "Example '$example_name' missing README.md"
                fi
            fi
        done
    else
        check_warn "No examples found in examples/ directory"
    fi
else
    check_warn "examples/ directory missing (recommended)"
fi

echo
echo "🏷️ Checking Repository Naming..."
echo "--------------------------------"

# Get repository name from git remote or current directory
REPO_NAME=$(basename "$(pwd)")

if [[ "$REPO_NAME" =~ ^terraform-[a-z0-9]+-[a-z0-9-]+$ ]]; then
    check_pass "Repository name follows terraform-<PROVIDER>-<NAME> format: $REPO_NAME"
else
    check_fail "Repository name doesn't follow terraform-<PROVIDER>-<NAME> format: $REPO_NAME"
fi

# Check for typo in current repo name
if [[ "$REPO_NAME" == "terraform-snowflake-acccount-objects" ]]; then
    check_fail "Repository name has typo: 'acccount' should be 'account'"
fi

echo
echo "🔍 Checking Terraform Syntax..."
echo "-------------------------------"

# Check if terraform is available
if command -v terraform &> /dev/null; then
    if terraform validate &> /dev/null; then
        check_pass "Terraform syntax is valid"
    else
        check_fail "Terraform syntax validation failed"
        echo "Run 'terraform validate' for details"
    fi
else
    check_warn "Terraform CLI not found - cannot validate syntax"
fi

echo
echo "🏷️ Checking for Git Tags..."
echo "---------------------------"

if git rev-parse --git-dir > /dev/null 2>&1; then
    # Check for semantic version tags
    TAGS=$(git tag -l | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | wc -l)
    if [ "$TAGS" -gt 0 ]; then
        check_pass "Found $TAGS semantic version tag(s)"
        LATEST_TAG=$(git tag -l | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1)
        echo "   Latest: $LATEST_TAG"
    else
        check_warn "No semantic version tags found (needed for publishing)"
        echo "   Create a tag with: git tag v1.0.0 && git push origin v1.0.0"
    fi
else
    check_warn "Not a git repository"
fi

echo
echo "📊 Validation Summary"
echo "===================="
echo -e "✅ ${GREEN}Passed${NC}: $PASSED"
echo -e "❌ ${RED}Failed${NC}: $FAILED"
echo -e "⚠️  ${YELLOW}Warnings${NC}: $WARNINGS"

echo
if [ $FAILED -eq 0 ]; then
    echo -e "🎉 ${GREEN}Module is ready for Terraform Registry!${NC}"
    echo
    echo "Next steps:"
    echo "1. Fix any warnings above (recommended)"
    echo "2. Create a release tag: git tag v1.0.0 && git push origin v1.0.0"
    echo "3. Go to https://registry.terraform.io/"
    echo "4. Sign in with GitHub and publish your module"
    exit 0
else
    echo -e "🚨 ${RED}Module has issues that must be fixed before publishing${NC}"
    echo
    echo "Please address the failed checks above and run this script again."
    exit 1
fi 