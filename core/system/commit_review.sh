#!/bin/bash
# Commit review script for lifeform-2
# This script reviews recent commit messages and quality

# Load error utilities
source "$(dirname "$0")/error_utils.sh"

# Script name for logging
SCRIPT_NAME="commit_review.sh"

# Function to get recent commits
get_recent_commits() {
  local count=${1:-5}
  log_info "Retrieving the $count most recent commits..." "$SCRIPT_NAME"
  
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
  
  # Get recent commits
  local commits=$(git log -n "$count" --pretty=format:"%h - %s" 2>/dev/null)
  if [ -z "$commits" ]; then
    log_warning "No commits found" "$SCRIPT_NAME"
    return 1
  fi
  
  echo "$commits"
  return 0
}

# Function to analyze a commit
analyze_commit() {
  local commit_hash=$1
  log_info "Analyzing commit: $commit_hash" "$SCRIPT_NAME"
  
  # Get commit message
  local commit_message=$(git log -n 1 --pretty=format:"%s" "$commit_hash" 2>/dev/null)
  if [ -z "$commit_message" ]; then
    log_error "Could not retrieve commit message for $commit_hash" "$SCRIPT_NAME"
    return 1
  fi
  
  # Get commit changes
  local commit_changes=$(git show --name-status "$commit_hash" 2>/dev/null)
  if [ -z "$commit_changes" ]; then
    log_error "Could not retrieve changes for $commit_hash" "$SCRIPT_NAME"
    return 1
  fi
  
  # Analyze message format
  echo "Commit: $commit_hash"
  echo "Message: $commit_message"
  
  # Check for conventional commit format
  if ! echo "$commit_message" | grep -q "^(feat|fix|docs|style|refactor|test|chore).*:"; then
    if ! echo "$commit_message" | grep -q "^feat:|^fix:|^docs:|^style:|^refactor:|^test:|^chore:"; then
      echo "⚠️  Message does not follow conventional commit format"
    fi
  fi
  
  # Check message length
  local message_length=${#commit_message}
  if [ "$message_length" -lt 10 ]; then
    echo "⚠️  Message is too short ($message_length chars)"
  elif [ "$message_length" -gt 100 ]; then
    echo "⚠️  Message is too long ($message_length chars)"
  fi
  
  # List changed files
  echo "Changed files:"
  echo "$commit_changes" | grep -v "^commit" | head -10
  
  # Add a separator
  echo "------------------------"
  
  return 0
}

# Function to review commits
review_commits() {
  local count=${1:-5}
  log_info "Reviewing the $count most recent commits..." "$SCRIPT_NAME"
  
  # Get recent commits
  local commits=$(get_recent_commits "$count")
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  echo "===== Recent Commit Review ====="
  echo
  
  # Analyze each commit
  while IFS= read -r line; do
    local commit_hash=$(echo "$line" | cut -d' ' -f1)
    analyze_commit "$commit_hash"
  done <<< "$commits"
  
  echo "===== Commit Review Summary ====="
  echo "Reviewed $count recent commits"
  echo "Review completed on $(date)"
  echo
  
  return 0
}

# Main execution
main() {
  local count=5
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --count)
        shift
        count=$1
        shift
        ;;
      --help)
        echo "Usage: $0 [--count N]"
        echo "  --count N: Number of commits to review (default: 5)"
        return 0
        ;;
      *)
        log_error "Unknown option: $1" "$SCRIPT_NAME"
        echo "Usage: $0 [--count N]"
        return 1
        ;;
    esac
  done
  
  # Review commits
  review_commits "$count" || return 1
  
  return 0
}

# Run main function and capture exit code
main "$@"
exit_code=$?

# Exit with the captured code
exit $exit_code