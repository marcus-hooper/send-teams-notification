BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\scripts\Send-TeamsNotification.psm1'
    Import-Module $modulePath -Force
}

Describe 'Get-StatusStyling' {
    It 'returns green/good styling for success' {
        $result = Get-StatusStyling -Status 'success'

        $result.AccentColor | Should -Be '#107C10'
        $result.Style | Should -Be 'good'
        $result.Emoji | Should -Be '✅'
    }

    It 'returns red/attention styling for failure' {
        $result = Get-StatusStyling -Status 'failure'

        $result.AccentColor | Should -Be '#D13438'
        $result.Style | Should -Be 'attention'
        $result.Emoji | Should -Be '❌'
    }

    It 'returns yellow/warning styling for cancelled' {
        $result = Get-StatusStyling -Status 'cancelled'

        $result.AccentColor | Should -Be '#F2C744'
        $result.Style | Should -Be 'warning'
        $result.Emoji | Should -Be '⚠️'
    }

    It 'returns warning styling for unknown status' {
        $result = Get-StatusStyling -Status 'unknown'

        $result.AccentColor | Should -Be '#F2C744'
        $result.Style | Should -Be 'warning'
        $result.Emoji | Should -Be '⚠️'
    }

    It 'is case-insensitive' {
        $result = Get-StatusStyling -Status 'SUCCESS'

        $result.Style | Should -Be 'good'
    }
}

Describe 'ConvertTo-CommitFacts' {
    It 'returns null for null input' {
        $result = ConvertTo-CommitFacts -CommitJson $null

        $result | Should -BeNullOrEmpty
    }

    It 'returns null for empty string' {
        $result = ConvertTo-CommitFacts -CommitJson ''

        $result | Should -BeNullOrEmpty
    }

    It 'returns null for empty array string' {
        $result = ConvertTo-CommitFacts -CommitJson '[]'

        $result | Should -BeNullOrEmpty
    }

    It 'returns null for whitespace' {
        $result = ConvertTo-CommitFacts -CommitJson '   '

        $result | Should -BeNullOrEmpty
    }

    It 'parses valid JSON array' {
        $json = '[{"title":"abc123","value":"Fix bug"}]'
        $result = ConvertTo-CommitFacts -CommitJson $json

        @($result).Count | Should -Be 1
        $result[0].title | Should -Be 'abc123'
        $result[0].value | Should -Be 'Fix bug'
    }

    It 'parses multiple commits' {
        $json = '[{"title":"abc123","value":"First"},{"title":"def456","value":"Second"}]'
        $result = ConvertTo-CommitFacts -CommitJson $json

        @($result).Count | Should -Be 2
    }

    It 'handles double-encoded JSON' {
        $inner = '[{"title":"abc123","value":"Fix bug"}]'
        $doubleEncoded = $inner | ConvertTo-Json
        $result = ConvertTo-CommitFacts -CommitJson $doubleEncoded

        @($result).Count | Should -Be 1
        $result[0].title | Should -Be 'abc123'
    }

    It 'returns null for invalid JSON' {
        $result = ConvertTo-CommitFacts -CommitJson 'not valid json' -WarningAction SilentlyContinue

        $result | Should -BeNullOrEmpty
    }
}

Describe 'Build-FactsArray' {
    It 'includes repository with GitHub link' {
        $result = Build-FactsArray -Repository 'owner/repo' -Actor 'testuser'

        $result[0].title | Should -Be 'Repository'
        $result[0].value | Should -Match 'owner/repo'
        $result[0].value | Should -Match 'github.com'
    }

    It 'includes actor' {
        $result = Build-FactsArray -Repository 'owner/repo' -Actor 'testuser'

        $actorFact = $result | Where-Object { $_.title -eq 'Started by' }
        $actorFact.value | Should -Be 'testuser'
    }

    It 'excludes environment when not provided' {
        $result = Build-FactsArray -Repository 'owner/repo' -Actor 'testuser'

        $envFact = $result | Where-Object { $_.title -eq 'Environment' }
        $envFact | Should -BeNullOrEmpty
    }

    It 'includes environment when provided' {
        $result = Build-FactsArray -Repository 'owner/repo' -Actor 'testuser' -Environment 'production'

        $envFact = $result | Where-Object { $_.title -eq 'Environment' }
        $envFact.value | Should -Be 'production'
    }

    It 'orders facts correctly: Repository, Environment, Actor' {
        $result = Build-FactsArray -Repository 'owner/repo' -Actor 'testuser' -Environment 'staging'

        $result[0].title | Should -Be 'Repository'
        $result[1].title | Should -Be 'Environment'
        $result[2].title | Should -Be 'Started by'
    }
}

Describe 'Build-AdaptiveCardBody' {
    BeforeAll {
        $script:defaultParams = @{
            Title   = 'Test Title'
            Status  = 'success'
            Styling = @{ Style = 'good'; Emoji = '✅'; AccentColor = '#107C10' }
            Facts   = @(@{ title = 'Repo'; value = 'test' })
            RunUrl  = 'https://github.com/owner/repo/actions/runs/123'
        }
    }

    It 'includes title as first element' {
        $result = Build-AdaptiveCardBody @script:defaultParams

        $result[0].type | Should -Be 'TextBlock'
        $result[0].text | Should -Be 'Test Title'
        $result[0].size | Should -Be 'Large'
    }

    It 'includes status container with correct style' {
        $result = Build-AdaptiveCardBody @script:defaultParams

        $statusContainer = $result | Where-Object { $_.type -eq 'Container' -and $_.style }
        $statusContainer.style | Should -Be 'good'
    }

    It 'includes status text with emoji' {
        $result = Build-AdaptiveCardBody @script:defaultParams

        $statusContainer = $result | Where-Object { $_.type -eq 'Container' -and $_.style }
        $statusContainer.items[0].text | Should -Match '✅'
        $statusContainer.items[0].text | Should -Match 'success'
    }

    It 'includes FactSet' {
        $result = Build-AdaptiveCardBody @script:defaultParams

        $factSet = $result | Where-Object { $_.type -eq 'FactSet' }
        $factSet | Should -Not -BeNullOrEmpty
    }

    It 'includes View Run action' {
        $result = Build-AdaptiveCardBody @script:defaultParams

        $actionSet = $result | Where-Object { $_.type -eq 'ActionSet' -and $_.actions[0].type -eq 'Action.OpenUrl' }
        $actionSet | Should -Not -BeNullOrEmpty
        $actionSet.actions[0].url | Should -Be 'https://github.com/owner/repo/actions/runs/123'
    }

    It 'excludes commits section when no commits provided' {
        $result = Build-AdaptiveCardBody @script:defaultParams

        $toggleAction = $result | Where-Object { $_.actions.type -contains 'Action.ToggleVisibility' }
        $toggleAction | Should -BeNullOrEmpty
    }

    It 'includes commits section when commits provided' {
        $params = @{
            Title       = 'Test Title'
            Status      = 'success'
            Styling     = @{ Style = 'good'; Emoji = '✅'; AccentColor = '#107C10' }
            Facts       = @(@{ title = 'Repo'; value = 'test' })
            RunUrl      = 'https://github.com/owner/repo/actions/runs/123'
            CommitFacts = @(@{ title = 'abc123'; value = 'Fix bug' })
        }

        $result = Build-AdaptiveCardBody @params

        $toggleAction = $result | Where-Object { $_.actions.type -contains 'Action.ToggleVisibility' }
        $toggleAction | Should -Not -BeNullOrEmpty
    }

    It 'shows correct commit count in toggle button' {
        $params = @{
            Title       = 'Test Title'
            Status      = 'success'
            Styling     = @{ Style = 'good'; Emoji = '✅'; AccentColor = '#107C10' }
            Facts       = @(@{ title = 'Repo'; value = 'test' })
            RunUrl      = 'https://github.com/owner/repo/actions/runs/123'
            CommitFacts = @(
                @{ title = 'abc123'; value = 'First' }
                @{ title = 'def456'; value = 'Second' }
            )
        }

        $result = Build-AdaptiveCardBody @params

        $toggleAction = $result | Where-Object { $_.actions.type -contains 'Action.ToggleVisibility' }
        $toggleAction.actions[0].title | Should -Match '2'
    }

    It 'creates hidden commits container' {
        $params = @{
            Title       = 'Test Title'
            Status      = 'success'
            Styling     = @{ Style = 'good'; Emoji = '✅'; AccentColor = '#107C10' }
            Facts       = @(@{ title = 'Repo'; value = 'test' })
            RunUrl      = 'https://github.com/owner/repo/actions/runs/123'
            CommitFacts = @(@{ title = 'abc123'; value = 'Fix bug' })
        }

        $result = Build-AdaptiveCardBody @params

        $commitsContainer = $result | Where-Object { $_.id -eq 'commitsSection' }
        $commitsContainer | Should -Not -BeNullOrEmpty
        $commitsContainer.isVisible | Should -Be $false
    }
}

Describe 'New-TeamsPayload' {
    It 'creates message type payload' {
        $cardBody = @(@{ type = 'TextBlock'; text = 'Test' })
        $result = New-TeamsPayload -CardBody $cardBody

        $result.type | Should -Be 'message'
    }

    It 'includes adaptive card attachment' {
        $cardBody = @(@{ type = 'TextBlock'; text = 'Test' })
        $result = New-TeamsPayload -CardBody $cardBody

        @($result.attachments).Count | Should -Be 1
        $result.attachments[0].contentType | Should -Be 'application/vnd.microsoft.card.adaptive'
    }

    It 'sets correct schema and version' {
        $cardBody = @(@{ type = 'TextBlock'; text = 'Test' })
        $result = New-TeamsPayload -CardBody $cardBody

        $result.attachments[0].content.'$schema' | Should -Be 'http://adaptivecards.io/schemas/adaptive-card.json'
        $result.attachments[0].content.type | Should -Be 'AdaptiveCard'
        $result.attachments[0].content.version | Should -Be '1.5'
    }

    It 'includes card body in content' {
        $cardBody = @(@{ type = 'TextBlock'; text = 'Test Message' })
        $result = New-TeamsPayload -CardBody $cardBody

        $result.attachments[0].content.body | Should -Be $cardBody
    }

    It 'produces valid JSON' {
        $cardBody = @(@{ type = 'TextBlock'; text = 'Test' })
        $result = New-TeamsPayload -CardBody $cardBody

        { $result | ConvertTo-Json -Depth 30 } | Should -Not -Throw
    }
}

Describe 'Send-TeamsNotification validation' {
    It 'throws when webhook URL is empty' {
        { Send-TeamsNotification -WebhookUrl '' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -ErrorAction Stop } |
            Should -Throw '*webhook*'
    }

    It 'throws when webhook URL is whitespace' {
        { Send-TeamsNotification -WebhookUrl '   ' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -ErrorAction Stop } |
            Should -Throw '*webhook*'
    }
}

Describe 'Send-TeamsNotification error handling' {
    It 'propagates HTTP errors from Invoke-RestMethod' {
        Mock Invoke-RestMethod { throw 'HTTP 400 Bad Request' } -ModuleName Send-TeamsNotification

        { Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -RunId '123' -ErrorAction Stop } |
            Should -Throw '*400*'
    }

    It 'propagates network errors from Invoke-RestMethod' {
        Mock Invoke-RestMethod { throw 'The remote name could not be resolved' } -ModuleName Send-TeamsNotification

        { Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -RunId '123' -ErrorAction Stop } |
            Should -Throw '*remote name*'
    }
}

Describe 'Send-TeamsNotification with mock' {
    BeforeAll {
        Mock Invoke-RestMethod { return $null } -ModuleName Send-TeamsNotification
    }

    It 'calls Invoke-RestMethod with POST method' {
        Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -RunId '123'

        Should -Invoke Invoke-RestMethod -ModuleName Send-TeamsNotification -ParameterFilter {
            $Method -eq 'Post'
        }
    }

    It 'sends with UTF-8 content type' {
        Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -RunId '123'

        Should -Invoke Invoke-RestMethod -ModuleName Send-TeamsNotification -ParameterFilter {
            $ContentType -eq 'application/json; charset=utf-8'
        }
    }

    It 'returns result with Sent=true' {
        $result = Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -RunId '123'

        $result.Sent | Should -Be $true
    }

    It 'returns result with PayloadBytes' {
        $result = Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -RunId '123'

        $result.PayloadBytes | Should -BeGreaterThan 0
    }

    It 'returns result with RunUrl' {
        $result = Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -RunId '456'

        $result.RunUrl | Should -Be 'https://github.com/owner/repo/actions/runs/456'
    }

    It 'handles missing RunId gracefully' {
        $result = Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user'

        $result.Sent | Should -Be $true
        $result.RunUrl | Should -Be 'https://github.com/owner/repo/actions/runs/'
    }

    It 'uses default CardTitle when not specified' {
        $script:capturedBody = $null
        Mock Invoke-RestMethod {
            $script:capturedBody = $Body
            return $null
        } -ModuleName Send-TeamsNotification

        Send-TeamsNotification -WebhookUrl 'https://test.url' -JobStatus 'success' -Repository 'owner/repo' -Actor 'user' -RunId '123'

        $json = [System.Text.Encoding]::UTF8.GetString($script:capturedBody)
        $json | Should -Match '🔔 GitHub Deployment'
    }
}

Describe 'Integration: Full Card Generation' {
    BeforeEach {
        $script:capturedBody = $null
        Mock Invoke-RestMethod {
            $script:capturedBody = $Body
            return $null
        } -ModuleName Send-TeamsNotification
    }

    It 'generates valid JSON payload for success notification' {
        Send-TeamsNotification `
            -WebhookUrl 'https://test.url' `
            -JobStatus 'success' `
            -Repository 'myorg/myrepo' `
            -Actor 'developer' `
            -Environment 'staging' `
            -CardTitle 'Deployment Complete' `
            -RunId '12345'

        $json = [System.Text.Encoding]::UTF8.GetString($script:capturedBody)
        $payload = $json | ConvertFrom-Json

        $payload.type | Should -Be 'message'
        $payload.attachments[0].content.type | Should -Be 'AdaptiveCard'
    }

    It 'generates valid JSON payload with commits' {
        $commits = '[{"title":"abc1234","value":"[Fix login bug](https://github.com/org/repo/commit/abc1234)"}]'

        Send-TeamsNotification `
            -WebhookUrl 'https://test.url' `
            -JobStatus 'failure' `
            -Repository 'myorg/myrepo' `
            -Actor 'developer' `
            -CommitMessages $commits `
            -RunId '12345'

        $json = [System.Text.Encoding]::UTF8.GetString($script:capturedBody)

        $json | Should -Match 'commitsSection'
        $json | Should -Match 'abc1234'
    }
}
