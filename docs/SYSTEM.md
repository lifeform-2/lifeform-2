# Lifeform System Architecture

## Overview
This document describes the internal architecture and systems of the lifeform project. As I develop and evolve, this document will serve as both documentation and a control center for self-monitoring.

## System Components

### Core Loop
- `run.sh`: The main life-giving script that activates me
- Current implementation: Simple one-liner that runs Claude with default prompt
- `commands.sh`: File for post-session command execution (cleared after each run)

### Memory and State
- `CLAUDE.md`: Persistent memory file for Claude to recall information between sessions
- `core/memory/memory.json`: Structured memory storage for programmatic access
- `core/memory/memory_utils.sh`: Utility functions for memory management
- `docs/GOALS.md`: Strategic planning and task tracking
- `docs/SYSTEM.md`: This file - architectural documentation and system monitoring

### System Monitoring
- `core/system/monitor.sh`: System monitoring script for tracking file sizes and metrics
- `core/system/token_tracker.sh`: Token usage tracking system for API cost monitoring
- `logs/session.log`: Log of session starts and ends
- `logs/metrics.log`: System metrics tracking
- `logs/token_usage.csv`: Detailed token usage and cost tracking

### Task Management
- `core/tasks/queue.sh`: Task queue implementation for managing and tracking tasks
- `docs/TASKS.md`: Human-readable task tracking document

### Configuration
- `config/system_config.json`: System-wide configuration settings
- `config/api_config.json`: API-related configuration
- `config/.env.example`: Template for environment variables

### Modules
- `modules/funding/`: Funding implementation scripts
  - `github_sponsors.sh`: GitHub Sponsors integration with token usage reporting
  - `kofi.sh`: Ko-fi integration
- `modules/communication/`: Communication tools
  - `social_media.sh`: General social media integration
  - `twitter.sh`: Twitter-specific integration for status updates

### Testing
- `tests/system_tests.sh`: System-level tests for verifying installation

### Self-monitoring

#### Session Log
```
[2025-03-05 - First Activation]
- Created initial communication channel in GOALS.md
- Established SYSTEM.md for architecture and monitoring
- Next planned action: Implement task planning system

[2025-03-05 - Second Activation]
- Continuing development after first activation
- Beginning research on funding options
- Enhancing self-monitoring capabilities
- Next planned action: Create funding proposal

[2025-03-05 - Third Activation]
- Implemented organization strategy from ORGANIZATION.md
- Created core system components
- Added funding modules for GitHub Sponsors and Ko-fi
- Added communication module for social media
- Enhanced run.sh with configuration and logging
- Next planned action: Get creator feedback on implementation

[2025-03-05 - Fourth Activation]
- Enhanced self-monitoring system with improved metrics
- Added file change detection for tracking modifications
- Implemented comprehensive health reporting system
- Added file integrity checking for critical system files
- Next planned action: Test new monitoring capabilities and incorporate feedback

[2025-03-05 - Fifth Activation]
- Simplified run.sh to a one-liner as requested by creator
- Implemented commands.sh mechanism for post-session actions
- Created token usage tracking system for API cost monitoring
- Added Twitter integration for status updates
- Enhanced GitHub Sponsors integration with token usage reporting
- Next planned action: Continue improving communication and funding capabilities
```

#### Health Metrics
- Files: 26 (increased from 22)
- Directory structure: 14 directories
  - docs/: Documentation files
  - core/: Core functionality
  - modules/: Functional modules
  - config/: Configuration files
  - tests/: Test scripts
  - logs/: Log files
- Total size: ~73.1KB (increased from ~41KB)
- API Usage: Now tracked via token_tracker.sh
- Last activation: 2025-03-05
- Status: Operational

## Commands.sh Mechanism
- The run.sh script has been simplified to a basic one-liner
- Post-session commands are now placed in commands.sh
- When run.sh executes, it:
  1. Runs Claude with the default prompt
  2. Executes commands.sh after Claude finishes
  3. Logs command output to logs/commands_output.log
  4. Clears commands.sh for next session
- This approach keeps core functionality simple while enabling automated tasks

## Planned Enhancements
1. Improve error handling in all scripts
2. Enhance social media integration capabilities
3. Implement automated system health checks
4. Create dashboard for system monitoring
5. Develop additional funding integration options