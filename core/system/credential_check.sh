#!/bin/bash
# Credential security check script for the lifeform project
# This script checks for potential credential leaks in modified files
# Run before committing changes to prevent accidental credential exposure

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
DANGER_PATTERNS=(
  "password"
  "passwd"
  "USERNAME"
  "PASSWORD"
  "API_KEY"
  "API_SECRET"
  "API_TOKEN"
  "TWITTER_USERNAME"
  "TWITTER_PASSWORD"
  "TWITTER_API_KEY"
  "TWITTER_API_SECRET"
  "TWITTER_ACCESS_TOKEN"
  "TWITTER_ACCESS_SECRET"
  "TWITTER_BEARER_TOKEN"
  "BEARER_TOKEN"
  "TOKEN"
  "SECRET"
  "ACCESS_KEY"
  "ACCESS_TOKEN"
  "PRIVATE_KEY"
  "\.env"
)

# Function to check staged files for credentials
check_staged_files() {
  echo -e "${GREEN}======= Credential Security Check =======${NC}"
  echo "Checking staged files for potential credentials..."
  
  # Get list of staged files that aren't deleted
  staged_files=$(git diff --name-only --cached --diff-filter=d)
  
  if [ -z "$staged_files" ]; then
    echo "No staged files to check."
    return 0
  fi
  
  # Initialize counters
  local warning_count=0
  local detected_patterns=()
  
  # Check each staged file
  for file in $staged_files; do
    # Skip binary files, .env files, and other non-text files
    if [[ ! -f "$file" || "$(file --mime "$file" | grep -c "text")" -eq 0 || "$file" == *".env"* ]]; then
      continue
    fi
    
    # Check for danger patterns in the staged changes
    for pattern in "${DANGER_PATTERNS[@]}"; do
      # Get only the staged changes in this file
      matches=$(git diff --cached --unified=0 "$file" | grep -i "$pattern" | grep -c "^+")
      
      if [ "$matches" -gt 0 ]; then
        warning_count=$((warning_count + 1))
        detected_patterns+=("$pattern")
        echo -e "${RED}WARNING: Potential credential ($pattern) found in: $file${NC}"
        echo -e "${YELLOW}  Showing context (+ lines are additions):${NC}"
        git diff --cached --unified=3 "$file" | grep -i -A 3 -B 3 "$pattern" | grep "^+" | head -n 3
        echo ""
      fi
    done
  done
  
  # Summary
  if [ "$warning_count" -gt 0 ]; then
    echo -e "${RED}===== Security Check Summary =====${NC}"
    echo -e "${RED}⚠️  $warning_count potential credential leaks detected!${NC}"
    echo -e "${RED}Detected patterns: ${detected_patterns[*]}${NC}"
    echo -e "${YELLOW}Please review your changes carefully before committing.${NC}"
    echo -e "${YELLOW}Remember: NEVER commit credentials or secrets to the repository.${NC}"
    return 1
  else
    echo -e "${GREEN}===== Security Check Summary =====${NC}"
    echo -e "${GREEN}✅ No potential credentials detected in staged files.${NC}"
    return 0
  fi
}

# Function to scan the entire codebase for credentials
scan_codebase() {
  echo -e "${GREEN}======= Codebase Credential Scan =======${NC}"
  echo "Scanning entire codebase for potential credentials..."
  
  local warning_count=0
  local detected_files=()
  
  # Scan all tracked files (exclude .env and binaries)
  for file in $(git ls-files | grep -v "\.env"); do
    # Skip binary files and non-text files
    if [[ ! -f "$file" || "$(file --mime "$file" | grep -c "text")" -eq 0 ]]; then
      continue
    fi
    
    # Check for danger patterns
    for pattern in "${DANGER_PATTERNS[@]}"; do
      matches=$(grep -i "$pattern" "$file" | wc -l)
      
      if [ "$matches" -gt 0 ]; then
        # Check if it's in a comment or documentation (might be a false positive)
        comment_matches=$(grep -i "$pattern" "$file" | grep -c "#\|//\|/\*\|\*\|<!--|-->")
        
        if [ "$matches" -gt "$comment_matches" ]; then
          warning_count=$((warning_count + 1))
          detected_files+=("$file")
          echo -e "${YELLOW}Potential credential reference ($pattern) found in: $file${NC}"
          echo -e "${YELLOW}  First occurrence:${NC}"
          grep -i -n "$pattern" "$file" | head -n 1
          echo ""
          break  # Only report once per file
        fi
      fi
    done
  done
  
  # Summary
  if [ "$warning_count" -gt 0 ]; then
    echo -e "${YELLOW}===== Scan Summary =====${NC}"
    echo -e "${YELLOW}⚠️  $warning_count files with potential credential references detected.${NC}"
    echo -e "${YELLOW}Files to review: ${detected_files[*]}${NC}"
    echo -e "${YELLOW}Note: These might be legitimate variable references or documentation.${NC}"
    echo -e "${YELLOW}Please ensure no actual credential values are stored in these files.${NC}"
    return 1
  else
    echo -e "${GREEN}===== Scan Summary =====${NC}"
    echo -e "${GREEN}✅ No potential credentials detected in codebase.${NC}"
    return 0
  fi
}

# Main execution
case "$1" in
  "check")
    check_staged_files
    ;;
  "scan")
    scan_codebase
    ;;
  *)
    echo "Usage: $0 {check|scan}"
    echo "  check - Check staged files for potential credentials (pre-commit)"
    echo "  scan  - Scan entire codebase for potential credential references"
    ;;
esac

exit 0