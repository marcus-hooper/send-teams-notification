# Send Teams Notification (Adaptive Cards)

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
        uses: owner/repo@v1
        with:
          job_status: ${{ job.status }}
          webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
```

With environment and custom title:

```yaml
- name: Send Teams notification
  if: ${{ always() }}
  uses: owner/repo@v1
  with:
    job_status: ${{ job.status }}
    environment: "production"
    card_title: "🔔 Deployment"
    webhook_url: ${{ secrets.TEAMS_WEBHOOK_URL }}
```

## Inputs

- job_status (required): success, failure, or cancelled
- webhook_url (required): Teams Incoming Webhook URL (store in secrets)
- commit_messages (optional): JSON array for a FactSet, e.g. [{"title":"SHA","value":"Message"}]
- environment (optional): Deployment environment label
- card_title (optional): Title for the card (default: "🔔 GitHub Deployment")
- repository (optional): Overrides repo shown (defaults to github.repository)
- actor (optional): Overrides actor shown (defaults to github.actor)
- run_id (optional): Explicit run id (defaults from context if omitted)

## Outputs

- sent: Whether a POST to Teams was attempted
- status_code: HTTP status code from Teams (200 on success)
- payload_bytes: Size of the JSON payload in bytes
- run_url: Link to the workflow run

Note: If an output is empty, ensure you’re on the latest version of the action. Outputs are produced by the PowerShell script.

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
