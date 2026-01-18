# Contributing to send-teams-notification

Thank you for your interest in contributing to send-teams-notification!

## Development Setup

### Prerequisites

- PowerShell 7+
- [Pester 5.x](https://pester.dev/) (testing framework)
- Git

### Clone and Test

```powershell
git clone https://github.com/marcus-hooper/send-teams-notification.git
cd send-teams-notification
Invoke-Pester ./tests -Output Detailed
```

## Running CI Locally

Before pushing, run the same checks as CI:

```powershell
# Lint check (must pass)
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery

# Unit tests (must pass)
Invoke-Pester ./tests -Output Detailed
```

### With Code Coverage

```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.Output.Verbosity = 'Detailed'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @('./scripts/send-teams.ps1', './scripts/Send-TeamsNotification.psm1')
Invoke-Pester -Configuration $config
```

### Quick CI Script

```powershell
# All-in-one CI check
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery; if ($?) { Invoke-Pester ./tests -Output Detailed }
```

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>: <description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `ci` | CI/workflow changes |
| `deps` | Dependency updates |
| `security` | Security improvements |
| `chore` | Maintenance tasks |
| `perf` | Performance improvement |

### Examples

```
feat: add support for custom card actions

fix: handle empty commit_messages array gracefully

docs: update webhook configuration instructions

test: add tests for Build-FactsArray edge cases

ci: update actions/checkout to latest version

chore: clean up unused test fixtures

perf: optimize JSON serialization in payload builder
```

### Breaking Changes

For breaking changes, use `!` after the type or add a `BREAKING CHANGE:` footer:

```
feat!: change webhook payload format

Card body structure changed to support new Teams requirements.
```

Or with a footer:

```
feat: change webhook payload format

BREAKING CHANGE: Card body structure changed to support new Teams requirements.
```

## Pull Request Process

### Before Opening a PR

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Run CI locally** (see above)

3. **Add tests** for new functionality

4. **Update CHANGELOG.md** under `[Unreleased]` if applicable

### PR Requirements

All PRs must pass these checks before merge:

| Check | Command | Threshold |
|-------|---------|-----------|
| Lint | `Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery` | No errors |
| Tests | `Invoke-Pester ./tests` | All pass |
| Coverage | Collected automatically | 80%+ target (not enforced) |

### PR Description

Include in your PR description:

- Summary of changes
- Related issue (if any)
- Type of change (bug fix, feature, etc.)
- Testing performed

### Code Review

- All PRs require review before merge
- Address review feedback promptly
- Resolve all conversations before merge
- Squash merge to `main`

## Coding Standards

### PowerShell Best Practices

```powershell
# Use ErrorAction Stop for critical operations
Invoke-RestMethod -Uri $url -Method Post -Body $body -ErrorAction Stop

# Use try/catch for error handling
try {
    # ... operation
} catch {
    throw "Operation failed: $_"
}

# Add SupportsShouldProcess for state-changing functions
function Send-Something {
    [CmdletBinding(SupportsShouldProcess)]
    param(...)
}
```

### Project-Specific Guidelines

- **UTF-8 encoding** without BOM for all files
- **Emoji characters** must be constructed from Unicode code points to avoid YAML encoding issues:
  ```powershell
  # Correct
  $emoji = [char]::ConvertFromUtf32(0x2705)

  # Avoid (causes YAML issues)
  $emoji = "✅"
  ```
- **Export functions** via `Export-ModuleMember` in the module file
- **Add Pester tests** for all new exported functions

### Module Structure

When adding new functions to `Send-TeamsNotification.psm1`:

1. Add the function implementation
2. Add it to `Export-ModuleMember -Function`
3. Add corresponding tests in `Send-TeamsNotification.Tests.ps1`

## Test Requirements

### Running Tests

```powershell
# Run all tests
Invoke-Pester ./tests -Output Detailed

# Run tests with coverage
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.Output.Verbosity = 'Detailed'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @('./scripts/send-teams.ps1', './scripts/Send-TeamsNotification.psm1')
Invoke-Pester -Configuration $config
```

### Adding Tests

| Change Type | Test Requirement |
|-------------|------------------|
| New function | Add unit tests covering happy path and error cases |
| Bug fix | Add regression test that fails without the fix |
| Refactor | Ensure existing tests still pass |

Tests are located in `tests/Send-TeamsNotification.Tests.ps1`. See existing tests for patterns on mocking `Invoke-RestMethod`.

## Issue Guidelines

### Bug Reports

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml). Include:

- PowerShell version (`$PSVersionTable.PSVersion`)
- Steps to reproduce
- Expected vs actual behavior
- Relevant error messages

### Feature Requests

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml). Include:

- Problem statement
- Proposed solution
- Alternatives considered

## Release Process

Releases are managed by maintainers:

1. All CI checks pass on `main`
2. CHANGELOG.md updated with version and date
3. Tag created: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Tag pushed: `git push origin v1.0.0`
5. GitHub Actions creates release and updates major version tag (`v1`)

## Getting Help

- **Questions**: Open a [Discussion](https://github.com/marcus-hooper/send-teams-notification/discussions)
- **Bugs**: Open an [Issue](https://github.com/marcus-hooper/send-teams-notification/issues)
- **Features**: Open an [Issue](https://github.com/marcus-hooper/send-teams-notification/issues)
- **Security**: See [SECURITY.md](SECURITY.md)

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
