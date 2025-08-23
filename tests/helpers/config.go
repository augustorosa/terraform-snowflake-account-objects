package helpers

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"
)

// TestConfig represents the test configuration structure
type TestConfig struct {
	SnowflakeAccount   string            `yaml:"snowflake_account"`
	SnowflakeRegion    string            `yaml:"snowflake_region"`
	SnowflakeUser      string            `yaml:"snowflake_user"`
	SnowflakePassword  string            `yaml:"snowflake_password"`
	SnowflakeRole      string            `yaml:"snowflake_role"`
	SnowflakeWarehouse string            `yaml:"snowflake_warehouse"`
	TestEnvironment    string            `yaml:"test_environment"`
	TestTags           map[string]string `yaml:"test_tags"`
}

// LoadTestConfig loads test configuration from a YAML file
func LoadTestConfig(t *testing.T, configPath string) *TestConfig {
	t.Helper()

	// Check if config file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		// Try to load from environment variables
		return LoadTestConfigFromEnv(t)
	}

	// Read the config file
	data, err := ioutil.ReadFile(configPath)
	require.NoError(t, err, "Failed to read config file")

	// Parse the YAML
	var config TestConfig
	err = yaml.Unmarshal(data, &config)
	require.NoError(t, err, "Failed to parse config file")

	// Override with environment variables if set
	config = mergeWithEnvVars(config)

	// Validate required fields
	validateTestConfig(t, &config)

	return &config
}

// LoadTestConfigFromEnv loads test configuration from environment variables
func LoadTestConfigFromEnv(t *testing.T) *TestConfig {
	t.Helper()

	config := &TestConfig{
		SnowflakeAccount:   os.Getenv("SNOWFLAKE_ACCOUNT"),
		SnowflakeRegion:    getEnvOrDefault("SNOWFLAKE_REGION", "us-west-2"),
		SnowflakeUser:      os.Getenv("SNOWFLAKE_USER"),
		SnowflakePassword:  os.Getenv("SNOWFLAKE_PASSWORD"),
		SnowflakeRole:      getEnvOrDefault("SNOWFLAKE_ROLE", "SYSADMIN"),
		SnowflakeWarehouse: getEnvOrDefault("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH"),
		TestEnvironment:    getEnvOrDefault("TEST_ENVIRONMENT", "test"),
		TestTags: map[string]string{
			"Environment": getEnvOrDefault("TEST_ENVIRONMENT", "test"),
			"ManagedBy":   "terraform",
			"Purpose":     "testing",
		},
	}

	validateTestConfig(t, config)
	return config
}

// mergeWithEnvVars merges configuration with environment variables
func mergeWithEnvVars(config TestConfig) TestConfig {
	if val := os.Getenv("SNOWFLAKE_ACCOUNT"); val != "" {
		config.SnowflakeAccount = val
	}
	if val := os.Getenv("SNOWFLAKE_REGION"); val != "" {
		config.SnowflakeRegion = val
	}
	if val := os.Getenv("SNOWFLAKE_USER"); val != "" {
		config.SnowflakeUser = val
	}
	if val := os.Getenv("SNOWFLAKE_PASSWORD"); val != "" {
		config.SnowflakePassword = val
	}
	if val := os.Getenv("SNOWFLAKE_ROLE"); val != "" {
		config.SnowflakeRole = val
	}
	if val := os.Getenv("SNOWFLAKE_WAREHOUSE"); val != "" {
		config.SnowflakeWarehouse = val
	}
	if val := os.Getenv("TEST_ENVIRONMENT"); val != "" {
		config.TestEnvironment = val
	}
	return config
}

// validateTestConfig validates that required configuration is present
func validateTestConfig(t *testing.T, config *TestConfig) {
	t.Helper()

	// Skip validation in unit test mode
	if os.Getenv("TF_ACC") != "1" {
		return
	}

	require.NotEmpty(t, config.SnowflakeAccount, "Snowflake account is required for integration tests")
	require.NotEmpty(t, config.SnowflakeUser, "Snowflake user is required for integration tests")
	require.NotEmpty(t, config.SnowflakePassword, "Snowflake password is required for integration tests")
}

// getEnvOrDefault returns environment variable value or default
func getEnvOrDefault(key, defaultValue string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultValue
}

// WriteTestYAMLConfig writes a YAML configuration to a temporary file
func WriteTestYAMLConfig(t *testing.T, config interface{}, filename string) string {
	t.Helper()

	// Create temp directory
	tmpDir := t.TempDir()
	filePath := filepath.Join(tmpDir, filename)

	// Marshal to YAML
	data, err := yaml.Marshal(config)
	require.NoError(t, err, "Failed to marshal config to YAML")

	// Write to file
	err = ioutil.WriteFile(filePath, data, 0644)
	require.NoError(t, err, "Failed to write config file")

	return filePath
}

// LoadYAMLFile loads a YAML file into the provided interface
func LoadYAMLFile(t *testing.T, path string, v interface{}) {
	t.Helper()

	data, err := ioutil.ReadFile(path)
	require.NoError(t, err, fmt.Sprintf("Failed to read file: %s", path))

	err = yaml.Unmarshal(data, v)
	require.NoError(t, err, fmt.Sprintf("Failed to parse YAML file: %s", path))
}

// GetTestFixturePath returns the path to a test fixture file
func GetTestFixturePath(t *testing.T, filename string) string {
	t.Helper()

	// Get the current test file location
	_, currentFile, _, ok := runtime.Caller(1)
	require.True(t, ok, "Failed to get current file path")

	// Navigate to the fixtures directory
	testDir := filepath.Dir(currentFile)
	fixturesDir := filepath.Join(testDir, "..", "fixtures")
	fixturePath := filepath.Join(fixturesDir, filename)

	// Check if file exists
	_, err := os.Stat(fixturePath)
	require.NoError(t, err, fmt.Sprintf("Fixture file not found: %s", fixturePath))

	return fixturePath
}

// CreateTempYAMLFile creates a temporary YAML file from a map
func CreateTempYAMLFile(t *testing.T, data map[string]interface{}) string {
	t.Helper()

	tmpFile, err := ioutil.TempFile("", "test-*.yaml")
	require.NoError(t, err, "Failed to create temp file")

	defer tmpFile.Close()

	encoder := yaml.NewEncoder(tmpFile)
	err = encoder.Encode(data)
	require.NoError(t, err, "Failed to encode YAML")

	return tmpFile.Name()
}
