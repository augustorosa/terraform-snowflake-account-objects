.PHONY: help init fmt validate test test-unit test-integration test-coverage clean docs lint security release-dry release

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize the project (install dependencies)
	@echo "🚀 Initializing project..."
	@echo "Installing pre-commit hooks..."
	@pip install pre-commit || echo "⚠️  Please install pip"
	@pre-commit install || echo "⚠️  Pre-commit installation failed"
	@echo "Installing Go dependencies..."
	@cd tests && go mod download
	@echo "Installing Node dependencies for semantic release..."
	@npm install -g semantic-release @semantic-release/git @semantic-release/changelog
	@echo "✅ Initialization complete!"

fmt: ## Format all code
	@echo "🎨 Formatting code..."
	@terraform fmt -recursive .
	@cd tests && go fmt ./...
	@echo "✅ Formatting complete!"

validate: ## Validate Terraform configuration
	@echo "🔍 Validating Terraform..."
	@for dir in modules/*/; do \
		echo "Validating $$dir"; \
		terraform -chdir="$$dir" init -backend=false; \
		terraform -chdir="$$dir" validate; \
	done
	@echo "✅ Validation complete!"

lint: ## Run all linters
	@echo "🔍 Running linters..."
	@echo "Running tflint..."
	@tflint --init || echo "⚠️  Please install tflint"
	@tflint --recursive
	@echo "Running yamllint..."
	@yamllint -c .yamllint config/ || echo "⚠️  Please install yamllint"
	@echo "✅ Linting complete!"

security: ## Run security scans
	@echo "🔒 Running security scans..."
	@echo "Running tfsec..."
	@tfsec . || echo "⚠️  Please install tfsec"
	@echo "Running checkov..."
	@checkov -d . --framework terraform || echo "⚠️  Please install checkov"
	@echo "✅ Security scan complete!"

test: test-unit test-integration ## Run all tests

test-unit: ## Run unit tests
	@echo "🧪 Running unit tests..."
	@cd tests && TF_ACC=0 go test -v -timeout 30m ./unit/...

test-integration: ## Run integration tests (requires Snowflake credentials)
	@echo "🧪 Running integration tests..."
	@cd tests && TF_ACC=1 go test -v -timeout 45m ./integration/...

test-coverage: ## Run tests with coverage report
	@echo "📊 Running tests with coverage..."
	@cd tests && go test -v -coverprofile=coverage.out ./...
	@cd tests && go tool cover -html=coverage.out -o coverage.html
	@echo "✅ Coverage report generated: tests/coverage.html"

clean: ## Clean up generated files
	@echo "🧹 Cleaning up..."
	@find . -type f -name "*.tfplan" -delete
	@find . -type f -name "*.tfstate*" -delete
	@find . -type f -name ".terraform.lock.hcl" -delete
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@rm -f tests/coverage.out tests/coverage.html
	@echo "✅ Cleanup complete!"

docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@terraform-docs markdown table --output-file README.md --output-mode inject .
	@for dir in modules/*/; do \
		terraform-docs markdown table --output-file "$$dir/README.md" --output-mode inject "$$dir" || true; \
	done
	@echo "✅ Documentation generated!"

release-dry: ## Perform a dry run of semantic release
	@echo "🚀 Dry run of semantic release..."
	@npx semantic-release --dry-run

release: ## Perform semantic release (CI only)
	@echo "🚀 Running semantic release..."
	@if [ -z "$$CI" ]; then \
		echo "❌ Release should only be run in CI environment"; \
		exit 1; \
	fi
	@npx semantic-release

# Development shortcuts
dev-setup: init fmt validate lint ## Complete development setup

pre-commit: fmt validate lint test-unit ## Pre-commit checks

pr-check: fmt validate lint security test-unit docs ## Full PR validation

# Helper targets
install-tools: ## Install required tools
	@echo "🔧 Installing required tools..."
	@echo "Installing Terraform..."
	@brew install terraform || sudo apt-get install terraform || echo "Please install Terraform manually"
	@echo "Installing TFLint..."
	@brew install tflint || curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
	@echo "Installing tfsec..."
	@brew install tfsec || go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
	@echo "Installing terraform-docs..."
	@brew install terraform-docs || go install github.com/terraform-docs/terraform-docs@latest
	@echo "Installing checkov..."
	@pip install checkov
	@echo "Installing yamllint..."
	@pip install yamllint
	@echo "✅ Tools installation complete!"

# CI simulation
ci-local: ## Simulate CI pipeline locally
	@echo "🏗️  Simulating CI pipeline..."
	@make fmt
	@make validate
	@make lint
	@make security
	@make test-unit
	@echo "✅ CI simulation complete!" 