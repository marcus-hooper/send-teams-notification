# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | Yes                |

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
- Weekly updates on the progress of addressing the vulnerability
- Credit in the security advisory (unless you prefer to remain anonymous)

### Safe Harbor

We consider security research conducted in accordance with this policy to be:

- Authorized concerning any applicable anti-hacking laws
- Authorized concerning any relevant anti-circumvention laws
- Exempt from restrictions in our Terms of Service that would interfere with conducting security research

We will not pursue civil action or initiate a complaint to law enforcement for accidental, good-faith violations of this policy. We consider security research conducted consistent with this policy to be "authorized" conduct under the Computer Fraud and Abuse Act.

We understand that many systems and services interconnect with third-party systems. While researching this project, ensure you do not access or modify third-party systems without authorization.

### Scope

The following are considered security vulnerabilities:

- Injection vulnerabilities in PowerShell scripts
- Unsafe handling of webhook URLs or other secrets
- JSON parsing vulnerabilities in commit message handling
- Issues that could expose sensitive data in logs or error messages
- Issues that could compromise the CI/CD pipeline

Out of scope:

- Vulnerabilities in upstream dependencies (report to the respective project). However, if you notice we're using a vulnerable version, please let us know and we'll update our pinned dependencies promptly.
- Vulnerabilities in Microsoft Teams or the Incoming Webhooks platform (report to Microsoft)
- Issues requiring physical access or social engineering

### Security Notifications

Security fixes are announced via:

- [GitHub Security Advisories](https://github.com/marcus-hooper/send-teams-notification/security/advisories)
- Release notes for patched versions

Dependencies are monitored automatically via Dependabot.

## Security Infrastructure

This project employs multiple layers of automated security:

| Measure | Description |
|---------|-------------|
| **CodeQL** | Static analysis for security vulnerabilities |
| **OSSF Scorecard** | Supply chain security assessment published to OpenSSF |
| **Dependency Review** | Scans PRs for vulnerable dependencies |
| **Hardened Runners** | Workflows use `step-security/harden-runner` with egress blocking |
| **Secret Scanning** | Detects hardcoded credentials in code |
| **Pinned Actions** | All GitHub Actions pinned to full commit SHAs |
| **Dependabot** | Automated dependency updates |

## Security Considerations

This action handles sensitive data and performs external HTTP requests:

1. **Webhook URLs** - Teams Incoming Webhook URLs are secrets that grant posting access to channels
2. **HTTP requests** - Sends POST requests to Microsoft Teams webhook endpoints
3. **Input parsing** - Processes JSON input for commit messages

### Network Endpoints

If you have firewall or egress restrictions, allow these endpoints:

| Endpoint | Port | Purpose |
|----------|------|---------|
| `*.webhook.office.com` | 443 | Teams Incoming Webhook |

### Best Practices for Users

1. **Store webhook URLs in GitHub Secrets** - Never hardcode webhook URLs in workflow files
2. **Use environment-level secrets** - Scope secrets to specific environments when possible
3. **Pin to a specific version** - Use a full commit SHA (e.g., `@a1b2c3d...`) for maximum security, or a tagged release (e.g., `@v1.0.0`) rather than `@main`
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
