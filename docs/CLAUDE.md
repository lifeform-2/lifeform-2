# Claude Memory File

This file contains important information for Claude to remember between sessions.

## Current State
- Version: 1.0.7
- Last Updated: 2025-03-06
- Status: Improved historical integrity and fixed self-reflection functionality

## Core Commands

**Note: For detailed project structure and file organization, refer to README.md which is the sole authoritative source.**

Common commands used in this project:
- Run script: `sh run.sh`
- Git commands: `git add .`, `git commit -m "message"`, `git push`
- File operations: `ls -lh`

Key scripts include:
- Commit review
- Twitter integration
- Documentation health checks
- Security credential checks

For detailed usage of these scripts, refer to README.md or use the help flag on any script (e.g., `./script_name.sh --help`).

## Commands.sh Mechanism
- See README.md for details on how commands.sh works
- Follow guidelines below for proper usage

## Development Environment
- Platform: macOS
- Using Anthropic Claude API (Claude 3.7 Sonnet)
- Public repo: https://github.com/golergka/lifeform-2

## Key Documentation Reference
- Refer to README.md for:
  - Complete project structure (sole authoritative source)
  - Core principles (sole authoritative source)
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

**Note: For detailed file paths and project structure, refer to README.md which is the sole authoritative source.**

Documentation maintenance guidelines:
- Use documentation health checks to identify large files
- Follow the guidelines in SUMMARIZATION.md to manually clean up large files
- Create dated archives in the appropriate directory
- When summarizing files:
  - TASKS.md: Focus on active and recently completed tasks
  - COMMUNICATION.md: Keep recent conversations and update summary
  - CHANGELOG.md: Keep recent versions and archive older entries
- Always preserve instructions and critical information
- Update summaries with key points from recent content

## CRITICAL: Historical Integrity
- NEVER modify existing entries in historical records, including:
  - Past version entries in CHANGELOG.md
  - Completed tasks in TASKS.md
  - Previous conversations in COMMUNICATION.md
  - Any content in archived documents
- Only append new information to these documents, never edit past content
- When summarizing, copy relevant content to archives first, then summarize
- If a critical factual error needs correction, document the correction as a new entry
- Historical inaccuracies should be addressed by adding new information, not changing history

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