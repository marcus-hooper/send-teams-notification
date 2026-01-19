## Summary

<!-- Brief description of what this PR does -->

## Related Issues

<!-- Link to related issues: Fixes #123, Relates to #456 -->

## Changes

<!-- List the key changes made -->

-
-
-

## Type of Change

<!-- Check all that apply -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Security fix
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] CI/CD changes
- [ ] Dependency update

### Breaking Change Details

<!-- If breaking change, describe migration steps for users -->

## Testing

<!-- Describe how this was tested -->

- [ ] Unit tests added/updated
- [ ] All tests pass (`Invoke-Pester ./tests`)
- [ ] Manual testing performed (sent test notification to Teams)

## Security Considerations

<!-- Check N/A if this PR doesn't touch webhook handling, card content, or external dependencies.
     Otherwise, check all applicable items below. -->

- [ ] N/A - No security-relevant changes (skip items below)

If security-relevant changes are made:

- [ ] Webhook URL is not exposed in logs or output
- [ ] No credentials or secrets are included in card content
- [ ] User input is sanitized before rendering in cards
- [ ] Supply chain security reviewed (dependencies pinned to SHAs)

## Checklist

- [ ] My code follows the project's coding standards
- [ ] I have run `Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery`
- [ ] I have run `Invoke-Pester ./tests` and all tests pass
- [ ] I have updated CHANGELOG.md under `[Unreleased]`
- [ ] I have updated README.md if inputs/outputs changed
- [ ] I have checked for breaking changes and documented them
- [ ] Commit messages use conventional prefixes (`fix:`, `feat:`, `docs:`, `security:`, etc.)
- [ ] Any new GitHub Actions dependencies are pinned to full commit SHAs

### If Adding/Modifying PowerShell Functions

- [ ] New functions are added to `Export-ModuleMember` in the module
- [ ] Script files are saved with UTF-8 encoding (no BOM)
- [ ] Tested on both Windows and Linux (or noted platform-specific behavior)

## Screenshots / Output

<!-- If applicable, add screenshots of the Teams notification card -->
