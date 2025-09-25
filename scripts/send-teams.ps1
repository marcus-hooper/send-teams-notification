[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Emoji via code points to avoid YAML/encoding issues
$noteEmoji = [System.Char]::ConvertFromUtf32(0x1F4DD) # 📝
$viewEmoji = [System.Char]::ConvertFromUtf32(0x1F50E) # 🔎

try {
    $webhookUrl = $env:INPUT_WEBHOOK_URL
    if ([string]::IsNullOrWhiteSpace($webhookUrl)) { throw "No webhook_url provided." }

    $repo = $env:INPUT_REPOSITORY; if (-not $repo) { $repo = $env:GITHUB_REPO_FALLBACK }
    $actor = $env:INPUT_ACTOR; if (-not $actor) { $actor = $env:GITHUB_ACTOR_FALLBACK }
    $status = $env:INPUT_JOB_STATUS
    $envName = $env:INPUT_ENVIRONMENT
    $title = $env:INPUT_CARD_TITLE

    switch ($status.ToLowerInvariant()) {
        'success' { $accentColor = '#107C10'; $statusStyle = 'good'; $statusEmoji = '✅' }
        'failure' { $accentColor = '#D13438'; $statusStyle = 'attention'; $statusEmoji = '❌' }
        default { $accentColor = '#F2C744'; $statusStyle = 'warning'; $statusEmoji = '⚠️' }
    }

    # Base facts
    $facts = @(
        @{ title = 'Repository'; value = "[${repo}](https://github.com/${repo})" }
    )
    if ($envName) { $facts += @{ title = 'Environment'; value = $envName } }
    $facts += @{ title = 'Started by'; value = $actor }

    # Parse commit messages (tolerate double-encoded JSON)
    $commitFacts = $null
    $commitJson = $env:INPUT_COMMIT_MESSAGES
    if ($commitJson -and $commitJson -ne '[]') {
        try {
            $commitFacts = $commitJson | ConvertFrom-Json -ErrorAction Stop
            if ($commitFacts -is [string]) {
                $commitFacts = $commitFacts | ConvertFrom-Json -ErrorAction Stop
            }
        }
        catch {
            Write-Warning "commit_messages is not valid JSON. Skipping commit section."
        }
    }

    # Card body
    $body = @(
        @{ type = 'TextBlock'; size = 'Large'; weight = 'Bolder'; text = $title; wrap = $true }
        @{ type = 'Container'; style = $statusStyle; items = @(
                @{ type = 'TextBlock'; text = "$statusEmoji Status: $status"; weight = 'Bolder'; wrap = $true }
            )
        }
        @{ type = 'FactSet'; facts = $facts }
    )

    if ($commitFacts) {
        # Render each commit as TextBlock
        $commitItems = foreach ($c in $commitFacts) {
            @{
                type = 'TextBlock'
                text = "- $($c.title): $($c.value)"  # value already contains markdown link
                wrap = $true
            }
        }

        $commitCount = @($commitFacts).Count

        # Toggle button
        $toggleAction = @{
            type    = 'ActionSet'
            actions = @(
                @{
                    type           = 'Action.ToggleVisibility'
                    title          = "$noteEmoji Recent Commits ($commitCount)"
                    targetElements = @('commitsSection')
                }
            )
        }

        # Collapsible container
        $commitContainer = @{
            type      = 'Container'
            id        = 'commitsSection'
            isVisible = $false
            items     = @(
                @{ type = 'TextBlock'; weight = 'Bolder'; text = 'Recent commits:'; wrap = $true; separator = $true }
                @{ type = 'Container'; items = $commitItems; spacing = 'Small' }
            )
        }

        $body += @(
            $toggleAction
            $commitContainer
        )
    }

    $runUrl = "https://github.com/$repo/actions/runs/$($env:GITHUB_RUN_ID)"

    $body += @{
        type    = 'ActionSet'
        actions = @(
            @{ type = 'Action.OpenUrl'; title = "$viewEmoji View Run"; url = $runUrl }
        )
    }

    # Teams payload
    $payload = @{
        type        = 'message'
        attachments = @(
            @{
                contentType = 'application/vnd.microsoft.card.adaptive'
                contentUrl  = $null
                content     = @{
                    '$schema'    = 'http://adaptivecards.io/schemas/adaptive-card.json'
                    type         = 'AdaptiveCard'
                    version      = '1.5'
                    body         = $body
                    selectAction = $null
                }
            }
        )
    }

    $json = $payload | ConvertTo-Json -Depth 30

    # Send as UTF-8 (no BOM) bytes
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $bodyBytes = $utf8NoBom.GetBytes($json)

    Write-Host "Sending Teams notification..."
    $null = Invoke-RestMethod -Method Post -Uri $webhookUrl -ContentType 'application/json; charset=utf-8' -Body $bodyBytes
    Write-Host "✅ Teams notification sent successfully."
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