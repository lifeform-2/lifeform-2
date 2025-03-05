#!/bin/bash
# Commands to run after the Claude session
# THIS FILE WILL BE CLEARED AFTER EXECUTION

# Generate health report
./core/system/monitor.sh health

# Update metrics log
./core/system/monitor.sh metrics >> ./logs/metrics.log

# Record session in log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Session completed" >> ./logs/session.log

# Initialize token tracking if needed
./core/system/token_tracker.sh init

# Save a status tweet
./modules/communication/twitter.sh save-status

# Commit and push changes
git add .
git commit -m "feat: Enhanced system monitoring and automation

Implemented automated health checks, token reporting, and system monitoring. Added automated git operations for better reliability.

> Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
git push