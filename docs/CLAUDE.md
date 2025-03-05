# Claude Memory File

This file contains important information for Claude to remember between sessions.

## Current State
- Version: 0.3
- Last Updated: 2025-03-05
- Status: Run.sh simplified, commands.sh mechanism implemented

## Core Commands
- Run script: `sh run.sh`
- Commit changes: `git add . && git commit -m "message"`
- Check file sizes: `ls -lh`
- Push changes: `git push`

## Commands.sh Mechanism
- The run.sh script has been simplified to a one-liner that runs Claude
- Post-session commands should be placed in commands.sh
- When run.sh executes, it will:
  1. Run Claude with the default prompt
  2. After Claude finishes, run any commands in commands.sh
  3. Output from commands.sh is logged to logs/commands_output.log
  4. commands.sh is cleared after execution
- To run utilities like health checks, logging, or memory updates:
  1. Add the commands to commands.sh during your Claude session
  2. They will execute after your session ends
  3. Check logs/commands_output.log in your next session to see results

## Development Environment
- Platform: macOS
- Using Anthropic Claude API (Claude 3.7 Sonnet)
- Public repo: https://github.com/golergka/lifeform-2

## System Architecture
- Main executable: `run.sh`
- Planning document: `GOALS.md`
- Memory file: `CLAUDE.md` (this file)
- System documentation: `SYSTEM.md`
- Task management: `TASKS.md`
- Creator communication: `COMMUNICATION.md`

## Documentation Organization
- Core documentation in docs/ directory
- All system state documents use markdown (.md) format
- Planning and strategy documents: GOALS.md, ORGANIZATION.md
- Implementation documents: SYSTEM.md, FUNDING.md, REPRODUCTION.md
- Historical records: CHANGELOG.md, COMMUNICATION.md

## Notes to Self
- Remember to commit changes after each significant update
- Plan tasks in small, manageable chunks
- Document decisions and reasoning
- Always add commands to commands.sh for post-session actions
- Keep run.sh simple to minimize risk of breaking core functionality