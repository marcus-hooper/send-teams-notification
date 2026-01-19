# Changelog

All notable changes to send-teams-notification are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-01-19

### Added

- CHANGELOG.md to track project changes
- CHANGELOG validation in CI workflow
- Integration test job in CI workflow
- Cross-platform CI testing (Ubuntu, Windows, macOS)
- CONTRIBUTING.md with contribution guidelines
- Dependabot configuration for automated dependency updates

### Changed

- Improved CI workflow with more precise action version comments
- Updated github/codeql-action from v3 to v4
- Updated ossf/scorecard-action from 2.4.0 to 2.4.3
- Updated issue templates from Markdown to YAML forms
- Use JUnitXml format for Pester test output
- Replace heredocs with env vars for multiline strings in workflows

### Fixed

- Single commit array handling bug
- PSScriptAnalyzer warnings for empty catch block and ShouldProcess
- Inconsistent action versions across workflows (standardized harden-runner to v2.14.0, checkout to v6.0.1, codeql-action to consistent SHA)
- CodeQL bundle download now allowed in harden-runner egress policy
- Corrected property and parameter names in CI cross-platform test
- Fixed PowerShell formatting in send-teams.ps1
- Security scan false positive

### Security

- CI/CD workflows for releases, security scanning, action validation, and scheduled health checks
- CodeQL workflow for SAST analysis
- OSSF Scorecard workflow for security analysis
- SECURITY.md with vulnerability reporting guidelines
- Pin all GitHub Actions to commit SHAs for supply chain security

## [1.0.0] - 2025-09-25

### Added

- Initial release
- GitHub Action (composite) for sending Adaptive Cards to Microsoft Teams via Incoming Webhooks
- PowerShell 7 module with testable functions
- Adaptive Card 1.5 support with status-based styling (success/failure/cancelled)
- Configurable card title, environment label, and commit messages display
- "View Run" action button linking to workflow run
- Pester unit tests with mocking support
- CI workflow with PSScriptAnalyzer linting

### Fixed

- Path separator in action.yml for cross-platform PowerShell script execution

---

<!--
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality
- **BREAKING**: Description of breaking change

### Deprecated
- Features to be removed in future versions

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements or vulnerability fixes
-->

[Unreleased]: https://github.com/marcus-hooper/send-teams-notification/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/marcus-hooper/send-teams-notification/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/marcus-hooper/send-teams-notification/releases/tag/v1.0.0
