#!/bin/bash
# Documentation health check script for the lifeform project
# This script checks the size and update status of documentation files
# to suggest when they need cleaning or summarizing

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
DOC_DIR="./docs"
ROOT_DIR="."
# Size thresholds in bytes
LARGE_FILE_THRESHOLD=5000
CRITICAL_SIZE_THRESHOLD=10000
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
  
  # Check for token tracking references (deprecated)
  echo -e "${YELLOW}Checking for deprecated token tracking references...${NC}"
  token_count=$(grep -l "token\|tracking\|token_usage\|token_report" "${DOC_FILES[@]}" | wc -l)
  if [[ $token_count -gt 0 ]]; then
    echo -e "${RED}⚠️  Deprecated token tracking references found in:${NC}"
    grep -l "token\|tracking\|token_usage\|token_report" "${DOC_FILES[@]}"
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
  *)
    check_doc_health
    echo ""
    check_duplication
    echo ""
    check_security
    ;;
esac

exit 0