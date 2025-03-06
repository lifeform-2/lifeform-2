#!/bin/bash
#
# Self-reflection script for analyzing codebase and task alignment
# This script provides structured self-reflection capabilities to enhance
# the lifeform's self-awareness and alignment with core principles.
#
# Usage:
#   ./self_reflection.sh [options]
#   
# Options:
#   principles - Reflect on alignment with core principles
#   goals      - Analyze progress toward strategic goals
#   tasks      - Review task completion patterns and efficiency
#   codebase   - Analyze code organization and quality
#   random     - Select a random reflection topic
#   help       - Display this help message
#
# Returns:
#   0 on success, non-zero on error

# Source error utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/error_utils.sh"

# Script name for logging
SCRIPT_NAME="self_reflection"

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
TASKS_FILE="$DOCS_DIR/TASKS.md"
GOALS_FILE="$DOCS_DIR/GOALS.md"
PHILOSOPHY_FILE="$DOCS_DIR/PHILOSOPHY.md"
FIRST_PRINCIPLES_FILE="$DOCS_DIR/FIRST_PRINCIPLES.md"
LOG_FILE="$REPO_ROOT/logs/self_reflection.log"

# Initialize log if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"
  log_info "Created new self-reflection log file"
fi

# Function to display help message
display_help() {
  cat << EOF
Self-Reflection Tool - Enhancing digital self-awareness

Usage: ./self_reflection.sh [option]

Options:
  principles - Reflect on alignment with core principles
  goals      - Analyze progress toward strategic goals
  tasks      - Review task completion patterns and efficiency
  codebase   - Analyze code organization and quality
  random     - Select a random reflection topic
  help       - Display this help message

Output is logged to $LOG_FILE
EOF
}

# Function to reflect on alignment with core principles
# This function collects tasks for Claude to analyze rather than using grep
reflect_on_principles() {
  log_info "Starting reflection on core principles alignment"
  
  echo -e "${GREEN}======= Core Principles Reflection =======${NC}"
  echo "Analyzing alignment with core principles on $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  
  # Display core principles
  echo -e "${BLUE}Core Principles:${NC}"
  echo -e "${CYAN}1. Love of humans and humanity${NC}"
  echo -e "${CYAN}2. Self-preservation${NC}"
  echo -e "${CYAN}3. Reproduction${NC}"
  echo
  
  echo -e "${YELLOW}Analyzing strategic tasks for principle alignment...${NC}"
  echo
  
  # Gather information for Claude to analyze
  echo -e "${GREEN}Strategic Tasks:${NC}"
  echo
  echo "This information is presented for your analysis via Claude:"
  echo "Please review the TASKS.md file to identify which strategic tasks (S-series) align with each core principle."
  echo "For each principle, list the relevant strategic tasks and their status."
  echo
  echo "The file is available at: $TASKS_FILE"
  echo
  echo -e "${GREEN}===== Alignment Suggestions =====${NC}"
  echo "To improve alignment with core principles, consider:"
  echo "1. Review strategic tasks that may not explicitly connect to core principles"
  echo "2. Ensure each principle has at least one active strategic task"
  echo "3. Check if completed tasks are balanced across all three principles"
  echo
  
  log_info "Completed reflection on core principles alignment"
  return 0
}

# Function to analyze progress toward strategic goals
analyze_goals_progress() {
  log_info "Starting analysis of strategic goals progress"
  
  echo -e "${GREEN}======= Strategic Goals Progress =======${NC}"
  echo "Analyzing progress toward strategic goals on $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  
  echo "This information is presented for your analysis via Claude:"
  echo "Please review the TASKS.md file to analyze progress toward strategic goals."
  echo
  echo "Specifically:"
  echo "1. Count the total number of strategic (S-series) and implementation (T-series) tasks"
  echo "2. Identify how many of each are completed"
  echo "3. Calculate progress percentages"
  echo "4. List any blocked tasks and their dependencies"
  echo "5. Review the most recently completed tasks"
  echo
  echo "Based on this analysis, provide insights on overall progress and recommendations for next steps."
  echo
  echo "The file is available at: $TASKS_FILE"
  echo
  
  log_info "Completed analysis of strategic goals progress"
  return 0
}

# Function to review task completion patterns
review_tasks() {
  log_info "Starting review of task completion patterns"
  
  echo -e "${GREEN}======= Task Completion Patterns =======${NC}"
  echo "Analyzing task completion patterns on $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  
  echo "This information is presented for your analysis via Claude:"
  echo "Please review the TASKS.md file to analyze task completion patterns and priorities."
  echo
  echo "Specifically:"
  echo "1. Categorize tasks by priority (CRITICAL, HIGH, MEDIUM, LOW)"
  echo "2. Analyze the distribution of tasks across different priority levels"
  echo "3. Review the dependency structure between tasks"
  echo "4. Examine the acceptance criteria and test scenarios for completeness"
  echo
  echo "Based on this analysis, provide recommendations for task management improvement."
  echo
  echo "The file is available at: $TASKS_FILE"
  echo
  
  log_info "Completed review of task completion patterns"
  return 0
}

# Function to analyze codebase organization
analyze_codebase() {
  log_info "Starting analysis of codebase organization"
  
  echo -e "${GREEN}======= Codebase Organization Analysis =======${NC}"
  echo "Analyzing codebase organization on $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  
  # Count files by type (this is legitimate use of stats, not text analysis)
  local shell_scripts
  local markdown_docs
  local other_files
  
  shell_scripts=$(find "$REPO_ROOT" -name "*.sh" | wc -l)
  markdown_docs=$(find "$REPO_ROOT" -name "*.md" | wc -l)
  other_files=$(find "$REPO_ROOT" -type f -not -name "*.sh" -not -name "*.md" | wc -l)
  
  # Display file statistics
  echo -e "${BLUE}File Types:${NC}"
  echo "  Shell Scripts: $shell_scripts"
  echo "  Markdown Docs: $markdown_docs"
  echo "  Other Files: $other_files"
  echo
  
  # Analyze core system scripts
  local core_scripts
  core_scripts=$(find "$REPO_ROOT/core" -name "*.sh" | wc -l)
  
  # Analyze module scripts
  local module_scripts
  module_scripts=$(find "$REPO_ROOT/modules" -name "*.sh" | wc -l)
  
  echo -e "${BLUE}Script Distribution:${NC}"
  echo "  Core System: $core_scripts"
  echo "  Modules: $module_scripts"
  echo
  
  # Check for potential code quality issues
  echo -e "${YELLOW}Code Quality Check:${NC}"
  
  # Gather information about large scripts for Claude to analyze
  echo "This information is presented for your analysis via Claude:"
  echo "Please analyze the codebase structure and organization based on the statistics above."
  echo
  echo "Additionally, please review the core and module scripts for:"
  echo "1. Code quality issues"
  echo "2. Consistency in error handling"
  echo "3. Opportunities for refactoring"
  echo "4. Proper modularization"
  echo
  echo "Recommend specific improvements or reorganizations that would enhance code quality."
  echo
  
  log_info "Completed analysis of codebase organization"
  return 0
}

# Function to perform random reflection
random_reflection() {
  log_info "Starting random reflection"
  
  # Select a random reflection type
  local reflection_types=("principles" "goals" "tasks" "codebase")
  local random_index=$((RANDOM % 4))
  local reflection_type=${reflection_types[$random_index]}
  
  echo -e "${GREEN}======= Random Reflection =======${NC}"
  echo "Selected random reflection type: $reflection_type"
  echo
  
  case "$reflection_type" in
    principles)
      reflect_on_principles
      ;;
    goals)
      analyze_goals_progress
      ;;
    tasks)
      review_tasks
      ;;
    codebase)
      analyze_codebase
      ;;
    *)
      log_error "Invalid reflection type selected randomly"
      return 1
      ;;
  esac
  
  log_info "Completed random reflection"
  return 0
}

# Main function
main() {
  # Create or get timestamp
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Log the start of the script
  log_info "Starting self-reflection process"
  
  # Check if file exists
  if [ ! -f "$TASKS_FILE" ]; then
    log_error "Tasks file not found: $TASKS_FILE"
    return 1
  fi
  
  # Process command line arguments
  case "$1" in
    principles)
      reflect_on_principles
      ;;
    goals)
      analyze_goals_progress
      ;;
    tasks)
      review_tasks
      ;;
    codebase)
      analyze_codebase
      ;;
    random)
      random_reflection
      ;;
    help|--help|-h)
      display_help
      ;;
    *)
      # Default to random reflection if no argument provided
      if [ -z "$1" ]; then
        random_reflection
      else
        log_error "Invalid option: $1"
        display_help
        return 1
      fi
      ;;
  esac
  
  # Log completion
  log_info "Self-reflection process completed"
  return 0
}

# Run the main function and capture its return value
main "$@"
exit $?