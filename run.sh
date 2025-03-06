#!/bin/bash
# Main execution script for lifeform-2

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="run.sh"

# Generate a unique session ID for logging purposes
SESSION_ID=$(date +"%Y%m%d%H%M%S")

# Manage log files to prevent excessive growth
clean_logs() {
  log_info "Performing log cleanup..." "$SCRIPT_NAME"
  
  # Ensure log directory exists
  mkdir -p ./logs
  
  # Clean up or truncate info.log if it's too large (5MB)
  if [ -f "./logs/info.log" ] && [ $(stat -f%z "./logs/info.log") -gt 5000000 ]; then
    log_info "Truncating oversized info.log file" "$SCRIPT_NAME"
    # Save last 1000 lines and truncate
    tail -n 1000 "./logs/info.log" > "./logs/info.log.tmp"
    mv "./logs/info.log.tmp" "./logs/info.log"
  fi
  
  # Clean up or truncate error.log if it's too large (1MB)
  if [ -f "./logs/error.log" ] && [ $(stat -f%z "./logs/error.log") -gt 1000000 ]; then
    log_info "Truncating oversized error.log file" "$SCRIPT_NAME"
    # Save last 500 lines and truncate
    tail -n 500 "./logs/error.log" > "./logs/error.log.tmp"
    mv "./logs/error.log.tmp" "./logs/error.log"
  fi
  
  # Clean up command output log if too large
  if [ -f "./logs/commands_output.log" ] && [ $(stat -f%z "./logs/commands_output.log") -gt 1000000 ]; then
    log_info "Truncating oversized commands_output.log file" "$SCRIPT_NAME"
    # Save last 500 lines and truncate
    tail -n 500 "./logs/commands_output.log" > "./logs/commands_output.log.tmp"
    mv "./logs/commands_output.log.tmp" "./logs/commands_output.log"
  fi
}

# Clean logs at startup
clean_logs

log_info "Starting Claude session with ID: $SESSION_ID" "$SCRIPT_NAME"

# Run documentation health check and save to log file 
log_info "Running documentation health check..." "$SCRIPT_NAME"
./core/system/doc_health.sh > ./logs/health_check.log 2>&1
DOC_HEALTH_EXIT=$?

# Run commit review and save to log file
log_info "Reviewing recent commits..." "$SCRIPT_NAME"
./core/system/commit_review.sh --count 5 > ./logs/commit_review.log 2>&1
COMMIT_REVIEW_EXIT=$?

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
./core/system/credential_check.sh check > ./logs/security_check.log 2>&1
SECURITY_CHECK_EXIT=$?

# Automatically commit and push any changes using auto_commit.sh
log_info "Committing changes using auto_commit.sh..." "$SCRIPT_NAME"
./core/system/auto_commit.sh --push

# Final log cleanup to avoid committing large log files
clean_logs

exit 0