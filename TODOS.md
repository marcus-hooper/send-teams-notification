# TODOS

## Send-TeamsNotification

### Power Automate Workflow support

**What:** Add support for Power Automate Workflow URLs as an alternative transport to Teams Incoming Webhooks.

**Why:** Microsoft has announced Incoming Webhook deprecation (timeline TBD). Without this, users will need to fork or find a replacement action when webhooks stop working.

**Context:** Power Automate Workflow URLs match `*.logic.azure.com` while current webhook URLs match `*.webhook.office.com`. The `Test-WebhookUrl` function being added in v2 can be extended to detect URL type and route to the appropriate payload builder. The payload format for Power Automate may differ (simpler JSON vs full Adaptive Card wrapping). Blocked until Microsoft finalizes the payload format and deprecation timeline. CEO review (2026-03-18) accepted this as strategic but deferred.

**Effort:** M
**Priority:** P2
**Depends on:** Microsoft finalizing Power Automate webhook payload format and deprecation timeline

## Completed
