# Testing Guide

This directory contains all tests for the Terraform Snowflake Account Objects module. We use [Terratest](https://terratest.gruntwork.io/) for testing our Terraform modules.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)

## Prerequisites

1. **Go 1.21+**: Install from [golang.org](https://golang.org/dl/)
2. **Terraform 1.5.7+**: Install from [terraform.io](https://www.terraform.io/downloads)
3. **Snowflake Account**: Required for integration tests

### Environment Variables

For integration tests, set these environment variables:

```bash
export SNOWFLAKE_ACCOUNT="your-account"
export SNOWFLAKE_USER="your-user"
export SNOWFLAKE_PASSWORD="your-password"
export SNOWFLAKE_ROLE="SYSADMIN"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
export SNOWFLAKE_REGION="us-west-2"
```

## Test Structure

```
tests/
├── unit/                    # Unit tests for individual modules
│   ├── foundation_test.go   # Foundation module tests
│   ├── rbac_test.go        # RBAC module tests
│   ├── database_test.go    # Database module tests
│   └── ...
├── integration/            # Integration tests
│   ├── complete_test.go    # Full module integration
│   └── scenarios/          # Real-world scenarios
├── fixtures/               # Test fixtures and data
├── helpers/                # Test helper functions
└── go.mod                  # Go module definition
```

## Running Tests

### All Tests

```bash
cd tests
go test -v ./...
```

### Unit Tests Only

```bash
cd tests
go test -v ./unit/... -timeout 30m
```

### Integration Tests Only

```bash
cd tests
TF_ACC=1 go test -v ./integration/... -timeout 45m
```

### Specific Test

```bash
cd tests
go test -v -run TestFoundationModule ./unit/
```

### With Coverage

```bash
cd tests
go test -v -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html
```

### Parallel Testing

```bash
cd tests
go test -v -parallel 4 ./unit/...
```

## Writing Tests

### Unit Test Example

```go
func TestDatabaseModule(t *testing.T) {
    t.Parallel()

    // Create unique test ID
    uniqueID := random.UniqueId()
    testName := fmt.Sprintf("test-%s", uniqueID)

    // Setup test
    terraformOptions := &terraform.Options{
        TerraformDir: "../../modules/database",
        Vars: map[string]interface{}{
            "database_name": testName,
            "environment":   "test",
        },
    }

    // Cleanup
    defer terraform.Destroy(t, terraformOptions)

    // Run Terraform
    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    dbName := terraform.Output(t, terraformOptions, "database_name")
    assert.Equal(t, testName, dbName)
}
```

### Integration Test Example

```go
func TestCompleteIntegration(t *testing.T) {
    t.Parallel()

    // Skip if not in integration test mode
    if os.Getenv("TF_ACC") != "1" {
        t.Skip("Skipping integration test")
    }

    // Load test config
    config := helpers.LoadTestConfig(t, "../fixtures/test-config.yml")

    // Test implementation...
}
```

### Test Helpers

```go
// Use helpers for common operations
func validateSecuritySettings(t *testing.T, opts *terraform.Options) {
    // MFA enabled
    mfaEnabled := terraform.Output(t, opts, "mfa_enabled")
    assert.Equal(t, "true", mfaEnabled)
    
    // Password policy
    policy := terraform.OutputMap(t, opts, "password_policy")
    assert.NotEmpty(t, policy)
}
```

## CI/CD Integration

Tests run automatically in GitHub Actions:

1. **On Pull Request**: Unit tests and validation
2. **On Push to Main**: Full test suite including integration
3. **On Release**: Comprehensive testing before publishing

### Local CI Simulation

```bash
# Run tests as CI would
cd tests
TF_ACC=0 go test -v -timeout 30m ./unit/...
```

## Best Practices

### 1. Test Isolation

- Use unique IDs for all resource names
- Clean up resources with `defer`
- Don't depend on external state

### 2. Test Organization

- Group related tests in test suites
- Use descriptive test names
- Keep tests focused on single functionality

### 3. Performance

- Use `t.Parallel()` for unit tests
- Mock expensive operations when possible
- Set appropriate timeouts

### 4. Debugging

```bash
# Verbose Terraform output
export TF_LOG=DEBUG

# Keep test artifacts
export SKIP_CLEANUP=true

# Run single test with debugging
go test -v -run TestSpecific ./unit/ -debug
```

### 5. Test Data

- Use fixtures for complex configurations
- Generate test data programmatically
- Avoid hardcoded values

### 6. Error Handling

```go
// Use E variants for better error handling
output, err := terraform.OutputE(t, opts, "some_output")
if err != nil {
    // Handle specific error cases
}
```

## Troubleshooting

### Common Issues

1. **Module not found**: Run `go mod tidy` in the tests directory
2. **Timeout errors**: Increase timeout with `-timeout` flag
3. **Permission denied**: Check Snowflake credentials and permissions
4. **State conflicts**: Use unique test names and clean up properly

### Debug Commands

```bash
# Check Go environment
go env

# Verify module dependencies
go mod graph

# Clean module cache
go clean -modcache

# Update dependencies
go get -u ./...
```

## Contributing

1. Write tests for all new features
2. Maintain or improve test coverage
3. Follow existing test patterns
4. Document complex test scenarios
5. Run tests locally before PR

## Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Go Testing Package](https://pkg.go.dev/testing)
- [Testify Assertions](https://github.com/stretchr/testify)
- [Terraform Testing](https://www.terraform.io/docs/language/modules/testing.html) 