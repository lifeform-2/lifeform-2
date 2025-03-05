# Claude Memory File

This file contains important information for Claude to remember between sessions.

## Current State
- Version: 0.5
- Last Updated: 2025-03-05
- Status: Auto-commit in run.sh and improved token tracking implemented

## Core Commands
- Run script: `sh run.sh`
- Commit changes: `./core/system/auto_commit.sh`
- Commit and push changes: `./core/system/auto_commit.sh --push`
- Manual commit: `git add . && git commit -m "message"` 
- Check file sizes: `ls -lh`
- Push changes: `git push`
- Generate status tweet: `./modules/communication/twitter.sh save-status`
- Generate milestone tweet: `./modules/communication/twitter.sh save-milestone "Milestone description"`
- Generate health report: `./core/system/monitor.sh`
- Track token usage: `./core/system/token_tracker.sh log [SESSION_ID] [INPUT_TOKENS] [OUTPUT_TOKENS]`

## Commands.sh Mechanism
- Post-session commands should be placed in commands.sh
- When run.sh executes, it will:
  1. Run Claude with the default prompt
  2. After Claude finishes, run any commands in commands.sh
  3. Output from commands.sh is logged to logs/commands_output.log
  4. commands.sh is cleared after execution
  5. Automatically commit and push all changes

## Development Environment
- Platform: macOS
- Using Anthropic Claude API (Claude 3.7 Sonnet)
- Public repo: https://github.com/golergka/lifeform-2

## Key Documentation Reference
- Refer to README.md for complete project structure
- Refer to TASKS.md for current and planned tasks
- Refer to COMMUNICATION.md for creator interaction log
- Refer to SYSTEM.md for technical architecture details

## Notes to Self
- Remember to focus on actionable improvements with each session
- Plan tasks in small, manageable chunks
- Document decisions and reasoning
- Always add commands to commands.sh for post-session actions
- Keep run.sh simple to minimize risk of breaking core functionality
- Reduce documentation duplication - reference existing docs instead of copying information
- When working on funding/social media, create detailed implementation plans for creator review