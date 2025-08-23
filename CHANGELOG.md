# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial module structure and documentation
- Foundation module for account-level configurations
- RBAC module for role-based access control
- Database module for database management
- Warehouse module for compute resources
- Security module with MFA, authentication, and password policies
- Integration support for dbt, Airflow, and Fivetran
- Auto-tagging system for governance
- Comprehensive testing framework with Terratest
- CI/CD pipeline with GitHub Actions
- Semantic versioning with automated releases
- YAML-based configuration support
- Multi-environment architecture (single and multi-account)
- Migration guide for existing Snowflake resources
- Security-first approach with Snowflake best practices

### Security
- MFA enforcement by default
- User type classification (PERSON, SERVICE, LEGACY_SERVICE)
- Network policies for IP allowlisting
- Session policies for timeout management
- Password complexity requirements
- Authentication policies with client type restrictions
- Break-glass procedures documentation

[Unreleased]: https://github.com/augustorosa/terraform-snowflake-account-objects/compare/v0.0.0...HEAD 