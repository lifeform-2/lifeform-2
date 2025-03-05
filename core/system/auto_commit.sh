#!/bin/bash
# Automatic git commit script for lifeform-2
# This script commits all changes made during a session

# Load error utilities
source "$(dirname "$0")/error_utils.sh"

# Script name for logging
SCRIPT_NAME="auto_commit.sh"

# Function to check if there are any changes to commit
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
  fi
  
  return 0
}

# Function to generate a meaningful commit message
generate_commit_message() {
  local message="chore: "
  
  # Get list of modified files
  local modified_files=$(git diff --name-only)
  local added_files=$(git diff --name-only --cached)
  local untracked_files=$(git ls-files --others --exclude-standard)
  
  # Check for specific file types to determine message
  if echo "$modified_files $added_files $untracked_files" | grep -q "communication"; then
    message+="communication"
  elif echo "$modified_files $added_files $untracked_files" | grep -q "monitor\|health\|token"; then
    message+="system monitoring"
  elif echo "$modified_files $added_files $untracked_files" | grep -q "error\|log"; then
    message+="error handling"
  elif echo "$modified_files $added_files $untracked_files" | grep -q "tweet\|social"; then
    message+="social media updates"
  else
    message+="update system files"
  fi
  
  echo "$message"
}

# Function to commit changes
commit_changes() {
  # Check if there are changes to commit
  if ! check_for_changes; then
    return 0
  fi
  
  local commit_message=$(generate_commit_message)
  log_info "Committing changes with message: $commit_message" "$SCRIPT_NAME"
  
  # Add all changes
  safe_exec "git add ." "Failed to add changes to git staging" "$SCRIPT_NAME" || return 1
  
  # Commit changes
  safe_exec "git commit -m \"$commit_message

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>\"" "Failed to commit changes" "$SCRIPT_NAME" || return 1
  
  log_info "Changes committed successfully" "$SCRIPT_NAME"
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
  safe_exec "git push" "Failed to push changes to remote repository" "$SCRIPT_NAME" || return 1
  
  log_info "Changes pushed successfully" "$SCRIPT_NAME"
  return 0
}

# Main execution
main() {
  local do_push=false
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --push)
        do_push=true
        shift
        ;;
      *)
        log_error "Unknown option: $1" "$SCRIPT_NAME"
        echo "Usage: $0 [--push]"
        return 1
        ;;
    esac
  done
  
  # Commit changes
  commit_changes || return 1
  
  # Push changes if requested
  if $do_push; then
    push_changes || return 1
  fi
  
  return 0
}

# Run main function and capture exit code
main "$@"
exit_code=$?

# Exit with the captured code
exit $exit_code