# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

### How to Report

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Use [GitHub's private vulnerability reporting](https://github.com/marcus-hooper/send-teams-notification/security/advisories/new) to submit a report
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Disclosure Timeline

- Acknowledgment of your report within 48 hours
- Initial assessment within 7 days
- Target resolution within 90 days for critical vulnerabilities
- Regular updates on the progress of addressing the vulnerability
- Credit in the security advisory (unless you prefer to remain anonymous)

### Scope

The following are considered security vulnerabilities:

- Injection vulnerabilities in PowerShell scripts
- Unsafe handling of webhook URLs or other secrets
- JSON parsing vulnerabilities in commit message handling
- Issues that could expose sensitive data in logs or error messages
- Issues that could compromise the CI/CD pipeline

Out of scope:

- Vulnerabilities in upstream dependencies (report to the respective project)
- Vulnerabilities in Microsoft Teams or the Incoming Webhooks platform (report to Microsoft)
- Issues requiring physical access or social engineering

### Security Notifications

Security fixes are announced via:

- [GitHub Security Advisories](https://github.com/marcus-hooper/send-teams-notification/security/advisories)
- Release notes for patched versions

Dependencies are monitored automatically via Dependabot.

## Security Considerations

This action handles sensitive data and performs external HTTP requests:

1. **Webhook URLs** - Teams Incoming Webhook URLs are secrets that grant posting access to channels
2. **HTTP requests** - Sends POST requests to Microsoft Teams webhook endpoints
3. **Input parsing** - Processes JSON input for commit messages

### Best Practices for Users

1. **Store webhook URLs in GitHub Secrets** - Never hardcode webhook URLs in workflow files
2. **Use environment-level secrets** - Scope secrets to specific environments when possible
3. **Pin to a specific version** - Use a tagged release (e.g., `@v1`) rather than `@main`
4. **Review workflow permissions** - Grant only necessary permissions to your workflow
5. **Rotate webhook URLs** - If a webhook URL is exposed, delete and recreate the connector in Teams
6. **Limit channel access** - Create webhooks only for channels that need notifications
7. **Use ephemeral runners** - Consider using ephemeral or isolated runners for sensitive pipelines

### Data Handling

This action:

- Does **not** log or expose webhook URLs
- Does **not** store any data beyond the workflow execution
- Does **not** send data to any service other than the specified Teams webhook
- Processes commit messages provided by the workflow (ensure you trust the source)
