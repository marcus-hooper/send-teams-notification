[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Import the module from the same directory
$modulePath = Join-Path $PSScriptRoot 'Send-TeamsNotification.psm1'
Import-Module $modulePath -Force

try {
    $webhookUrl = $env:INPUT_WEBHOOK_URL
    $repo = if ($env:INPUT_REPOSITORY) { $env:INPUT_REPOSITORY } else { $env:GITHUB_REPO_FALLBACK }
    $actor = if ($env:INPUT_ACTOR) { $env:INPUT_ACTOR } else { $env:GITHUB_ACTOR_FALLBACK }

    $result = Send-TeamsNotification `
        -WebhookUrl $webhookUrl `
        -JobStatus $env:INPUT_JOB_STATUS `
        -Repository $repo `
        -Actor $actor `
        -Environment $env:INPUT_ENVIRONMENT `
        -CardTitle $env:INPUT_CARD_TITLE `
        -CommitMessages $env:INPUT_COMMIT_MESSAGES `
        -RunId $env:GITHUB_RUN_ID

    # Set GitHub Actions outputs
    "sent=true" >> $env:GITHUB_OUTPUT
    "payload_bytes=$($result.PayloadBytes)" >> $env:GITHUB_OUTPUT
    "run_url=$($result.RunUrl)" >> $env:GITHUB_OUTPUT
    "status_code=200" >> $env:GITHUB_OUTPUT
}
catch {
    $msg = "❌ Failed to send Teams notification. $($_.Exception.Message)"
    try {
        $resp = $_.Exception.Response
        if ($resp -and $resp.GetResponseStream) {
            $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $respBody = $reader.ReadToEnd()
            if ($respBody) { $msg += "`nResponse body:`n$respBody" }
        }
    }
    catch { }
    Write-Error $msg
    throw
}
