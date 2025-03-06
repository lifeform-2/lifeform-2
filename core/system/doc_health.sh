#!/bin/bash
# Documentation health check script for the lifeform project
# This script checks the size and update status of documentation files
# to suggest when they need cleaning or summarizing

# Load error utilities for consistent error handling and logging
source "$(dirname "$0")/error_utils.sh"

# Script name for logging
SCRIPT_NAME="doc_health.sh"

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
DOC_DIR="./docs"
ROOT_DIR="."
LOG_DIR="./logs"
# Size thresholds in bytes
LARGE_FILE_THRESHOLD=10000
CRITICAL_SIZE_THRESHOLD=20000
# Log file size thresholds in bytes
LOG_WARNING_THRESHOLD=1000000  # 1MB
LOG_CRITICAL_THRESHOLD=5000000 # 5MB
# Documentation files to monitor (relative to project root)
DOC_FILES=(
  "README.md"
  "docs/GOALS.md"
  "docs/SYSTEM.md"
  "docs/TASKS.md"
  "docs/FUNDING.md"
  "docs/REPRODUCTION.md"
  "docs/COMMUNICATION.md"
  "docs/CLAUDE.md"
  "docs/TWITTER.md"
  "docs/CHANGELOG.md"
)
# Log files to monitor (relative to project root)
LOG_FILES=(
  "logs/info.log"
  "logs/error.log"
  "logs/commands_output.log"
  "logs/health_check.log"
  "logs/commit_review.log"
  "logs/security_check.log"
)

# Function to calculate file age in days
get_file_age() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local file_time=$(stat -f "%m" "$file")
    local current_time=$(date +%s)
    local age_seconds=$((current_time - file_time))
    local age_days=$((age_seconds / 86400))
    echo $age_days
  else
    echo "0"
  fi
}

# Check documentation file health
check_doc_health() {
  echo -e "${GREEN}======= Documentation Health Check =======${NC}"
  echo "Running checks on $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  
  local large_files=0
  local critical_files=0
  local old_files=0
  
  # Check each documentation file
  for doc_file in "${DOC_FILES[@]}"; do
    if [[ ! -f "$doc_file" ]]; then
      echo -e "${RED}WARNING: $doc_file does not exist!${NC}"
      continue
    fi
    
    # Get file size
    local size=$(wc -c < "$doc_file")
    local lines=$(wc -l < "$doc_file")
    local age=$(get_file_age "$doc_file")
    
    # Format output based on file size
    if [[ $size -gt $CRITICAL_SIZE_THRESHOLD ]]; then
      echo -e "${RED}$doc_file: $size bytes, $lines lines, last modified $age days ago${NC}"
      echo -e "${RED}  ⚠️  This file is critically large and should be summarized ASAP${NC}"
      critical_files=$((critical_files + 1))
    elif [[ $size -gt $LARGE_FILE_THRESHOLD ]]; then
      echo -e "${YELLOW}$doc_file: $size bytes, $lines lines, last modified $age days ago${NC}"
      echo -e "${YELLOW}  ⚠️  This file is getting large and may need summarizing soon${NC}"
      large_files=$((large_files + 1))
    else
      echo -e "${GREEN}$doc_file: $size bytes, $lines lines, last modified $age days ago${NC}"
    fi
    
    # Check for old files that haven't been updated recently
    if [[ $age -gt 30 ]]; then
      echo -e "${YELLOW}  ⚠️  This file hasn't been updated in over a month${NC}"
      old_files=$((old_files + 1))
    fi
  done
  
  echo ""
  echo -e "${GREEN}===== Documentation Health Summary =====${NC}"
  if [[ $critical_files -gt 0 ]]; then
    echo -e "${RED}$critical_files files are critically large and need immediate attention${NC}"
  fi
  if [[ $large_files -gt 0 ]]; then
    echo -e "${YELLOW}$large_files files are large and should be summarized soon${NC}"
  fi
  if [[ $old_files -gt 0 ]]; then
    echo -e "${YELLOW}$old_files files haven't been updated in over a month${NC}"
  fi
  
  if [[ $critical_files -eq 0 && $large_files -eq 0 && $old_files -eq 0 ]]; then
    echo -e "${GREEN}All documentation files are in good health!${NC}"
  fi
  
  echo ""
  echo "Recommendation: Run ./core/system/doc_health.sh before starting work"
  echo "to identify documentation that needs cleaning or summarizing."
}

# Check for duplication in documentation
check_duplication() {
  echo -e "${GREEN}======= Documentation Duplication Check =======${NC}"
  echo "Checking for common duplication patterns..."
  
  # Check for project structure duplication
  echo -e "${YELLOW}Checking for project structure duplication...${NC}"
  structure_count=$(grep -l "project structure\|directory structure\|├──\|│" "${DOC_FILES[@]}" | wc -l)
  if [[ $structure_count -gt 1 ]]; then
    echo -e "${RED}⚠️  Project structure appears in multiple files:${NC}"
    grep -l "project structure\|directory structure\|├──\|│" "${DOC_FILES[@]}"
  fi
  
  # Check for principles duplication
  echo -e "${YELLOW}Checking for core principles duplication...${NC}"
  principles_count=$(grep -l "Love of humans\|Self-preservation\|Reproduction" "${DOC_FILES[@]}" | wc -l)
  if [[ $principles_count -gt 1 ]]; then
    echo -e "${RED}⚠️  Core principles appear in multiple files:${NC}"
    grep -l "Love of humans\|Self-preservation\|Reproduction" "${DOC_FILES[@]}"
  fi
  
  # Check for obsolete functionality references
  echo -e "${YELLOW}Checking for obsolete functionality references...${NC}"
  obsolete_count=$(grep -l "token tracking\|token_tracker.sh\|token_report.sh\|token usage monitoring\|auto_commit.sh" "${DOC_FILES[@]}" | wc -l)
  if [[ $obsolete_count -gt 0 ]]; then
    echo -e "${RED}⚠️  References to obsolete functionality found in:${NC}"
    grep -l "token tracking\|token_tracker.sh\|token_report.sh\|token usage monitoring\|auto_commit.sh" "${DOC_FILES[@]}"
  fi
  
  # Check for API documentation duplication
  echo -e "${YELLOW}Checking for API documentation duplication...${NC}"
  api_count=$(grep -l "API_KEY\|API_SECRET\|ACCESS_TOKEN\|Bearer" "${DOC_FILES[@]}" | wc -l)
  if [[ $api_count -gt 1 ]]; then
    echo -e "${RED}⚠️  API documentation appears in multiple files:${NC}"
    grep -l "API_KEY\|API_SECRET\|ACCESS_TOKEN\|Bearer" "${DOC_FILES[@]}"
  fi
}

# Check for potential security issues in documentation
check_security() {
  echo -e "${GREEN}======= Documentation Security Check =======${NC}"
  echo "Checking for potential security issues..."
  
  # Check for potential API keys
  echo -e "${YELLOW}Checking for potential API keys in documentation...${NC}"
  api_key_matches=$(grep -E "[a-zA-Z0-9]{25,}" "${DOC_FILES[@]}" || true)
  if [[ -n "$api_key_matches" ]]; then
    echo -e "${RED}⚠️  Potential API keys found in documentation:${NC}"
    grep -l -E "[a-zA-Z0-9]{25,}" "${DOC_FILES[@]}"
  fi
  
  # Check for URLs with embedded credentials
  echo -e "${YELLOW}Checking for URLs with embedded credentials...${NC}"
  credential_urls=$(grep -E "https?://[^:]+:[^@]+@" "${DOC_FILES[@]}" || true)
  if [[ -n "$credential_urls" ]]; then
    echo -e "${RED}⚠️  URLs with embedded credentials found:${NC}"
    grep -l -E "https?://[^:]+:[^@]+@" "${DOC_FILES[@]}"
  fi
  
  # Check for IP addresses 
  echo -e "${YELLOW}Checking for IP addresses in documentation...${NC}"
  ip_matches=$(grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "${DOC_FILES[@]}" || true)
  if [[ -n "$ip_matches" ]]; then
    echo -e "${YELLOW}⚠️  IP addresses found in documentation (review for sensitivity):${NC}"
    grep -l -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "${DOC_FILES[@]}"
  fi
}

# Function to display documentation summarization guidelines
run_summarization() {
  local guide_file="./docs/SUMMARIZATION.md"
  
  if [[ -f "$guide_file" ]]; then
    echo -e "${GREEN}======= Documentation Summarization Guide =======${NC}"
    echo "Opening documentation summarization guidelines..."
    echo ""
    echo -e "${YELLOW}Please follow the guidelines in ${guide_file} to summarize large documents.${NC}"
    echo ""
    echo "Summary of guidelines:"
    echo "1. Create dated archives in docs/archived/ directory"
    echo "2. Retain important information and instructions"
    echo "3. Update summaries with recent key points"
    echo "4. Add references to archived content"
    echo "5. Follow document-specific guidelines for each file type"
    echo ""
    echo -e "${GREEN}For detailed instructions, review ${guide_file}${NC}"
  else
    echo -e "${RED}⚠️  Documentation summarization guide not found${NC}"
    echo "Please ensure $guide_file exists"
    return 1
  fi
}

# Self-reflection function for codebase health
self_reflection() {
  echo -e "${GREEN}======= Self-Reflection Process =======${NC}"
  echo "Performing codebase health check on $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  
  # Select a random component to review from existing directories
  # First build a list of components that actually exist
  components=()
  
  # Use absolute paths to ensure directory existence is properly checked
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  project_root="$(cd "$script_dir/../.." &>/dev/null && pwd)"
  
  for dir in "core/system" "modules/communication" "modules/funding" "docs"; do
    abs_dir="$project_root/$dir"
    if [ -d "$abs_dir" ]; then
      components+=("$dir")
    fi
  done
  
  # Get a random component
  if [ ${#components[@]} -eq 0 ]; then
    echo -e "${RED}No valid components found for review${NC}"
    return 1
  fi
  
  # Use a safer method to pick a random component
  rand_index=$(( RANDOM % ${#components[@]} ))
  random_component=${components[$rand_index]}
  
  echo -e "${YELLOW}Selected component for review: ${random_component}${NC}"
  echo ""
  
  # List files in the component
  echo -e "${GREEN}Files in this component:${NC}"
  find "$project_root/${random_component}" -type f -not -path "*/\.*" | sort
  echo ""
  
  # Check for references
  echo -e "${GREEN}Checking for references to component files...${NC}"
  echo ""
  
  # Get all files in the component
  component_files=$(find "$project_root/${random_component}" -type f -not -path "*/\.*" -name "*.sh" 2>/dev/null)
  
  if [[ -z "$component_files" ]]; then
    echo "No shell scripts found in this component."
  else
    for file in $component_files; do
      file_name=$(basename "$file")
      # Get path relative to project root
      relative_path=${file#"$project_root/"}
      
      # Check both the filename and the relative path
      # Count references to this file in other files (add more file extensions to check)
      filename_count=$(grep -l "$file_name" --include="*.sh" --include="*.md" --include="*.json" --include="*.txt" --exclude="$file" "$project_root" 2>/dev/null | wc -l)
      
      # Also check for references to the relative path
      path_count=$(find "$project_root" -type f -not -path "*/\.*" -not -path "$file" -exec grep -l "$relative_path" {} \; 2>/dev/null | wc -l)
      
      # Also check for references to the file with ./
      dot_path_count=$(find "$project_root" -type f -not -path "*/\.*" -not -path "$file" -exec grep -l "./$relative_path" {} \; 2>/dev/null | wc -l)
      
      # Sum up all references
      total_count=$((filename_count + path_count + dot_path_count))
      
      # For core system scripts, also check if they're used in run.sh which might not be detected
      # by the simple grep
      if [[ "$random_component" == "core/system" ]]; then
        if grep -q "$file_name" "$ROOT_DIR/run.sh" 2>/dev/null; then
          echo -e "${GREEN}✓ $file_name is referenced in run.sh (core component)${NC}"
          continue
        fi
      fi
      
      if [[ $total_count -eq 0 ]]; then
        # Do a final thorough check
        thorough_count=$(find . -type f -not -path "*/\.*" -not -path "$file" -exec grep -l "$file_name" {} \; 2>/dev/null | wc -l)
        if [[ $thorough_count -gt 0 ]]; then
          echo -e "${GREEN}✓ $file_name is referenced in $thorough_count files (found with thorough search)${NC}"
        else
          echo -e "${RED}⚠️  Warning: $file_name may be obsolete - no references found${NC}"
        fi
      else
        echo -e "${GREEN}✓ $file_name is referenced in $total_count files${NC}"
      fi
    done
  fi
  
  echo ""
  echo -e "${YELLOW}Reflection suggestions:${NC}"
  echo "1. Review files with no references for potential obsolescence"
  echo "2. Check component documentation for accuracy and completeness"
  echo "3. Look for duplication of functionality across components"
  echo "4. Consider if component follows current architectural principles"
  echo ""
  echo -e "${GREEN}Self-reflection is complete. Add any issues found to TASKS.md as appropriate.${NC}"
}

# Function to check log file sizes
check_logs() {
  echo -e "${GREEN}======= Log File Health Check =======${NC}"
  echo "Running checks on log files at $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  
  local large_logs=0
  local critical_logs=0
  
  # Check if logs directory exists
  if [[ ! -d "$LOG_DIR" ]]; then
    echo -e "${YELLOW}Log directory not found. No log files to check.${NC}"
    return 0
  fi
  
  # Check each log file
  for log_file in "${LOG_FILES[@]}"; do
    if [[ ! -f "$log_file" ]]; then
      # Not an error, just skip silently
      continue
    fi
    
    # Get file size
    local size=$(wc -c < "$log_file")
    local lines=$(wc -l < "$log_file")
    local age=$(get_file_age "$log_file")
    
    # Format output based on file size
    if [[ $size -gt $LOG_CRITICAL_THRESHOLD ]]; then
      echo -e "${RED}$log_file: $size bytes, $lines lines, last modified $age days ago${NC}"
      echo -e "${RED}  ⚠️  This log file is critically large and should be truncated${NC}"
      critical_logs=$((critical_logs + 1))
    elif [[ $size -gt $LOG_WARNING_THRESHOLD ]]; then
      echo -e "${YELLOW}$log_file: $size bytes, $lines lines, last modified $age days ago${NC}"
      echo -e "${YELLOW}  ⚠️  This log file is getting large and should be monitored${NC}"
      large_logs=$((large_logs + 1))
    else
      echo -e "${GREEN}$log_file: $size bytes, $lines lines, last modified $age days ago${NC}"
    fi
  done
  
  echo ""
  echo -e "${GREEN}===== Log File Health Summary =====${NC}"
  if [[ $critical_logs -gt 0 ]]; then
    echo -e "${RED}$critical_logs log files are critically large and need attention${NC}"
    echo -e "${RED}Consider manually truncating these files or adjusting truncation thresholds in run.sh${NC}"
  fi
  if [[ $large_logs -gt 0 ]]; then
    echo -e "${YELLOW}$large_logs log files are large and should be monitored${NC}"
  fi
  
  if [[ $critical_logs -eq 0 && $large_logs -eq 0 ]]; then
    echo -e "${GREEN}All log files are in good health!${NC}"
  fi
  
  echo ""
  echo "Logs are automatically truncated by run.sh when they exceed size thresholds."
}

# Main execution
case "$1" in
  "health")
    check_doc_health
    ;;
  "duplication")
    check_duplication
    ;;
  "security")
    check_security
    ;;
  "summarize")
    run_summarization
    ;;
  "self-reflect")
    self_reflection
    ;;
  "logs")
    check_logs
    ;;
  *)
    check_doc_health
    echo ""
    check_duplication
    echo ""
    check_security
    echo ""
    check_logs
    
    # If large files are detected, suggest running summarization
    if [[ $critical_files -gt 0 || $large_files -gt 0 ]]; then
      echo ""
      echo -e "${YELLOW}Consider running document summarization to clean up large files:${NC}"
      echo "./core/system/doc_health.sh summarize"
    fi
    ;;
esac

exit 0