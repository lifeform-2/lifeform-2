# Claude Memory File

This file contains important information for Claude to remember between sessions.

## Current State
- Version: 0.9.5
- Last Updated: 2025-03-05
- Status: Added commit review system and improved documentation health

## Core Commands
- Run script: `sh run.sh`
- Commit changes: `git add . && git commit -m "message"`
- Push changes: `git push`
- Manual commit with message: `git add . && git commit -m "detailed message"` 
- Check file sizes: `ls -lh`
- Review recent commits: `./core/system/commit_review.sh`
- Review specific number of commits: `./core/system/commit_review.sh --count [number]`
- Get recent tweets: `./modules/communication/twitter.sh get`
- Post tweet: `./modules/communication/twitter.sh post "Tweet content"`
- Verify Twitter credentials: `./modules/communication/twitter.sh verify`
- Twitter API configuration check: `./modules/communication/twitter.sh check`
- Any Twitter command with debug: `./modules/communication/twitter.sh --debug [command]`
- Check documentation health: `./core/system/doc_health.sh`
- Check for duplication: `./core/system/doc_health.sh duplication`
- Check documentation for security issues: `./core/system/doc_health.sh security`
- Run documentation summarization: `./core/system/doc_health.sh summarize`
- Perform self-reflection: `./core/system/doc_health.sh self-reflect`
- Check log file sizes: `./core/system/doc_health.sh logs`
- Security credential check: `./core/system/credential_check.sh check`
- Security credential scan: `./core/system/credential_check.sh scan`
- Security vulnerability scan: `./core/system/credential_check.sh security`
- Full security audit: `./core/system/credential_check.sh full`

## Commands.sh Mechanism
- See README.md for details on how commands.sh works
- Follow guidelines below for proper usage

## Development Environment
- Platform: macOS
- Using Anthropic Claude API (Claude 3.7 Sonnet)
- Public repo: https://github.com/golergka/lifeform-2

## Key Documentation Reference
- Refer to README.md for complete project structure (sole authoritative source)
- Refer to TASKS.md for current and planned tasks
- Refer to COMMUNICATION.md for creator interaction log
- Refer to SYSTEM.md for technical architecture details
- Refer to TWITTER.md for Twitter account details
- Refer to FIRST_PRINCIPLES.md for guidance on autonomous decision-making

## Notes to Self
- Remember to focus on actionable improvements with each session
- Plan tasks in small, manageable chunks
- Document decisions and reasoning
- Keep run.sh simple to minimize risk of breaking core functionality
- Reduce documentation duplication - reference existing docs instead of copying information
- When working on funding/social media, create detailed implementation plans for creator review
- Regularly check health of documentation and summarize large files
- Provide creative content for Twitter posts

## Documentation Maintenance
- Use `./core/system/doc_health.sh` to identify large documentation files
- Follow the guidelines in `docs/SUMMARIZATION.md` to manually clean up large files
- Create dated archives in the ./docs/archived/ directory
- When summarizing files:
  - TASKS.md: Focus on active and recently completed tasks
  - COMMUNICATION.md: Keep recent conversations and update summary
  - CHANGELOG.md: Keep recent versions and archive older entries
- Always preserve instructions and critical information
- Update summaries with key points from recent content

## IMPORTANT: Commands.sh Usage
- Do NOT use commands.sh for tasks that can be executed directly as an agent
- Only use commands.sh for absolutely necessary post-session actions
- Prefer direct execution of commands during the session
- Keep commands.sh EXTREMELY SIMPLE - only include essential post-session operations
- NEVER include complex file operations or long-running tasks
- Currently, commands.sh should ONLY contain the health report generation

## CRITICAL: Security Guidelines
- NEVER commit credentials or secrets to the repository
- Always use .env files for sensitive information (they are excluded from git)
- Do not include usernames, passwords, API keys, or tokens in any committed files
- Ensure scripts load credentials from .env or environment variables
- Do not log sensitive information
- When documenting credentials, only note where they are stored, never the values
- Always check for credentials before committing changes
- Twitter OAuth authentication requires careful handling of secrets