# Send Teams Notification (Adaptive Cards)

[![CI](https://github.com/marcus-hooper/send-teams-notification/actions/workflows/ci.yml/badge.svg)](https://github.com/marcus-hooper/send-teams-notification/actions/workflows/ci.yml)
[![CodeQL](https://github.com/marcus-hooper/send-teams-notification/actions/workflows/codeql.yml/badge.svg)](https://github.com/marcus-hooper/send-teams-notification/actions/workflows/codeql.yml)
[![GitHub release](https://img.shields.io/github/v/release/marcus-hooper/send-teams-notification)](https://github.com/marcus-hooper/send-teams-notification/releases)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/marcus-hooper/send-teams-notification/badge)](https://securityscorecards.dev/viewer/?uri=github.com/marcus-hooper/send-teams-notification)
[![PowerShell 7](https://img.shields.io/badge/PowerShell-7-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A composite GitHub Action that posts Adaptive Cards to Microsoft Teams via Incoming Webhooks.

## Features

- Sends rich Adaptive Card notifications to Microsoft Teams channels
- Status styling with colors and emoji (success/failure/warning)
- Displays repository, actor, and optional environment information
- Optional collapsible commit history section
- UTF-8-safe emoji handling (constructed from Unicode code points)
- PowerShell 7 with no external dependencies
- Works on Linux, Windows, and macOS runners

## Quick Start

Minimal usage (sends on success and failure):

```yaml
jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Send Teams notification
        if: ${{ always() }}
        uses: marcus-hooper/send-teams-notification@v1
        with:
          job_status: ${{ job.status }}
          webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
```

With environment and custom title:

```yaml
- name: Send Teams notification
  if: ${{ always() }}
  uses: marcus-hooper/send-teams-notification@v1
  with:
    job_status: ${{ job.status }}
    environment: production
    card_title: "🔔 Deployment"
    webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
```

With commit messages (collapsible section in card):

```yaml
- name: Get recent commits
  id: commits
  run: |
    COMMITS=$(git log --pretty=format:'{"title":"%h","value":"[%s](https://github.com/${{ github.repository }}/commit/%H)"}' -3 | jq -s '.')
    echo "json=$COMMITS" >> $GITHUB_OUTPUT

- name: Send Teams notification
  if: ${{ always() }}
  uses: marcus-hooper/send-teams-notification@v1
  with:
    job_status: ${{ job.status }}
    commit_messages: ${{ steps.commits.outputs.json }}
    webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
```

### Complete Workflow Example

Here's a complete deployment workflow with Teams notification:

```yaml
name: Deploy and Notify

on:
  push:
    branches: [main]

jobs:
  deploy:
    name: Deploy Application
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 5

      - name: Deploy to production
        run: |
          # Your deployment steps here
          echo "Deploying application..."

      - name: Get recent commits
        id: commits
        run: |
          COMMITS=$(git log --pretty=format:'{"title":"%h","value":"[%s](https://github.com/${{ github.repository }}/commit/%H)"}' -3 | jq -s '.')
          echo "json=$COMMITS" >> $GITHUB_OUTPUT

      - name: Send Teams notification
        if: ${{ always() }}
        uses: marcus-hooper/send-teams-notification@v1
        with:
          job_status: ${{ job.status }}
          environment: ${{ github.environment }}
          card_title: "🚀 Production Deployment"
          commit_messages: ${{ steps.commits.outputs.json }}
          webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
```

## Sample Card Output

The action sends an Adaptive Card to Teams with the following structure:

```
┌─────────────────────────────────────────────────┐
│ 🚀 Production Deployment                        │
├─────────────────────────────────────────────────┤
│ ✅ Success                                      │
│                                                 │
│ Repository    owner/repo                        │
│ Environment   production                        │
│ Actor         username                          │
│                                                 │
│ ▶ Recent Commits (tap to expand)               │
│   abc1234  Fix authentication bug               │
│   def5678  Add new feature                      │
│   ghi9012  Update dependencies                  │
│                                                 │
│ [View Run]                                      │
└─────────────────────────────────────────────────┘
```

**Status Styling:**
| Status | Color | Emoji |
|--------|-------|-------|
| Success | Green (#107C10) | ✅ |
| Failure | Red (#D13438) | ❌ |
| Cancelled/Other | Yellow (#F2C744) | ⚠️ |

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `job_status` | Yes | | Status of the job: `success`, `failure`, or `cancelled` |
| `webhook_url` | Yes | | Teams Incoming Webhook URL (store in secrets) |
| `commit_messages` | No | `[]` | JSON array for FactSet, e.g. `[{"title":"SHA","value":"Message"}]` |
| `environment` | No | | Deployment environment label |
| `card_title` | No | `🔔 GitHub Deployment` | Title for the card |
| `repository` | No | `github.repository` | Repository name to display |
| `actor` | No | `github.actor` | Actor name to display |
| `run_id` | No | `github.run_id` | Workflow run ID for the "View Run" link |

## Outputs

| Output | Description |
|--------|-------------|
| `sent` | Whether a POST to Teams was attempted |
| `payload_bytes` | Size of the JSON payload in bytes |
| `run_url` | Link to the workflow run |

## Requirements

- GitHub-hosted runners (Linux/Windows/macOS) with PowerShell 7 available (default on GitHub runners)
- Microsoft Teams Incoming Webhook connector configured for the target channel

## Limitations

| Limitation | Details |
|------------|---------|
| Teams webhook only | Does not support Bot Framework or Graph API delivery |
| No retry logic | Single attempt to send; fails immediately on HTTP error |
| Card size limit | Teams limits Adaptive Cards to ~28KB; large commit lists may be truncated |
| Webhook rate limits | Teams may throttle frequent webhook calls |
| No message updates | Cannot update or delete sent cards (webhook limitation) |
| Encoding sensitivity | Requires UTF-8 without BOM; emoji via code points to avoid YAML issues |

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| 400/BadRequest | Teams rejects malformed or oversized cards | Keep payload < ~28 KB |
| Nothing appears in Teams | Webhook URL invalid or connector disabled | Verify the webhook URL and that the channel has the Incoming Webhook connector |
| Emoji or characters look wrong | Encoding issues | Ensure your YAML files are UTF-8 without BOM |
| No commits section | Invalid JSON | Ensure commit_messages is valid JSON (quote properly and avoid YAML mangling) |
| 403/Forbidden | Webhook URL expired or revoked | Generate a new webhook URL in Teams |

### Debug Tips

1. **Check workflow logs** - Expand the "Send Teams notification" step for detailed output
2. **Verify webhook URL** - Test the webhook URL manually with a simple curl/Invoke-RestMethod call
3. **Check payload size** - The `payload_bytes` output shows the JSON size; keep it under 28KB
4. **Validate commit JSON** - Add a step to echo `${{ steps.commits.outputs.json }}` to verify format
5. **Test locally** - Run the PowerShell script directly with environment variables set (see Development section)

## How It Works

1. Builds an Adaptive Card 1.5 with status styling and optional collapsible commit list
2. Sends via Teams Incoming Webhook as an attachment payload
3. Derives repo/actor from GitHub context if not provided

## Development

### Requirements

- PowerShell 7+
- Pester 5.x (for tests)
- PSScriptAnalyzer (for linting)

### Local Testing

```powershell
# Run Pester tests
Invoke-Pester ./tests -Output Detailed

# Run tests with coverage
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.Output.Verbosity = 'Detailed'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @('./scripts/send-teams.ps1', './scripts/Send-TeamsNotification.psm1')
Invoke-Pester -Configuration $config
```

### Linting

```powershell
# Install PSScriptAnalyzer if needed
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

# Run linter
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery
```

### Manual Testing

For end-to-end testing with a real Teams channel:

```powershell
$env:INPUT_WEBHOOK_URL = 'https://outlook.office.com/webhook/...'
$env:INPUT_JOB_STATUS = 'success'
$env:INPUT_REPOSITORY = 'owner/repo'
$env:INPUT_ACTOR = 'username'
$env:INPUT_RUN_ID = '123456789'
./scripts/send-teams.ps1
```

## Project Structure

```
send-teams-notification/
├── action.yml                  # GitHub Action definition (composite action)
├── scripts/
│   ├── send-teams.ps1          # Entry point script
│   └── Send-TeamsNotification.psm1  # PowerShell module with testable functions
├── tests/
│   └── Send-TeamsNotification.Tests.ps1  # Pester unit tests
├── .github/
│   ├── dependabot.yml          # Dependabot configuration
│   ├── labels.yml              # Repository label definitions
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml      # Bug report form
│   │   ├── feature_request.yml # Feature request form
│   │   └── config.yml          # Issue template chooser config
│   └── workflows/
│       ├── ci.yml              # CI workflow (lint, test, coverage)
│       ├── codeql.yml          # CodeQL security analysis
│       ├── dependabot-auto-merge.yml  # Auto-merge Dependabot PRs
│       ├── labels.yml          # Label synchronization
│       ├── release.yml         # Major version tag updates
│       ├── schedule.yml        # Weekly health check
│       ├── scorecard.yml       # OpenSSF Scorecard analysis
│       ├── security.yml        # Security scanning
│       └── validate.yml        # Action validation
├── README.md                   # This file
├── CHANGELOG.md                # Version history
├── CONTRIBUTING.md             # Contribution guidelines
├── SECURITY.md                 # Security policy
├── LICENSE                     # MIT License
└── .gitignore                  # Git ignore patterns
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

Quick start:

1. Check existing [issues](https://github.com/marcus-hooper/send-teams-notification/issues) or open a new one
2. Fork the repository
3. Create a feature branch (`git checkout -b feature/my-feature`)
4. Make your changes and add tests if applicable
5. Ensure CI passes (lint and test)
6. Submit a pull request

See the issue templates for [bug reports](.github/ISSUE_TEMPLATE/bug_report.yml) and [feature requests](.github/ISSUE_TEMPLATE/feature_request.yml).

## Security

- Store `webhook_url` in GitHub Secrets (e.g., `TEAMS_WEBHOOK_URL`)
- Do not echo or log the webhook URL
- Review branch protections for workflows that can send notifications

See [SECURITY.md](SECURITY.md) for security policy and reporting vulnerabilities.

## License

MIT License - see [LICENSE](LICENSE) for details.
