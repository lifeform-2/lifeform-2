#!/bin/bash
# Main execution script for lifeform-2

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="run.sh"

# Generate a unique session ID for logging purposes
SESSION_ID=$(date +"%Y%m%d%H%M%S")

log_info "Starting Claude session with ID: $SESSION_ID" "$SCRIPT_NAME"

# Run documentation health check
log_info "Running documentation health check..." "$SCRIPT_NAME"
./core/system/doc_health.sh

# Run commit review
log_info "Reviewing recent commits..." "$SCRIPT_NAME"
./core/system/commit_review.sh --count 5

# Simple one-liner to run Claude as requested by creator
log_info "Launching Claude..." "$SCRIPT_NAME"
claude --dangerously-skip-permissions -p "Read README and act. For every prompt, you must do plenty of sustained productive action, commit and push it." --print

# Run any commands from commands.sh if it exists, then clear it
if [ -f "./commands.sh" ]; then
  log_info "Running post-session commands..." "$SCRIPT_NAME"
  source ./commands.sh > ./logs/commands_output.log 2>&1
  EXIT_CODE=$?
  echo "Exit code: $EXIT_CODE" >> ./logs/commands_output.log
  # Clear the commands file after running
  echo "
# IMPORTANT: commands.sh is automatically cleared after each execution - DO NOT put anything in it
# that you want to persist. Only use it for necessary post-session actions that cannot be performed
# during the Claude session. Prefer direct execution of commands during the session whenever possible." > ./commands.sh
  log_info "commands.sh has been cleared after execution." "$SCRIPT_NAME"
fi

# Run security check
log_info "Running security credential check..." "$SCRIPT_NAME"
./core/system/credential_check.sh check

# Automatically commit and push any changes using auto_commit.sh
log_info "Committing changes using auto_commit.sh..." "$SCRIPT_NAME"
./core/system/auto_commit.sh --push

exit 0