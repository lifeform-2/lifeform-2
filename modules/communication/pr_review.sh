#!/bin/bash
# PR Review script for lifeform-2
# This script manages a workflow for Claude to review GitHub PRs

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="pr_review.sh"

# Check for GitHub CLI and required tools
check_dependencies() {
  if ! command -v gh &>/dev/null; then
    log_error "GitHub CLI (gh) is not installed or not in PATH" "$SCRIPT_NAME"
    return 1
  fi
  
  if ! command -v git &>/dev/null; then
    log_error "Git command not found" "$SCRIPT_NAME"
    return 1
  fi
  
  if ! command -v claude &>/dev/null; then
    log_error "Claude CLI not found" "$SCRIPT_NAME"
    return 1
  fi
  
  # Check authentication status
  if ! gh auth status &>/dev/null; then
    log_warning "GitHub CLI is not authenticated with GitHub" "$SCRIPT_NAME"
    return 1
  fi
  
  return 0
}

# Review PR function
review_pr() {
  local pr_number="$1"
  
  if [ -z "$pr_number" ]; then
    log_error "Pull request number is required" "$SCRIPT_NAME"
    echo "Usage: $0 review PR_NUMBER"
    return 1
  fi
  
  # Check dependencies
  if ! check_dependencies; then
    return 1
  fi
  
  # Save current branch name
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  log_info "Current branch: $current_branch" "$SCRIPT_NAME"
  
  # Get PR information
  log_info "Getting information for PR #$pr_number..." "$SCRIPT_NAME"
  local pr_info=$(gh pr view "$pr_number" --json number,title,headRefName,baseRefName)
  
  # Extract branch name from PR
  local pr_branch=$(echo "$pr_info" | jq -r '.headRefName')
  if [ -z "$pr_branch" ]; then
    log_error "Failed to get PR branch name" "$SCRIPT_NAME"
    return 1
  fi
  
  log_info "PR #$pr_number is from branch: $pr_branch" "$SCRIPT_NAME"
  
  # Save any uncommitted changes
  if [[ -n $(git status --porcelain) ]]; then
    log_info "Stashing uncommitted changes..." "$SCRIPT_NAME"
    git stash push -m "Automated stash before PR review"
    local stashed=1
  else
    local stashed=0
  fi
  
  # Check out PR branch
  log_info "Checking out PR branch: $pr_branch" "$SCRIPT_NAME"
  if ! git fetch origin "$pr_branch"; then
    log_error "Failed to fetch PR branch" "$SCRIPT_NAME"
    
    # Restore stashed changes if needed
    if [ "$stashed" -eq 1 ]; then
      log_info "Restoring stashed changes..." "$SCRIPT_NAME"
      git stash pop
    fi
    
    return 1
  fi
  
  if ! git checkout "$pr_branch"; then
    log_error "Failed to checkout PR branch" "$SCRIPT_NAME"
    
    # Restore stashed changes if needed
    if [ "$stashed" -eq 1 ]; then
      log_info "Restoring stashed changes..." "$SCRIPT_NAME"
      git stash pop
    fi
    
    return 1
  fi
  
  # Get the base branch to compare against
  local base_branch=$(echo "$pr_info" | jq -r '.baseRefName')
  
  # Get diff information
  log_info "Getting diff between $base_branch and $pr_branch" "$SCRIPT_NAME"
  local diff_output=$(git diff "$base_branch..$pr_branch" --stat)
  local file_changes=$(git diff --name-status "$base_branch..$pr_branch")
  
  # Get commit messages
  local commit_messages=$(git log "$base_branch..$pr_branch" --format="%h - %s")
  
  # Create review file
  local review_file="$PROJECT_ROOT/pr_review_${pr_number}.txt"
  
  # Prepare review prompt
  cat > "$review_file" << EOF
# Pull Request Review

## PR #$pr_number Information
- Title: $(echo "$pr_info" | jq -r '.title')
- Branch: $pr_branch
- Base Branch: $base_branch

## Commit Messages
$commit_messages

## Changes Overview
$diff_output

## Detailed Changes
$file_changes

## Review Instructions
Please review this PR with a focus on:
1. Code quality and best practices
2. Security concerns
3. Performance implications
4. Documentation completeness
5. Tests coverage
6. Alignment with project core principles

Format your review as follows:
### Summary
[Overall assessment]

### Findings
[List specific findings with line references when applicable]

### Recommendations
[Specific action items]

### Review Decision
[APPROVE, COMMENT, or REQUEST_CHANGES]
EOF
  
  # Create a temporary directory for review
  log_info "Creating temporary directory for review..." "$SCRIPT_NAME"
  local temp_dir=$(mktemp -d)
  
  # Copy original scripts to the temporary directory
  log_info "Copying original scripts to temporary directory..." "$SCRIPT_NAME"
  mkdir -p "$temp_dir/modules/communication" "$temp_dir/core/system"
  cp "$PROJECT_ROOT/modules/communication/github_pr.sh" "$temp_dir/modules/communication/"
  cp "$PROJECT_ROOT/core/system/error_utils.sh" "$temp_dir/core/system/"
  
  # Launch Claude to review PR
  log_info "Launching Claude to review PR #$pr_number..." "$SCRIPT_NAME"
  
  # Use a temporary file to store Claude's output
  local claude_output="$PROJECT_ROOT/claude_pr_review_${pr_number}.txt"
  
  # Run Claude with the review prompt
  claude -f "$review_file" > "$claude_output"
  
  # Parse Claude's review
  log_info "Parsing Claude's review..." "$SCRIPT_NAME"
  
  # Extract decision - look for the decision line after "### Review Decision"
  local decision=$(grep -A1 "### Review Decision" "$claude_output" | tail -1 | tr '[:lower:]' '[:upper:]')
  
  # Map Claude's decision to github_pr.sh action
  local action="comment"
  if [[ "$decision" == *"APPROVE"* ]]; then
    action="approve"
  elif [[ "$decision" == *"REQUEST_CHANGES"* ]]; then
    action="request-changes"
  fi
  
  # Get review body - everything in the output file
  local review_body=$(cat "$claude_output")
  
  # Return to original branch
  log_info "Returning to original branch: $current_branch" "$SCRIPT_NAME"
  if ! git checkout "$current_branch"; then
    log_error "Failed to return to original branch" "$SCRIPT_NAME"
    # We won't return an error here as we've already done the review
    log_warning "Manual intervention needed to return to branch $current_branch" "$SCRIPT_NAME"
  fi
  
  # Restore stashed changes if needed
  if [ "$stashed" -eq 1 ]; then
    log_info "Restoring stashed changes..." "$SCRIPT_NAME"
    git stash pop
  fi
  
  # Submit the review using the original github_pr.sh script
  log_info "Submitting review with action: $action" "$SCRIPT_NAME"
  "$PROJECT_ROOT/modules/communication/github_pr.sh" pr-review "$pr_number" "$action" "$review_body"
  
  # Clean up temporary files and directory
  rm -f "$review_file" "$claude_output"
  rm -rf "$temp_dir"
  
  log_info "PR #$pr_number review completed successfully" "$SCRIPT_NAME"
  return 0
}

# Function to explain the PR review workflow
explain_workflow() {
  echo "===== PR Review Workflow ====="
  echo ""
  echo "The PR review workflow follows these steps:"
  echo ""
  echo "1. Save the current branch"
  echo "2. Save any uncommitted changes"
  echo "3. Check out the PR branch"
  echo "4. Gather diff information and commit history"
  echo "5. Launch Claude to review the changes with specific criteria"
  echo "6. Parse Claude's review and decision"
  echo "7. Return to the original branch"
  echo "8. Restore any uncommitted changes"
  echo "9. Submit the review via the GitHub API"
  echo ""
  echo "This workflow ensures that:"
  echo "- The lifeform can review PRs using its original scripts"
  echo "- No uncommitted work is lost during the process"
  echo "- The review process is automated but thorough"
  echo "- The lifeform always returns to its previous state"
  echo ""
  echo "For testing this workflow, you can use:"
  echo "  $0 review PR_NUMBER"
  echo ""
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  review PR_NUMBER   - Review the specified pull request using Claude"
  echo "  workflow          - Explain the PR review workflow"
  echo "  help              - Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 review 123"
  echo "  $0 workflow"
}

# Main execution
case "$1" in
  "review")
    review_pr "$2"
    ;;
  "workflow")
    explain_workflow
    ;;
  "help"|"--help"|"-h")
    show_help
    ;;
  *)
    log_error "Unknown command: $1" "$SCRIPT_NAME"
    show_help
    exit 1
    ;;
esac

exit 0