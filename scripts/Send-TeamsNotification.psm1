# Send-TeamsNotification Module
# Exports testable functions for building and sending Teams Adaptive Cards

function Get-StatusStyling {
    <#
    .SYNOPSIS
        Returns styling information based on job status.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Status
    )

    switch ($Status.ToLowerInvariant()) {
        'success' {
            @{
                AccentColor = '#107C10'
                Style       = 'good'
                Emoji       = '✅'
            }
        }
        'failure' {
            @{
                AccentColor = '#D13438'
                Style       = 'attention'
                Emoji       = '❌'
            }
        }
        default {
            @{
                AccentColor = '#F2C744'
                Style       = 'warning'
                Emoji       = '⚠️'
            }
        }
    }
}

function ConvertTo-CommitFact {
    <#
    .SYNOPSIS
        Parses commit messages JSON, handling double-encoded strings.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$CommitJson
    )

    if ([string]::IsNullOrWhiteSpace($CommitJson) -or $CommitJson -eq '[]') {
        return $null
    }

    try {
        $result = $CommitJson | ConvertFrom-Json -ErrorAction Stop
        # Handle double-encoded JSON
        if ($result -is [string]) {
            $result = $result | ConvertFrom-Json -ErrorAction Stop
        }
        return $result
    }
    catch {
        Write-Warning "commit_messages is not valid JSON. Skipping commit section."
        return $null
    }
}

function Build-FactsArray {
    <#
    .SYNOPSIS
        Builds the facts array for the Adaptive Card.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository,

        [Parameter(Mandatory)]
        [string]$Actor,

        [Parameter()]
        [string]$Environment
    )

    $facts = @(
        @{ title = 'Repository'; value = "[$Repository](https://github.com/$Repository)" }
    )

    if (-not [string]::IsNullOrWhiteSpace($Environment)) {
        $facts += @{ title = 'Environment'; value = $Environment }
    }

    $facts += @{ title = 'Started by'; value = $Actor }

    return $facts
}

function Build-AdaptiveCardBody {
    <#
    .SYNOPSIS
        Constructs the Adaptive Card body array.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [hashtable]$Styling,

        [Parameter(Mandatory)]
        [array]$Facts,

        [Parameter()]
        [array]$CommitFacts,

        [Parameter(Mandatory)]
        [string]$RunUrl
    )

    # Emoji via code points
    $noteEmoji = [System.Char]::ConvertFromUtf32(0x1F4DD) # 📝
    $viewEmoji = [System.Char]::ConvertFromUtf32(0x1F50E) # 🔎

    $body = @(
        @{ type = 'TextBlock'; size = 'Large'; weight = 'Bolder'; text = $Title; wrap = $true }
        @{
            type  = 'Container'
            style = $Styling.Style
            items = @(
                @{ type = 'TextBlock'; text = "$($Styling.Emoji) Status: $Status"; weight = 'Bolder'; wrap = $true }
            )
        }
        @{ type = 'FactSet'; facts = $Facts }
    )

    if ($CommitFacts -and $CommitFacts.Count -gt 0) {
        $commitItems = foreach ($c in $CommitFacts) {
            @{
                type = 'TextBlock'
                text = "- $($c.title): $($c.value)"
                wrap = $true
            }
        }

        $commitCount = @($CommitFacts).Count

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

        $commitContainer = @{
            type      = 'Container'
            id        = 'commitsSection'
            isVisible = $false
            items     = @(
                @{ type = 'TextBlock'; weight = 'Bolder'; text = 'Recent commits:'; wrap = $true; separator = $true }
                @{ type = 'Container'; items = @($commitItems); spacing = 'Small' }
            )
        }

        $body += @($toggleAction, $commitContainer)
    }

    $body += @{
        type    = 'ActionSet'
        actions = @(
            @{ type = 'Action.OpenUrl'; title = "$viewEmoji View Run"; url = $RunUrl }
        )
    }

    return $body
}

function New-TeamsPayload {
    <#
    .SYNOPSIS
        Creates the full Teams message payload with Adaptive Card attachment.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Function only constructs a data structure, no system state is changed')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$CardBody
    )

    @{
        type        = 'message'
        attachments = @(
            @{
                contentType = 'application/vnd.microsoft.card.adaptive'
                contentUrl  = $null
                content     = @{
                    '$schema'    = 'http://adaptivecards.io/schemas/adaptive-card.json'
                    type         = 'AdaptiveCard'
                    version      = '1.5'
                    body         = $CardBody
                    selectAction = $null
                }
            }
        )
    }
}

function Send-TeamsNotification {
    <#
    .SYNOPSIS
        Sends an Adaptive Card notification to Microsoft Teams.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$WebhookUrl,

        [Parameter(Mandatory)]
        [string]$JobStatus,

        [Parameter(Mandatory)]
        [string]$Repository,

        [Parameter(Mandatory)]
        [string]$Actor,

        [Parameter()]
        [string]$Environment,

        [Parameter()]
        [string]$CardTitle = '🔔 GitHub Deployment',

        [Parameter()]
        [string]$CommitMessages,

        [Parameter()]
        [string]$RunId
    )

    if ([string]::IsNullOrWhiteSpace($WebhookUrl)) {
        throw "No webhook_url provided."
    }

    $styling = Get-StatusStyling -Status $JobStatus
    $facts = Build-FactsArray -Repository $Repository -Actor $Actor -Environment $Environment
    $commitFacts = ConvertTo-CommitFact -CommitJson $CommitMessages
    $runUrl = "https://github.com/$Repository/actions/runs/$RunId"

    $cardBody = Build-AdaptiveCardBody `
        -Title $CardTitle `
        -Status $JobStatus `
        -Styling $styling `
        -Facts $facts `
        -CommitFacts $commitFacts `
        -RunUrl $runUrl

    $payload = New-TeamsPayload -CardBody $cardBody
    $json = $payload | ConvertTo-Json -Depth 30

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $bodyBytes = $utf8NoBom.GetBytes($json)

    if ($PSCmdlet.ShouldProcess($WebhookUrl, 'Send Teams notification')) {
        Write-Host "Sending Teams notification..."
        $null = Invoke-RestMethod -Method Post -Uri $WebhookUrl -ContentType 'application/json; charset=utf-8' -Body $bodyBytes
        Write-Host "✅ Teams notification sent successfully."
    }

    return @{
        Sent         = -not $WhatIfPreference
        PayloadBytes = $bodyBytes.Length
        RunUrl       = $runUrl
    }
}

Export-ModuleMember -Function @(
    'Get-StatusStyling'
    'ConvertTo-CommitFact'
    'Build-FactsArray'
    'Build-AdaptiveCardBody'
    'New-TeamsPayload'
    'Send-TeamsNotification'
)
