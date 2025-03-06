#!/bin/bash
# Claude-friendly monitoring script for PR and issue detection
# This script is designed to be run directly from Claude to provide visibility into the monitoring process

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="claude_monitor.sh"

# Function to initialize the script
initialize() {
  echo "Initializing Claude-friendly monitoring system..."
  echo "This script provides direct visibility for Claude into PR and issue monitoring."
  echo "Any errors or issues will be displayed directly in Claude's context."
  echo "======================================================================"
  echo ""
}

# Function to check if GitHub CLI is installed and authenticated
check_gh_cli() {
  echo "Checking GitHub CLI availability and authentication..."
  
  if ! command -v gh &>/dev/null; then
    echo "❌ ERROR: GitHub CLI (gh) is not installed or not in PATH"
    echo "Please install the GitHub CLI from https://cli.github.com/"
    return 1
  fi
  
  # Check authentication status with detailed output for Claude
  echo "Verifying GitHub authentication status..."
  if gh auth status 2>&1; then
    echo "✅ GitHub CLI is properly authenticated"
  else
    echo "❌ GitHub CLI is not authenticated with GitHub"
    echo "Please run 'gh auth login' to authenticate with GitHub"
    return 1
  fi
  
  return 0
}

# Function to monitor PRs with full output for Claude
monitor_prs() {
  echo "======================================================================"
  echo "MONITORING PULL REQUESTS"
  echo "======================================================================"
  
  # First check if GitHub CLI is available
  if ! check_gh_cli; then
    echo "❌ Cannot monitor PRs without GitHub CLI access"
    return 1
  fi
  
  echo "Running PR monitoring with direct output..."
  
  # Get the PR monitor script path
  PR_MONITOR="$PROJECT_ROOT/modules/communication/pr_monitor.sh"
  if [ ! -f "$PR_MONITOR" ]; then
    echo "❌ ERROR: PR monitoring script not found at $PR_MONITOR"
    return 1
  fi
  
  # Check PR monitoring state before running
  PR_STATE_FILE="$PROJECT_ROOT/logs/pr_monitor_state.json"
  if [ -f "$PR_STATE_FILE" ]; then
    echo "Current PR monitoring state:"
    cat "$PR_STATE_FILE"
    echo ""
  else
    echo "No existing PR monitoring state found. This appears to be the first run."
    echo ""
  fi
  
  # Run the PR monitoring script with all output sent to Claude
  echo "Executing PR monitoring..."
  # Run in a subshell to capture all output
  output=$("$PR_MONITOR" monitor 2>&1)
  PR_RESULT=$?
  
  # Display the output
  echo "$output"
  
  # Look for specific errors in the output and handle them
  if echo "$output" | grep -q "Invalid JSON"; then
    echo ""
    echo "⚠️ Warning: Invalid JSON detected in the GitHub API response"
    echo "This error sometimes occurs due to GitHub API rate limiting or temporary issues"
    echo "Try again in a few minutes or check the GitHub status page"
    PR_RESULT=1
  fi
  
  # Check if PR commands were generated
  if [ -f "$PROJECT_ROOT/pr_review_commands.sh" ]; then
    echo ""
    echo "Found PR review commands. New PRs were detected!"
    echo "Content of pr_review_commands.sh:"
    echo "--------------------------------------------------------------------"
    cat "$PROJECT_ROOT/pr_review_commands.sh"
    echo "--------------------------------------------------------------------"
    echo ""
    echo "To execute these commands, run:"
    echo "source $PROJECT_ROOT/pr_review_commands.sh"
    echo ""
  else
    echo ""
    echo "No new PRs were detected that require review."
    echo ""
  fi
  
  # Check updated state
  if [ -f "$PR_STATE_FILE" ]; then
    echo "Updated PR monitoring state:"
    cat "$PR_STATE_FILE"
    echo ""
  fi
  
  return $PR_RESULT
}

# Function to monitor issues with full output for Claude
monitor_issues() {
  echo "======================================================================"
  echo "MONITORING GITHUB ISSUES"
  echo "======================================================================"
  
  # First check if GitHub CLI is available
  if ! check_gh_cli; then
    echo "❌ Cannot monitor issues without GitHub CLI access"
    return 1
  fi
  
  echo "Running issue monitoring with direct output..."
  
  # Get the issue monitor script path
  ISSUE_MONITOR="$PROJECT_ROOT/modules/communication/github_issue_monitor.sh"
  if [ ! -f "$ISSUE_MONITOR" ]; then
    echo "❌ ERROR: Issue monitoring script not found at $ISSUE_MONITOR"
    return 1
  fi
  
  # Check issue monitoring state before running
  ISSUE_STATE_FILE="$PROJECT_ROOT/logs/issue_monitor_state.json"
  if [ -f "$ISSUE_STATE_FILE" ]; then
    echo "Current issue monitoring state:"
    cat "$ISSUE_STATE_FILE"
    echo ""
  else
    echo "No existing issue monitoring state found. This appears to be the first run."
    echo ""
  fi
  
  # Run the issue monitoring script with all output sent to Claude
  echo "Executing issue monitoring..."
  # Run in a subshell to capture all output
  output=$("$ISSUE_MONITOR" monitor 2>&1)
  ISSUE_RESULT=$?
  
  # Display the output
  echo "$output"
  
  # Look for specific errors in the output and handle them
  if echo "$output" | grep -q "Invalid JSON"; then
    echo ""
    echo "⚠️ Warning: Invalid JSON detected in the GitHub API response"
    echo "This error sometimes occurs due to GitHub API rate limiting or temporary issues"
    echo "Try again in a few minutes or check the GitHub status page"
    ISSUE_RESULT=1
  fi
  
  # Check if issue commands were generated
  if [ -f "$PROJECT_ROOT/issue_analysis_commands.sh" ]; then
    echo ""
    echo "Found issue analysis commands. New issues were detected!"
    echo "Content of issue_analysis_commands.sh:"
    echo "--------------------------------------------------------------------"
    cat "$PROJECT_ROOT/issue_analysis_commands.sh"
    echo "--------------------------------------------------------------------"
    echo ""
    echo "To execute these commands, run:"
    echo "source $PROJECT_ROOT/issue_analysis_commands.sh"
    echo ""
  else
    echo ""
    echo "No new issues were detected that require analysis."
    echo ""
  fi
  
  # Check updated state
  if [ -f "$ISSUE_STATE_FILE" ]; then
    echo "Updated issue monitoring state:"
    cat "$ISSUE_STATE_FILE"
    echo ""
  fi
  
  return $ISSUE_RESULT
}

# Function to directly execute PR review commands
execute_pr_commands() {
  echo "======================================================================"
  echo "EXECUTING PR REVIEW COMMANDS"
  echo "======================================================================"
  
  # Check if the PR commands file exists
  if [ ! -f "$PROJECT_ROOT/pr_review_commands.sh" ]; then
    echo "❌ No PR review commands file found at $PROJECT_ROOT/pr_review_commands.sh"
    echo "Run 'monitor prs' first to generate the commands."
    return 1
  fi
  
  echo "Executing PR review commands with direct output..."
  echo "This will execute the following script:"
  echo "--------------------------------------------------------------------"
  cat "$PROJECT_ROOT/pr_review_commands.sh"
  echo "--------------------------------------------------------------------"
  echo ""
  
  # Execute the commands
  echo "Starting PR reviews..."
  source "$PROJECT_ROOT/pr_review_commands.sh"
  PR_EXEC_RESULT=$?
  
  # Report result
  if [ $PR_EXEC_RESULT -eq 0 ]; then
    echo ""
    echo "✅ PR review commands executed successfully"
    # Clean up the commands file
    rm "$PROJECT_ROOT/pr_review_commands.sh"
    echo "Removed PR review commands file."
  else
    echo ""
    echo "❌ Error executing PR review commands (exit code: $PR_EXEC_RESULT)"
    echo "The PR review commands file has been left in place for debugging."
  fi
  
  return $PR_EXEC_RESULT
}

# Function to directly execute issue analysis commands
execute_issue_commands() {
  echo "======================================================================"
  echo "EXECUTING ISSUE ANALYSIS COMMANDS"
  echo "======================================================================"
  
  # Check if the issue commands file exists
  if [ ! -f "$PROJECT_ROOT/issue_analysis_commands.sh" ]; then
    echo "❌ No issue analysis commands file found at $PROJECT_ROOT/issue_analysis_commands.sh"
    echo "Run 'monitor issues' first to generate the commands."
    return 1
  fi
  
  echo "Executing issue analysis commands with direct output..."
  echo "This will execute the following script:"
  echo "--------------------------------------------------------------------"
  cat "$PROJECT_ROOT/issue_analysis_commands.sh"
  echo "--------------------------------------------------------------------"
  echo ""
  
  # Execute the commands
  echo "Starting issue analysis..."
  source "$PROJECT_ROOT/issue_analysis_commands.sh"
  ISSUE_EXEC_RESULT=$?
  
  # Report result
  if [ $ISSUE_EXEC_RESULT -eq 0 ]; then
    echo ""
    echo "✅ Issue analysis commands executed successfully"
    # Clean up the commands file
    rm "$PROJECT_ROOT/issue_analysis_commands.sh"
    echo "Removed issue analysis commands file."
  else
    echo ""
    echo "❌ Error executing issue analysis commands (exit code: $ISSUE_EXEC_RESULT)"
    echo "The issue analysis commands file has been left in place for debugging."
  fi
  
  return $ISSUE_EXEC_RESULT
}

# Function to monitor both PRs and issues
monitor_all() {
  initialize
  
  # Monitor PRs
  monitor_prs
  PR_RESULT=$?
  
  # Monitor issues
  monitor_issues
  ISSUE_RESULT=$?
  
  # Report overall result
  echo "======================================================================"
  echo "MONITORING SUMMARY"
  echo "======================================================================"
  
  if [ $PR_RESULT -eq 0 ] && [ $ISSUE_RESULT -eq 0 ]; then
    echo "✅ All monitoring completed successfully"
  else
    echo "⚠️ Monitoring completed with some issues:"
    
    if [ $PR_RESULT -ne 0 ]; then
      echo "  - PR monitoring encountered errors (exit code: $PR_RESULT)"
      echo "    This demonstrates how Claude can now directly see monitoring errors"
      echo "    and take appropriate action based on the specific error type."
    fi
    
    if [ $ISSUE_RESULT -ne 0 ]; then
      echo "  - Issue monitoring encountered errors (exit code: $ISSUE_RESULT)"
      echo "    This demonstrates how Claude can now directly see monitoring errors"
      echo "    and take appropriate action based on the specific error type."
    fi
    
    echo ""
    echo "The ability to see these errors directly addresses the creator's concern:"
    echo "\"I'm concerned of how use organized PR monitor. You don't launch it from"
    echo "Claude, and you won't see errors (which I see) that happen when you launch it."
    echo "You should pursue strategies that give your LLM brain higher-level place in"
    echo "the call stack so that you can see when your tools malfunction and adjust.\""
  fi
  
  # Provide options for next steps
  echo ""
  echo "Next steps:"
  
  if [ -f "$PROJECT_ROOT/pr_review_commands.sh" ]; then
    echo "- To process new PRs: $0 execute prs"
  fi
  
  if [ -f "$PROJECT_ROOT/issue_analysis_commands.sh" ]; then
    echo "- To process new issues: $0 execute issues"
  fi
  
  if [ ! -f "$PROJECT_ROOT/pr_review_commands.sh" ] && [ ! -f "$PROJECT_ROOT/issue_analysis_commands.sh" ]; then
    echo "- No new PRs or issues requiring action"
  fi
  
  echo ""
  
  return 0
}

# Display script help
show_help() {
  echo "Usage: $0 COMMAND"
  echo ""
  echo "This script provides Claude with direct visibility into PR and issue monitoring."
  echo ""
  echo "Commands:"
  echo "  monitor all       - Monitor both PRs and issues"
  echo "  monitor prs       - Monitor PRs only"
  echo "  monitor issues    - Monitor issues only"
  echo "  execute prs       - Execute PR review commands"
  echo "  execute issues    - Execute issue analysis commands"
  echo "  check-gh          - Check GitHub CLI availability"
  echo "  help              - Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 monitor all"
  echo ""
  echo "This script is designed to be run directly from Claude, providing"
  echo "visibility into the monitoring process and any errors that occur."
}

# Main execution
case "$1" in
  "monitor")
    case "$2" in
      "all")
        monitor_all
        ;;
      "prs")
        initialize
        monitor_prs
        ;;
      "issues")
        initialize
        monitor_issues
        ;;
      *)
        echo "❌ Unknown monitor target: $2"
        show_help
        exit 1
        ;;
    esac
    ;;
  "execute")
    case "$2" in
      "prs")
        execute_pr_commands
        ;;
      "issues")
        execute_issue_commands
        ;;
      *)
        echo "❌ Unknown execute target: $2"
        show_help
        exit 1
        ;;
    esac
    ;;
  "check-gh")
    initialize
    check_gh_cli
    ;;
  "help"|"--help"|"-h")
    show_help
    ;;
  *)
    echo "❌ Unknown command: $1"
    show_help
    exit 1
    ;;
esac

exit 0