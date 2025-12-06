package unit

import (
	"fmt"
	"strconv"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestFoundationModule tests the foundation module
func TestFoundationModule(t *testing.T) {
	t.Parallel()

	// Create a random ID to prevent naming conflicts
	uniqueID := random.UniqueId()
	testName := fmt.Sprintf("test-%s", uniqueID)

	// Root folder where Terraform files should be (relative to the test folder)
	rootFolder := "../../"
	terraformFolderRelativeToRoot := "modules/foundation"

	// Copy the terraform folder to a temp folder
	tempFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	// Define terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Vars: map[string]interface{}{
			"project_name":        testName,
			"environment":         "test",
			"snowflake_account":   "test_account",
			"snowflake_region":    "us-west-2",
			"enable_mfa":          true,
			"enable_auto_tagging": true,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terraform",
				"TestRun":     uniqueID,
			},
		},
		NoColor: true,
	}

	// Clean up resources with "terraform destroy" at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform plan" and fail the test if there are any errors
	terraform.InitAndPlan(t, terraformOptions)

	// Run "terraform apply" and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	// Run validation checks
	validateFoundationOutputs(t, terraformOptions)
	validateSecuritySettings(t, terraformOptions)
	validateTaggingSystem(t, terraformOptions)
}

// validateFoundationOutputs validates the outputs from the foundation module
func validateFoundationOutputs(t *testing.T, terraformOptions *terraform.Options) {
	// Check account level objects are created
	accountName := terraform.Output(t, terraformOptions, "account_name")
	assert.NotEmpty(t, accountName, "Account name should not be empty")

	// Check organization name
	orgName := terraform.Output(t, terraformOptions, "organization_name")
	assert.NotEmpty(t, orgName, "Organization name should not be empty")

	// Check if default roles are created
	defaultRoles := terraform.OutputList(t, terraformOptions, "default_roles")
	require.NotEmpty(t, defaultRoles, "Default roles should be created")

	expectedRoles := []string{"ACCOUNTADMIN", "SECURITYADMIN", "SYSADMIN", "USERADMIN", "PUBLIC"}
	for _, role := range expectedRoles {
		assert.Contains(t, defaultRoles, role, fmt.Sprintf("Default role %s should exist", role))
	}

	// Check if custom roles are created
	customRoles := terraform.OutputMap(t, terraformOptions, "custom_roles")
	assert.NotEmpty(t, customRoles, "Custom roles should be created")
}

// validateSecuritySettings validates security configurations
func validateSecuritySettings(t *testing.T, terraformOptions *terraform.Options) {
	// Check MFA enforcement
	mfaEnabled := terraform.Output(t, terraformOptions, "mfa_enforcement_enabled")
	assert.Equal(t, "true", mfaEnabled, "MFA enforcement should be enabled")

	// Check authentication policy
	authPolicy := terraform.OutputMap(t, terraformOptions, "authentication_policy")
	require.NotEmpty(t, authPolicy, "Authentication policy should be created")

	// Validate authentication policy settings
	assert.Equal(t, "true", authPolicy["mfa_enrollment_required"], "MFA enrollment should be required")
	assert.Equal(t, "900", authPolicy["client_types_session_timeout"], "Session timeout should be 15 minutes (900 seconds)")

	// Check network policy
	networkPolicy := terraform.OutputMap(t, terraformOptions, "network_policy")
	if len(networkPolicy) > 0 {
		assert.Contains(t, networkPolicy, "allowed_ip_list", "Network policy should contain allowed IP list")
		assert.Contains(t, networkPolicy, "blocked_ip_list", "Network policy should contain blocked IP list")
	}

	// Check password policy
	passwordPolicyRaw := terraform.OutputMap(t, terraformOptions, "password_policy")
	require.NotEmpty(t, passwordPolicyRaw, "Password policy should be created")

	// Validate password policy settings
	// terraform.OutputMap returns map[string]string, so we need to handle type conversion
	passwordPolicy := make(map[string]interface{})
	for k, v := range passwordPolicyRaw {
		passwordPolicy[k] = v
	}

	minLength, ok := passwordPolicy["min_length"].(string)
	if ok {
		// If it's a string, try to parse it
		minLengthFloat := 0.0
		if n, err := strconv.ParseFloat(minLength, 64); err == nil {
			minLengthFloat = n
		}
		assert.GreaterOrEqual(t, minLengthFloat, float64(12), "Password minimum length should be at least 12")
	} else {
		// Try as float64 directly
		if minLengthFloat, ok := passwordPolicy["min_length"].(float64); ok {
			assert.GreaterOrEqual(t, minLengthFloat, float64(12), "Password minimum length should be at least 12")
		}
	}

	assert.Equal(t, "true", passwordPolicyRaw["require_uppercase"], "Password should require uppercase")
	assert.Equal(t, "true", passwordPolicyRaw["require_lowercase"], "Password should require lowercase")
	assert.Equal(t, "true", passwordPolicyRaw["require_numeric"], "Password should require numeric")
	assert.Equal(t, "true", passwordPolicyRaw["require_special"], "Password should require special characters")
}

// validateTaggingSystem validates the auto-tagging system
func validateTaggingSystem(t *testing.T, terraformOptions *terraform.Options) {
	// Check if tag schema is created
	tagSchema := terraform.OutputMap(t, terraformOptions, "tag_schema")
	require.NotEmpty(t, tagSchema, "Tag schema should be created")

	// Validate required tag categories
	requiredCategories := []string{"governance", "operational", "technical"}
	for _, category := range requiredCategories {
		assert.Contains(t, tagSchema, category, fmt.Sprintf("Tag category %s should exist", category))
	}

	// Check if auto-tagging is enabled
	autoTaggingEnabled := terraform.Output(t, terraformOptions, "auto_tagging_enabled")
	assert.Equal(t, "true", autoTaggingEnabled, "Auto-tagging should be enabled")

	// Validate tag policies
	tagPolicies := terraform.OutputList(t, terraformOptions, "tag_policies")
	assert.NotEmpty(t, tagPolicies, "Tag policies should be created")

	// Check for required tags
	requiredTags := terraform.OutputList(t, terraformOptions, "required_tags")
	expectedTags := []string{"environment", "project", "owner", "cost_center"}
	for _, tag := range expectedTags {
		found := false
		for _, reqTag := range requiredTags {
			if strings.Contains(strings.ToLower(reqTag), tag) {
				found = true
				break
			}
		}
		assert.True(t, found, fmt.Sprintf("Required tag %s should be defined", tag))
	}
}

// TestFoundationModuleWithMinimalConfig tests the foundation module with minimal configuration
func TestFoundationModuleWithMinimalConfig(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	testName := fmt.Sprintf("test-minimal-%s", uniqueID)

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "modules/foundation"
	tempFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Vars: map[string]interface{}{
			"project_name":      testName,
			"environment":       "test",
			"snowflake_account": "test_account",
			"snowflake_region":  "us-west-2",
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	// This should work with minimal config
	terraform.InitAndPlan(t, terraformOptions)
}

// TestFoundationModuleInvalidConfig tests the foundation module with invalid configuration
func TestFoundationModuleInvalidConfig(t *testing.T) {
	t.Parallel()

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "modules/foundation"
	tempFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempFolder,
		Vars: map[string]interface{}{
			// Missing required variables
			"environment": "test",
		},
		NoColor: true,
	}

	// This should fail during plan
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Should fail with missing required variables")
}
