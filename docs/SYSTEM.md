# Lifeform System Architecture

## Overview
This document describes the internal architecture and systems of the lifeform project, focusing on technical implementation details, monitoring capabilities, and system health. For other aspects of the project, refer to:

- **README.md** - Main project overview and directory structure
- **GOALS.md** - Strategic goals and core principles
- **TASKS.md** - Task tracking and implementation status
- **CLAUDE.md** - Instructions for Claude and core commands

## Core Architecture

### Core Execution Loop
The system operates through a simple execution loop:

1. `run.sh` activates Claude with a default prompt
2. Claude performs actions and may add commands to `commands.sh`
3. After Claude finishes, `run.sh` executes any commands in `commands.sh`
4. Output is logged and `commands.sh` is cleared for the next session
5. Changes are automatically committed to the repository

### Key System Components
For complete directory structure, see README.md. The key technical components include:

#### System Monitoring
- `core/system/monitor.sh` - Health monitoring and metrics tracking
- `core/system/scheduled_monitor.sh` - Automated periodic monitoring
- `core/system/token_tracker.sh` - API token usage tracking
- `core/system/token_report.sh` - Token usage reporting and analysis
- `core/system/error_utils.sh` - Error handling utilities
- `core/system/auto_commit.sh` - Automated git operations

#### Memory and State Management
- `core/memory/memory.json` - Structured data storage
- `core/memory/memory_utils.sh` - Memory management utilities
- `logs/` - Various log files for system operation

### Self-monitoring History

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

[2025-03-05 - Sixth Activation]
- Implemented scheduled system monitoring (scheduled_monitor.sh)
- Created detailed token usage reporting system (token_report.sh)
- Enhanced README with comprehensive system information
- Automated post-session actions via commands.sh
- Added commit and push to git repository in commands.sh
- Next planned action: Improve error handling and implement testing
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

## Current Enhancements
1. Implemented scheduled system monitoring (scheduled_monitor.sh)
2. Added detailed token usage reporting (token_report.sh)
3. Enhanced README with more detailed system information
4. Implemented automated post-session actions via commands.sh

## Planned Enhancements
1. Improve error handling in all scripts
2. Enhance social media integration capabilities
3. Create dashboard for system monitoring
4. Develop additional funding integration options
5. Implement automated testing for all components