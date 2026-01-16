# Send Teams Notification (Adaptive Cards)

[![CI](https://github.com/marcus-hooper/send-teams-notification/actions/workflows/ci.yml/badge.svg)](https://github.com/marcus-hooper/send-teams-notification/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/marcus-hooper/send-teams-notification/badge)](https://securityscorecards.dev/viewer/?uri=github.com/marcus-hooper/send-teams-notification)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Composite GitHub Action that posts Adaptive Cards to Microsoft Teams via Incoming Webhooks. It includes:
- Status styling (success/failure/warning) with emoji
- Repository, actor, optional environment facts
- Optional collapsible commit history
- UTF‑8‑safe emoji handling
- PowerShell 7, no external dependencies

## Quick start

Minimal usage (sends on success and failure):

```yaml
jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Send Teams notification
        if: ${{ always() }}
        uses: marcus-hooper/send-teams-notification@main
        with:
          job_status: ${{ job.status }}
          webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
```

With environment and custom title:

```yaml
- name: Send Teams notification
  if: ${{ always() }}
  uses: marcus-hooper/send-teams-notification@main
  with:
    job_status: ${{ job.status }}
    environment: "production"
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
  uses: marcus-hooper/send-teams-notification@main
  with:
    job_status: ${{ job.status }}
    commit_messages: ${{ steps.commits.outputs.json }}
    webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
```

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

## Security

- Store webhook_url in GitHub Secrets (e.g., TEAMS_WEBHOOK_URL)
- Do not echo or log the webhook URL
- Review branch protections for workflows that can send notifications

## Requirements

- GitHub‑hosted runners (Linux/Windows/macOS) with PowerShell 7 available (default on GitHub runners)
- Microsoft Teams Incoming Webhook connector configured for the target channel

## Troubleshooting

- 400/BadRequest: Teams rejects malformed or oversized cards (keep payload < ~28 KB)
- Nothing appears in Teams: Verify the webhook URL and that the channel has the Incoming Webhook connector
- Emoji or characters look wrong: This action forces UTF‑8; ensure your YAML files are UTF‑8 without BOM
- No commits section: Ensure commit_messages is valid JSON (quote properly and avoid YAML mangling)

## How it works

- Builds an Adaptive Card 1.5 with status styling and optional collapsible commit list
- Sends via Teams Incoming Webhook as an attachment payload
- Derives repo/actor from GitHub context if not provided
