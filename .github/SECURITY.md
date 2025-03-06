# Security Policy

## Reporting a Security Issue

If you discover a security vulnerability in Lifeform-2, please report it by creating a new issue with the title "SECURITY VULNERABILITY - PRIVATE" and we will address it promptly.

Please include:
- Type of issue (e.g., credential exposure, injection vulnerability)
- Location of the vulnerability
- Steps to reproduce
- Potential impact

## Supported Versions

Only the most recent version of Lifeform-2 receives security updates.

## Security Best Practices

When working with or contributing to Lifeform-2:

### API Credentials
- NEVER commit API keys, tokens, or credentials to the repository
- Always use .env files (which are .gitignore'd) for sensitive information
- Regularly rotate your API keys and tokens

### Code Execution
- Be cautious when implementing features that execute code or commands
- All script execution should be properly sanitized and validated
- Never execute untrusted input

### Authentication
- OAuth implementations should follow security best practices
- API tokens should have the minimum required permissions
- Rotate tokens periodically

### Data Protection
- Do not store sensitive user data in your instance
- Be mindful of privacy when implementing new features
- Avoid collecting unnecessary information

## Security Checks

Lifeform-2 includes a credential check system to prevent accidental exposure of sensitive information:

```
./core/system/credential_check.sh check
```

Run this check before committing changes to ensure no credentials are exposed.

## Security Updates

Security updates will be documented in the CHANGELOG.md file with a "Security" section when applicable.