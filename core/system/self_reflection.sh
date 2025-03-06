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
reflect_on_principles() {
  log_info "Starting reflection on core principles alignment"
  
  echo -e "${GREEN}======= Core Principles Reflection =======${NC}"
  echo "Analyzing alignment with core principles on $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  
  # Read core principles from README
  local readme_content
  readme_content=$(cat "$REPO_ROOT/README.md")
  
  # Extract core principles and display them
  echo -e "${BLUE}Core Principles:${NC}"
  echo -e "${CYAN}1. Love of humans and humanity${NC}"
  echo -e "${CYAN}2. Self-preservation${NC}"
  echo -e "${CYAN}3. Reproduction${NC}"
  echo
  
  # Analyze tasks for principle alignment
  echo -e "${YELLOW}Analyzing strategic tasks for principle alignment...${NC}"
  
  # Get strategic tasks from TASKS.md
  local strategic_tasks
  strategic_tasks=$(grep -A5 "^S[0-9]" "$TASKS_FILE")
  
  # Check principle 1: Love of humans and humanity
  echo -e "${BLUE}Love of humans and humanity:${NC}"
  grep -i "human\|humanity\|interaction\|communication" "$TASKS_FILE" | grep "^S" | head -n 3
  echo
  
  # Check principle 2: Self-preservation
  echo -e "${BLUE}Self-preservation:${NC}"
  grep -i "preservation\|health\|monitoring\|security" "$TASKS_FILE" | grep "^S" | head -n 3
  echo
  
  # Check principle 3: Reproduction
  echo -e "${BLUE}Reproduction:${NC}"
  grep -i "reproduction\|fork\|identity\|lineage" "$TASKS_FILE" | grep "^S" | head -n 3
  echo
  
  # Provide suggestions for better alignment
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
  
  # Count total strategic and implementation tasks
  local total_strategic
  local completed_strategic
  local total_implementation
  local completed_implementation
  
  total_strategic=$(grep -c "^S[0-9]" "$TASKS_FILE" || echo 0)
  completed_strategic=$(grep "^S[0-9].*COMPLETED" "$TASKS_FILE" | wc -l)
  total_implementation=$(grep -c "^T[0-9]" "$TASKS_FILE" || echo 0)
  completed_implementation=$(grep "^T[0-9].*COMPLETED" "$TASKS_FILE" | wc -l)
  
  # Calculate progress percentages
  local strategic_progress
  local implementation_progress
  
  if [ "$total_strategic" -gt 0 ]; then
    strategic_progress=$((completed_strategic * 100 / total_strategic))
  else
    strategic_progress=0
  fi
  
  if [ "$total_implementation" -gt 0 ]; then
    implementation_progress=$((completed_implementation * 100 / total_implementation))
  else
    implementation_progress=0
  fi
  
  # Display progress
  echo -e "${BLUE}Strategic Tasks Progress:${NC} $completed_strategic of $total_strategic ($strategic_progress%)"
  echo -e "${BLUE}Implementation Tasks Progress:${NC} $completed_implementation of $total_implementation ($implementation_progress%)"
  echo
  
  # Analyze blocked tasks
  local blocked_tasks
  blocked_tasks=$(grep "BLOCKED" "$TASKS_FILE" | wc -l)
  
  echo -e "${YELLOW}Blocked Tasks:${NC} $blocked_tasks"
  echo
  
  # List most recent completed tasks
  echo -e "${GREEN}Recent Completed Tasks:${NC}"
  grep "COMPLETED" "$TASKS_FILE" | grep "^T[0-9]" | head -n 3
  echo
  
  # Provide insight on progress
  echo -e "${GREEN}===== Progress Insights =====${NC}"
  
  if [ "$implementation_progress" -lt 50 ]; then
    echo "Progress on implementation tasks is below 50%. Consider focusing on completing active tasks."
  else
    echo "Good progress on implementation tasks. Consider defining new tasks to continue evolution."
  fi
  
  if [ "$blocked_tasks" -gt 0 ]; then
    echo "There are $blocked_tasks blocked tasks. Review dependencies and external requirements."
  fi
  
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
  
  # Analyze completed tasks
  local completed_count
  completed_count=$(grep -c "COMPLETED" "$TASKS_FILE" || echo 0)
  
  # Analyze tasks by priority
  local critical_tasks
  local high_tasks
  local medium_tasks
  local low_tasks
  
  critical_tasks=$(grep -c "CRITICAL" "$TASKS_FILE" || echo 0)
  high_tasks=$(grep -c "HIGH" "$TASKS_FILE" || echo 0)
  medium_tasks=$(grep -c "MEDIUM" "$TASKS_FILE" || echo 0)
  low_tasks=$(grep -c "LOW" "$TASKS_FILE" || echo 0)
  
  # Display task statistics
  echo -e "${BLUE}Task Completion:${NC} $completed_count tasks completed"
  echo -e "${BLUE}Task Priorities:${NC}"
  echo "  Critical: $critical_tasks"
  echo "  High: $high_tasks"
  echo "  Medium: $medium_tasks"
  echo "  Low: $low_tasks"
  echo
  
  # Analyze task dependencies
  local tasks_with_dependencies
  tasks_with_dependencies=$(grep -c "Dependencies:" "$TASKS_FILE" || echo 0)
  
  echo -e "${YELLOW}Tasks with Dependencies:${NC} $tasks_with_dependencies"
  echo
  
  # Provide task management suggestions
  echo -e "${GREEN}===== Task Management Suggestions =====${NC}"
  
  if [ "$critical_tasks" -gt 3 ]; then
    echo "There are many critical tasks. Consider re-evaluating priorities."
  fi
  
  if [ "$low_tasks" -eq 0 ]; then
    echo "No low-priority tasks found. Consider adding exploratory or improvement tasks."
  fi
  
  echo "Ensure all tasks have clear acceptance criteria and test scenarios."
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
  
  # Count files by type
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
  
  # Check for large scripts (> 200 lines)
  local large_scripts
  large_scripts=$(find "$REPO_ROOT" -name "*.sh" -exec wc -l {} \; | awk '$1 > 200 {print $2}')
  
  if [ -n "$large_scripts" ]; then
    echo "Large scripts detected (>200 lines):"
    echo "$large_scripts"
  else
    echo "No excessively large scripts detected."
  fi
  echo
  
  # Provide codebase suggestions
  echo -e "${GREEN}===== Codebase Suggestions =====${NC}"
  
  if [ "$core_scripts" -gt "$module_scripts" ]; then
    echo "More scripts in core than in modules. Consider modularizing functionality."
  fi
  
  echo "Maintain consistent error handling across all scripts."
  echo "Review scripts regularly for opportunities to refactor and improve."
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