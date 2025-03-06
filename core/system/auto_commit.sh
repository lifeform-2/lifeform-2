#!/bin/bash
# ============================================================================
# AUTO_COMMIT.SH - Simple git commit helper for lifeform-2
# ============================================================================
# Purpose:
#   This script handles committing and pushing changes that remain after a 
#   Claude session ends. It is intentionally simplified following the creator's
#   request and LLM-friendly architecture principles.
#
# Usage:
#   ./auto_commit.sh         # Only commit changes
#   ./auto_commit.sh --push  # Commit and push changes
#
# Note: Per creator's instructions, this script should NOT be directly called
# in the Action Algorithm. Instead, direct git commands should be used during
# Claude sessions, with this only used as a fallback in run.sh for stragglers.
# ============================================================================

# Load shared error utilities for consistent logging and error handling
source "$(dirname "$0")/error_utils.sh"

# Define script name for logging context
SCRIPT_NAME="auto_commit.sh"

# -----------------------------------------------------------------------------
# Function: check_for_changes
# Purpose: Checks if there are uncommitted changes in the git repository
# Returns: 0 if changes exist, 1 if no changes or errors
# -----------------------------------------------------------------------------
check_for_changes() {
  log_info "Checking for changes to commit..." "$SCRIPT_NAME"
  
  # Verify git is installed
  if ! command -v git &> /dev/null; then
    log_error "Git command not found" "$SCRIPT_NAME"
    return 1
  fi
  
  # Ensure we're in a git repository
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    log_error "Not in a git repository" "$SCRIPT_NAME"
    return 1
  fi
  
  # Check for unstaged/staged changes
  if [ -z "$(git status --porcelain)" ]; then
    log_info "No changes to commit" "$SCRIPT_NAME"
    return 1
  fi
  
  # Changes found
  return 0
}

# -----------------------------------------------------------------------------
# Function: commit_changes
# Purpose: Commits all changes with a simple message
# Returns: 0 on success, 1 on failure
# -----------------------------------------------------------------------------
commit_changes() {
  # Check if there are changes to commit
  if ! check_for_changes; then
    return 0  # No changes to commit is not an error
  fi
  
  log_info "Committing post-session changes" "$SCRIPT_NAME"
  
  # Add all changes
  safe_exec "git add ." "Failed to add changes to git staging" "$SCRIPT_NAME" || return 1
  
  # Use a simple, consistent commit message for straggler changes
  # Main commits should be handled by Claude during the session
  safe_exec "git commit -m \"chore: auto-commit remaining changes after session

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>\"" "Failed to commit changes" "$SCRIPT_NAME" || return 1
  
  log_info "Post-session changes committed successfully" "$SCRIPT_NAME"
  return 0
}

# -----------------------------------------------------------------------------
# Function: push_changes
# Purpose: Pushes commits to remote repository
# Returns: 0 on success, 1 on failure
# -----------------------------------------------------------------------------
push_changes() {
  log_info "Pushing changes to remote repository..." "$SCRIPT_NAME"
  
  # Check if there's a remote repository configured
  if ! git remote -v | grep -q origin; then
    log_warning "No remote repository found, skipping push" "$SCRIPT_NAME"
    return 0  # Not an error, just nothing to do
  fi
  
  # Push changes
  safe_exec "git push" "Failed to push changes to remote repository" "$SCRIPT_NAME" || return 1
  
  log_info "Changes pushed successfully" "$SCRIPT_NAME"
  return 0
}

# -----------------------------------------------------------------------------
# Function: main
# Purpose: Main script execution
# Parameters:
#   $1 - Optional --push flag to also push changes
# -----------------------------------------------------------------------------
main() {
  local do_push=false
  
  # Simple argument parsing (intentionally minimal)
  if [[ "$1" == "--push" ]]; then
    do_push=true
  fi
  
  # Commit changes
  commit_changes || exit 1
  
  # Push changes if requested
  if $do_push; then
    push_changes || exit 1
  fi
  
  exit 0
}

# Execute main function with all arguments
main "$@"