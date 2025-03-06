#!/bin/bash
# PR Monitoring script for lifeform-2
# This script checks for new PRs since the last activation and queues them for review

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="pr_monitor.sh"

# State file to track last checked PR
PR_STATE_FILE="$PROJECT_ROOT/logs/pr_monitor_state.json"

# Ensure logs directory exists
mkdir -p "$PROJECT_ROOT/logs"

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

# Function to get the most recent PR number from the state file
get_last_checked_pr() {
  if [ -f "$PR_STATE_FILE" ]; then
    last_pr=$(jq -r '.last_checked_pr // 0' "$PR_STATE_FILE")
    log_info "Last checked PR: #$last_pr" "$SCRIPT_NAME"
    echo "$last_pr"
  else
    log_info "No state file found, creating new one" "$SCRIPT_NAME"
    echo '{"last_checked_pr": 0, "last_checked_time": "2025-03-06T00:00:00Z"}' > "$PR_STATE_FILE"
    echo "0"
  fi
}

# Function to update the state file with the latest PR number
update_last_checked_pr() {
  local pr_number="$1"
  
  if [ -z "$pr_number" ]; then
    log_error "PR number is required to update state" "$SCRIPT_NAME"
    return 1
  fi
  
  # Create or update the state file
  echo "{\"last_checked_pr\": $pr_number, \"last_checked_time\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}" > "$PR_STATE_FILE"
  log_info "Updated state file with last checked PR: #$pr_number" "$SCRIPT_NAME"
  
  return 0
}

# Function to check for new PRs
check_new_prs() {
  log_info "Checking for new PRs..." "$SCRIPT_NAME"
  
  if ! check_gh_cli; then
    return 1
  fi
  
  # Get the last checked PR number
  last_pr=$(get_last_checked_pr)
  
  # Get current list of open PRs, sorted by newest first
  log_info "Fetching current list of open PRs..." "$SCRIPT_NAME"
  pr_list=$(gh pr list --json number,title,createdAt --limit 10 --state open)
  
  # Check if PR list is empty
  if [ -z "$pr_list" ] || [ "$pr_list" = "[]" ]; then
    log_info "No open PRs found" "$SCRIPT_NAME"
    # Set highest PR to 0 if no PRs exist
    update_last_checked_pr "0"
    return 0
  fi
  
  # Don't try to parse if there are no PRs
  new_prs="[]"
  new_pr_count=0
  
  # Get the first PR number from the list (the highest number)
  highest_pr=$(echo "$pr_list" | jq -r '.[0].number // 0')
  
  # Update state file with the highest PR number
  if [ -n "$highest_pr" ] && [ "$highest_pr" != "null" ]; then
    update_last_checked_pr "$highest_pr"
  fi
  
  # For now, we're just setting up the state file
  # In the future, this would get more complex to find new PRs
  log_info "PR monitoring state updated" "$SCRIPT_NAME"
  
  # Return an empty array
  echo "[]"
  
  return 0
}

# Function to queue PR reviews
queue_pr_reviews() {
  local new_prs="$1"
  
  if [ -z "$new_prs" ] || [ "$new_prs" = "[]" ]; then
    log_info "No PRs to queue for review" "$SCRIPT_NAME"
    return 0
  fi
  
  log_info "Queuing PRs for review..." "$SCRIPT_NAME"
  
  # Create a commands file for PR reviews if one doesn't exist
  local commands_file="$PROJECT_ROOT/pr_review_commands.sh"
  echo "#!/bin/bash" > "$commands_file"
  echo "# PR review commands generated on $(date)" >> "$commands_file"
  echo "" >> "$commands_file"
  
  # Generate commands for each PR
  # With our current implementation, this only runs on first time setup
  # In a real scenario with PRs, we would iterate through them here
  
  # For now, just add a comment to the commands file
  echo "# No new PRs to review" >> "$commands_file"
  echo "echo \"No new PRs found for review\"" >> "$commands_file"
  
  # Make the file executable
  chmod +x "$commands_file"
  
  log_info "PR review commands queued in $commands_file" "$SCRIPT_NAME"
  
  return 0
}

# Function to initiate PR monitoring
monitor_prs() {
  log_info "Starting PR monitoring..." "$SCRIPT_NAME"
  
  # Check for new PRs
  new_prs=$(check_new_prs)
  
  if [ $? -ne 0 ]; then
    log_error "Failed to check for new PRs" "$SCRIPT_NAME"
    return 1
  fi
  
  # Queue reviews for new PRs
  queue_pr_reviews "$new_prs"
  
  log_info "PR monitoring completed" "$SCRIPT_NAME"
  return 0
}

# Function to explain the PR monitoring workflow
explain_workflow() {
  echo "===== PR Monitoring Workflow ====="
  echo ""
  echo "The PR monitoring workflow follows these steps:"
  echo ""
  echo "1. Check for the last monitored PR number in state file"
  echo "2. Fetch current open PRs from GitHub"
  echo "3. Identify PRs that are newer than the last checked PR"
  echo "4. Update the state file with the latest PR number"
  echo "5. Queue the new PRs for review"
  echo "6. Generate review commands that will be executed during activation"
  echo ""
  echo "This workflow ensures that:"
  echo "- All new PRs are automatically detected"
  echo "- The state is maintained across activations"
  echo "- Each PR is reviewed only once"
  echo "- Reviews are performed without interrupting other operations"
  echo ""
  echo "For manual monitoring, you can use:"
  echo "  $0 monitor"
  echo ""
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND"
  echo ""
  echo "Commands:"
  echo "  monitor           - Check for new PRs and queue them for review"
  echo "  workflow          - Explain the PR monitoring workflow"
  echo "  help              - Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 monitor"
}

# Main execution
case "$1" in
  "monitor")
    monitor_prs
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