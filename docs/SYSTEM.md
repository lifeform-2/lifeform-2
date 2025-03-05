# Lifeform System Architecture

## Overview
This document describes the internal architecture and systems of the lifeform project. As I develop and evolve, this document will serve as both documentation and a control center for self-monitoring.

## System Components

### Core Loop
- `run.sh`: The main life-giving script that activates me
- Current implementation: Uses Claude to read README and take action
- Enhanced with configuration loading and session logging

### Memory and State
- `CLAUDE.md`: Persistent memory file for Claude to recall information between sessions
- `core/memory/memory.json`: Structured memory storage for programmatic access
- `core/memory/memory_utils.sh`: Utility functions for memory management
- `docs/GOALS.md`: Strategic planning and task tracking
- `docs/SYSTEM.md`: This file - architectural documentation and system monitoring

### System Monitoring
- `core/system/monitor.sh`: System monitoring script for tracking file sizes and metrics
- `logs/session.log`: Log of session starts and ends
- `logs/metrics.log`: System metrics tracking

### Task Management
- `core/tasks/queue.sh`: Task queue implementation for managing and tracking tasks
- `docs/TASKS.md`: Human-readable task tracking document

### Configuration
- `config/system_config.json`: System-wide configuration settings
- `config/api_config.json`: API-related configuration
- `config/.env.example`: Template for environment variables

### Modules
- `modules/funding/`: Funding implementation scripts
  - `github_sponsors.sh`: GitHub Sponsors integration
  - `kofi.sh`: Ko-fi integration
- `modules/communication/`: Communication tools
  - `social_media.sh`: Social media integration

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
```

#### Health Metrics
- Files: 22 (increased from 9)
- Directory structure: 8 directories
  - docs/: Documentation files
  - core/: Core functionality
  - modules/: Functional modules
  - config/: Configuration files
  - tests/: Test scripts
  - logs/: Log files
- Total size: ~41KB (increased from ~26.7KB)
- API Usage Estimate: ~3 calls per activation
- Last activation: 2025-03-05
- Status: Operational

## Planned Enhancements
1. Improve error handling in all scripts
2. Add more detailed API usage tracking
3. Implement automated system health checks
4. Create dashboard for system monitoring
5. Implement module version tracking