#!/bin/bash
# IMPORTANT: This file is automatically cleared after execution
# Place commands here that should run after the Claude session ends

# Generate a health report
echo "Generating health report..."
./core/system/monitor.sh > ./logs/health_report_$(date +"%Y%m%d").txt

# Save a status update tweet
echo "Generating status tweet..."
./modules/communication/twitter.sh save-status

# Run token tracker to update usage statistics
echo "Updating token usage statistics..."
./core/system/token_tracker.sh init

# Commit and push changes
echo "Committing changes to git repository..."
./core/system/auto_commit.sh --push

# Note: This file will be cleared after execution