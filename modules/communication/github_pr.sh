#!/bin/bash
# GitHub Pull Request and Issue management integration for lifeform-2
# This script facilitates interaction with GitHub PRs and issues through the 'gh' CLI

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="github_pr.sh"

# Check if the gh CLI is installed and functioning
check_gh_cli() {
  if ! command -v gh &>/dev/null; then
    log_error "GitHub CLI (gh) is not installed or not in PATH" "$SCRIPT_NAME"
    echo "Please install the GitHub CLI from https://cli.github.com/"
    return 1
  fi
  
  # Check authentication status
  if ! gh auth status &>/dev/null; then
    log_warning "GitHub CLI is not authenticated with GitHub" "$SCRIPT_NAME"
    echo "Please run 'gh auth login' to authenticate with GitHub"
    return 1
  fi
  
  return 0
}

# Function to list open pull requests
list_pull_requests() {
  log_info "Listing open pull requests..." "$SCRIPT_NAME"
  
  if ! check_gh_cli; then
    return 1
  fi
  
  # List open PRs in the current repository
  gh pr list --limit 10
  
  return $?
}

# Function to view a specific pull request
view_pull_request() {
  local pr_number="$1"
  
  if [ -z "$pr_number" ]; then
    log_error "Pull request number is required" "$SCRIPT_NAME"
    echo "Usage: $0 view PR_NUMBER"
    return 1
  fi
  
  log_info "Viewing pull request #$pr_number..." "$SCRIPT_NAME"
  
  if ! check_gh_cli; then
    return 1
  fi
  
  # View the PR details
  gh pr view "$pr_number"
  
  return $?
}

# Function to review a pull request
review_pull_request() {
  local pr_number="$1"
  local action="$2"
  local comment="$3"
  
  if [ -z "$pr_number" ] || [ -z "$action" ]; then
    log_error "Pull request number and action are required" "$SCRIPT_NAME"
    echo "Usage: $0 review PR_NUMBER (approve|comment|request-changes) [COMMENT]"
    return 1
  fi
  
  # Validate action
  if [[ ! "$action" =~ ^(approve|comment|request-changes)$ ]]; then
    log_error "Invalid action: $action" "$SCRIPT_NAME"
    echo "Valid actions: approve, comment, request-changes"
    return 1
  fi
  
  log_info "Reviewing pull request #$pr_number with action: $action..." "$SCRIPT_NAME"
  
  if ! check_gh_cli; then
    return 1
  fi
  
  # If comment is provided, use it; otherwise prompt for comment
  if [ -n "$comment" ]; then
    gh pr review "$pr_number" --"$action" --body "$comment"
  else
    # For approve without comment
    if [ "$action" = "approve" ]; then
      gh pr review "$pr_number" --approve
    else
      log_error "Comment is required for '$action' action" "$SCRIPT_NAME"
      echo "Usage: $0 review PR_NUMBER $action COMMENT"
      return 1
    fi
  fi
  
  return $?
}

# Function to list issues
list_issues() {
  local state="${1:-open}"
  
  log_info "Listing $state issues..." "$SCRIPT_NAME"
  
  if ! check_gh_cli; then
    return 1
  fi
  
  # Validate state
  if [[ ! "$state" =~ ^(open|closed|all)$ ]]; then
    log_warning "Invalid state: $state. Using 'open' instead." "$SCRIPT_NAME"
    state="open"
  fi
  
  # List issues in the current repository
  gh issue list --state "$state" --limit 10
  
  return $?
}

# Function to view a specific issue
view_issue() {
  local issue_number="$1"
  
  if [ -z "$issue_number" ]; then
    log_error "Issue number is required" "$SCRIPT_NAME"
    echo "Usage: $0 issue-view ISSUE_NUMBER"
    return 1
  fi
  
  log_info "Viewing issue #$issue_number..." "$SCRIPT_NAME"
  
  if ! check_gh_cli; then
    return 1
  fi
  
  # View the issue details
  gh issue view "$issue_number"
  
  return $?
}

# Function to comment on an issue
comment_issue() {
  local issue_number="$1"
  local comment="$2"
  
  if [ -z "$issue_number" ] || [ -z "$comment" ]; then
    log_error "Issue number and comment are required" "$SCRIPT_NAME"
    echo "Usage: $0 issue-comment ISSUE_NUMBER COMMENT"
    return 1
  fi
  
  log_info "Commenting on issue #$issue_number..." "$SCRIPT_NAME"
  
  if ! check_gh_cli; then
    return 1
  fi
  
  # Comment on the issue
  gh issue comment "$issue_number" --body "$comment"
  
  return $?
}

# Function to check repository status and recent activity
repo_status() {
  log_info "Checking repository status and activity..." "$SCRIPT_NAME"
  
  if ! check_gh_cli; then
    return 1
  fi
  
  echo "==== Repository Status ===="
  # Get repository information
  gh repo view
  
  echo -e "\n==== Open Pull Requests ===="
  gh pr list --limit 5
  
  echo -e "\n==== Open Issues ===="
  gh issue list --limit 5
  
  echo -e "\n==== Recent Activities ===="
  # There's no direct gh command for this, but we can use the API
  gh api repos/:owner/:repo/events --jq 'limit(5; .[] | {type: .type, actor: .actor.login, created_at: .created_at})'
  
  return 0
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo ""
  echo "Commands for Pull Requests:"
  echo "  pr-list                        - List open pull requests"
  echo "  pr-view NUMBER                 - View a specific pull request"
  echo "  pr-review NUMBER ACTION [COMMENT] - Review a pull request"
  echo "    ACTION can be: approve, comment, request-changes"
  echo ""
  echo "Commands for Issues:"
  echo "  issue-list [STATE]             - List issues (STATE: open, closed, all)"
  echo "  issue-view NUMBER              - View a specific issue"
  echo "  issue-comment NUMBER COMMENT   - Comment on an issue"
  echo ""
  echo "General Commands:"
  echo "  status                         - Show repository status and recent activity"
  echo "  help                           - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 pr-list"
  echo "  $0 pr-view 123"
  echo "  $0 pr-review 123 approve \"LGTM\""
  echo "  $0 issue-list"
  echo "  $0 issue-view 456"
  echo "  $0 issue-comment 456 \"I'll look into this\""
}

# Main execution
case "$1" in
  "pr-list")
    list_pull_requests
    ;;
  "pr-view")
    view_pull_request "$2"
    ;;
  "pr-review")
    review_pull_request "$2" "$3" "$4"
    ;;
  "issue-list")
    list_issues "$2"
    ;;
  "issue-view")
    view_issue "$2"
    ;;
  "issue-comment")
    comment_issue "$2" "$3"
    ;;
  "status")
    repo_status
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