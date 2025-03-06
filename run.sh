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

# Check for new PRs and queue them for review
check_prs() {
  log_info "Checking for new PRs..." "$SCRIPT_NAME"
  
  # Check if PR monitoring script exists
  if [ ! -f "./modules/communication/pr_monitor.sh" ]; then
    log_warning "PR monitoring script not found, skipping PR checks" "$SCRIPT_NAME"
    return 0
  fi
  
  # Run PR monitoring script
  ./modules/communication/pr_monitor.sh monitor
  
  # Check if PR review commands were generated
  if [ -f "./pr_review_commands.sh" ]; then
    log_info "Found queued PR reviews, executing..." "$SCRIPT_NAME"
    
    # Execute the PR review commands
    source ./pr_review_commands.sh > ./logs/pr_review_output.log 2>&1
    PR_REVIEW_EXIT_CODE=$?
    
    # Log result
    if [ $PR_REVIEW_EXIT_CODE -eq 0 ]; then
      log_info "PR reviews completed successfully" "$SCRIPT_NAME"
    else
      log_error "PR reviews encountered errors (exit code: $PR_REVIEW_EXIT_CODE)" "$SCRIPT_NAME"
    fi
    
    # Clean up the PR review commands file
    rm ./pr_review_commands.sh
  else
    log_info "No new PRs to review" "$SCRIPT_NAME"
  fi
  
  return 0
}

# Check for new GitHub issues and generate responses
check_issues() {
  log_info "Checking for new GitHub issues..." "$SCRIPT_NAME"
  
  # Check if issue monitoring script exists
  if [ ! -f "./modules/communication/github_issue_monitor.sh" ]; then
    log_warning "GitHub issue monitoring script not found, skipping issue checks" "$SCRIPT_NAME"
    return 0
  fi
  
  # Run issue monitoring script
  ./modules/communication/github_issue_monitor.sh monitor
  
  # Check if issue analysis commands were generated
  if [ -f "./issue_analysis_commands.sh" ]; then
    log_info "Found new issues to analyze, executing..." "$SCRIPT_NAME"
    
    # Execute the issue analysis commands
    source ./issue_analysis_commands.sh > ./logs/issue_analysis_output.log 2>&1
    ISSUE_ANALYSIS_EXIT_CODE=$?
    
    # Log result
    if [ $ISSUE_ANALYSIS_EXIT_CODE -eq 0 ]; then
      log_info "Issue analysis completed successfully" "$SCRIPT_NAME"
    else
      log_error "Issue analysis encountered errors (exit code: $ISSUE_ANALYSIS_EXIT_CODE)" "$SCRIPT_NAME"
    fi
    
    # Clean up the issue analysis commands file
    rm ./issue_analysis_commands.sh
  else
    log_info "No new issues to analyze" "$SCRIPT_NAME"
  fi
  
  return 0
}

# Check if there are any changes to commit
check_for_changes() {
  log_info "Checking for changes to commit..." "$SCRIPT_NAME"
  
  # Check if git is available
  if ! command -v git &> /dev/null; then
    log_error "Git command not found" "$SCRIPT_NAME"
    return 1
  fi
  
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    log_error "Not in a git repository" "$SCRIPT_NAME"
    return 1
  fi
  
  # Check for changes
  if [ -z "$(git status --porcelain)" ]; then
    log_info "No changes to commit" "$SCRIPT_NAME"
    return 1
  else
    return 0
  fi
}

# Function to commit changes (for post-session stragglers only)
commit_changes() {
  # Check if there are changes to commit
  if ! check_for_changes; then
    return 0
  fi
  
  log_info "Committing post-session changes" "$SCRIPT_NAME"
  
  # Add all changes
  git add . || { log_error "Failed to add changes to git staging" "$SCRIPT_NAME"; return 1; }
  
  # Commit changes - Note: Claude should generate descriptive commits during the session
  # This is only a fallback for changes made after Claude completes
  git commit -m "chore: auto-commit remaining changes after session
  
🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>" || { log_error "Failed to commit changes" "$SCRIPT_NAME"; return 1; }
  
  log_info "Post-session changes committed successfully" "$SCRIPT_NAME"
  return 0
}

# Function to push changes
push_changes() {
  log_info "Pushing changes to remote repository..." "$SCRIPT_NAME"
  
  # Check if there's a remote repository
  if ! git remote -v | grep -q origin; then
    log_warning "No remote repository found, skipping push" "$SCRIPT_NAME"
    return 0
  fi
  
  # Push changes
  git push || { log_error "Failed to push changes to remote repository" "$SCRIPT_NAME"; return 1; }
  
  log_info "Changes pushed successfully" "$SCRIPT_NAME"
  return 0
}

# Clean logs at startup
clean_logs

log_info "Starting Claude session with ID: $SESSION_ID" "$SCRIPT_NAME"

# Check for new PRs and issues before starting Claude session
log_info "Checking for new PRs and issues before starting session..." "$SCRIPT_NAME"
check_prs
check_issues

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
  cat > ./commands.sh << 'ENDOFCOMMANDS'
# IMPORTANT: commands.sh is automatically cleared after each execution - DO NOT put anything in it
# that you want to persist. Only use it for necessary post-session actions that cannot be performed
# during the Claude session. Prefer direct execution of commands during the session whenever possible.
ENDOFCOMMANDS
  log_info "commands.sh has been cleared after execution." "$SCRIPT_NAME"
fi

# Commit and push any straggler changes
log_info "Checking for any post-session changes to commit..." "$SCRIPT_NAME"
commit_changes && push_changes

# Final log cleanup to avoid committing large log files
clean_logs

exit 0