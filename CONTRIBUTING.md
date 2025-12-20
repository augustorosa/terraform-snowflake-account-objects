# Contributing to Terraform Snowflake Account Objects

First off, thank you for considering contributing to this project! 🎉

This document provides guidelines for contributing to the Terraform Snowflake Account Objects module. Following these guidelines helps maintain code quality and ensures a smooth collaboration process.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Commit Convention](#commit-convention)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Release Process](#release-process)

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful and constructive in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/terraform-snowflake-account-objects.git`
3. Add upstream remote: `git remote add upstream https://github.com/augustorosa/terraform-snowflake-account-objects.git`
4. Create a feature branch: `git checkout -b feat/your-feature-name`

## Development Setup

### Prerequisites

- Terraform >= 1.10.0
- Go >= 1.21 (for testing)
- Pre-commit hooks
- Node.js >= 20 (for semantic release)

### Setup Steps

```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Install commit message helper
npm install -g commitizen
npm install -g cz-conventional-changelog

# Install Go dependencies
cd tests
go mod download

# Install Terraform
tfenv install 1.10.5
tfenv use 1.10.5
```

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/) for our commit messages. This enables automatic versioning and changelog generation.

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Rules:**
- Header (first line) must be ≤ 100 characters
- Body lines must be ≤ 120 characters
- Subject must start with lowercase letter (or version number like `v0.6.0`)
- Body and footer must be separated by blank line
- Use imperative mood ("add feature" not "added feature")

### Types

- **feat**: New feature (MINOR version bump)
- **fix**: Bug fix (PATCH version bump)
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Test additions or corrections
- **build**: Build system changes
- **ci**: CI/CD changes
- **chore**: Maintenance tasks
- **revert**: Revert previous commit

### Scopes

- **foundation**: Foundation module changes
- **rbac**: RBAC module changes
- **database**: Database module changes
- **warehouse**: Warehouse module changes
- **security**: Security module changes
- **integration**: Integration module changes
- **tagging**: Tagging system changes
- **docs**: Documentation
- **examples**: Example configurations
- **tests**: Test framework
- **ci**: CI/CD pipeline
- **deps**: Dependency updates

### Examples

```bash
# Feature (simple)
feat(database): add support for transient tables

# Feature with body
feat(rbac): implement cross-environment project admin role

Added PROJECT_ADMIN_RL role that inherits from all environment
admin roles and SYSADMIN. This enables superusers to manage
resources across all environments.

# Bug fix
fix(rbac): correct role inheritance for custom roles

Fixed issue where custom roles with inherit_from attribute
were not properly inheriting parent role privileges.

# Breaking change
feat(warehouse)!: change default warehouse size to X-Small

BREAKING CHANGE: Default warehouse size changed from Small to X-Small.
Users must explicitly set size to maintain previous behavior.

# Documentation
docs(readme): add PR description guidelines

Added recommended PR description template and commit message
formatting rules to CONTRIBUTING.md.

# Multiple scopes (not recommended, prefer separate commits)
feat(database,warehouse): add cross-database query support

# Version release (special case)
feat: v0.6.0 - Major refactoring, provider 2.11.0, security enhancements
```

### Commit Message Best Practices

1. **Be Specific**: Clearly describe what changed
   - ❌ `fix: bug fix`
   - ✅ `fix(rbac): correct role inheritance lookup logic`

2. **Use Imperative Mood**: Write as if completing "This commit will..."
   - ❌ `feat: added new role`
   - ✅ `feat: add new role`

3. **Keep Subject Concise**: First line should be clear summary
   - ❌ `feat: implement a comprehensive role-based access control system with inheritance`
   - ✅ `feat(rbac): implement role inheritance hierarchy`

4. **Use Body for Context**: Explain why, not just what
   ```bash
   fix(security): prevent unauthorized database access
   
   Updated network policy validation to reject PUBLIC network
   rules. This prevents accidental exposure of databases to
   all IP addresses.
   ```

5. **Breaking Changes**: Always include BREAKING CHANGE footer
   ```bash
   feat(database)!: rename PREPARE layer to INT
   
   BREAKING CHANGE: The PREPARE layer has been renamed to INT
   (Integration). Update all references in your configurations.
   ```

### Using Commitizen

For interactive commit message creation:

```bash
git add .
npx cz
# or
git cz
```

## Pull Request Process

### Before Submitting

1. **Update from upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests locally**:
   ```bash
   cd tests
   go test -v ./...
   ```

3. **Format code**:
   ```bash
   terraform fmt -recursive
   go fmt ./...
   ```

4. **Update documentation** if needed

### PR Requirements

1. **Title**: Use conventional commit format
   - Example: `feat(rbac): add support for dynamic role creation`
   - Must start with type (feat, fix, docs, etc.)
   - Subject should start with uppercase letter or version number (e.g., `v0.6.0`)

2. **Description**: Include recommended sections (workflow will suggest if missing)
   
   **Recommended PR Description Template:**
   ```markdown
   ## Description
   Brief description of what this PR changes and why.
   
   ## Type of Change
   - [ ] Bug fix (non-breaking change which fixes an issue)
   - [ ] New feature (non-breaking change which adds functionality)
   - [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
   - [ ] Documentation update
   - [ ] Refactoring (no functional changes)
   - [ ] Performance improvement
   - [ ] Test updates
   
   ## Testing
   Describe the tests you ran to verify your changes:
   - [ ] Unit tests pass
   - [ ] Integration tests pass
   - [ ] Manual testing completed
   - [ ] Tested with example configurations
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex code
   - [ ] Documentation updated
   - [ ] No new warnings generated
   - [ ] Tests added/updated and passing
   - [ ] All commits follow conventional commit format
   ```

3. **Tests**: Add/update tests for your changes
   - Unit tests required for new features
   - Integration tests for complex scenarios

4. **Documentation**: Update relevant docs
   - README updates
   - Example configurations
   - API documentation

### Review Process

1. Automated checks must pass
2. At least one maintainer approval required
3. No unresolved conversations
4. Branch must be up-to-date with main

## Testing Guidelines

### Writing Tests

1. **Unit Tests**: Test individual module components
   ```go
   func TestNewFeature(t *testing.T) {
       t.Parallel()
       // Test implementation
   }
   ```

2. **Integration Tests**: Test module interactions
   ```go
   func TestIntegrationScenario(t *testing.T) {
       if os.Getenv("TF_ACC") != "1" {
           t.Skip("Skipping integration test")
       }
       // Test implementation
   }
   ```

### Test Coverage

- Aim for >80% coverage on new code
- Critical paths must have 100% coverage
- Use meaningful test cases, not just coverage

### Running Tests

```bash
# All tests
make test

# Unit tests only
make test-unit

# With coverage
make test-coverage
```

## Documentation

### Code Documentation

- Add comments for complex logic
- Document all public interfaces
- Include examples in comments

### Module Documentation

- Update README.md for user-facing changes
- Add examples for new features
- Document breaking changes clearly

### API Documentation

- Document all variables in `variables.tf`
- Document all outputs in `outputs.tf`
- Include descriptions and examples

## Release Process

Releases are automated using semantic-release based on commit messages.

### Automatic Release

When changes are merged to `main`:

1. Semantic-release analyzes commits
2. Determines version bump (major/minor/patch)
3. Updates CHANGELOG.md
4. Creates Git tag
5. Creates GitHub release
6. Updates VERSION file

### Manual Release (Emergency Only)

```bash
# Only for maintainers
npm run release -- --dry-run  # Preview
npm run release              # Execute
```

## Style Guidelines

### Terraform Style

- Use 2 spaces for indentation
- Use `snake_case` for resource names
- Group related resources together
- Add comments for complex logic

### Go Style

- Follow standard Go conventions
- Use meaningful variable names
- Add comments for exported functions
- Keep functions focused and small

## Questions?

- Open an issue for bugs or features
- Start a discussion for questions
- Contact maintainers for security issues

## Recognition

Contributors will be recognized in:
- CHANGELOG.md (automatic via commits)
- GitHub contributors page
- Special mentions for significant contributions

Thank you for contributing! 🚀 