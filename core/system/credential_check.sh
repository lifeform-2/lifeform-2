#!/bin/bash
# Credential security check script for the lifeform project
# This script checks for potential credential leaks in modified files
# Run before committing changes to prevent accidental credential exposure

# Load error utilities for consistent error handling and logging
source "$(dirname "$0")/error_utils.sh"

# Script name for logging
SCRIPT_NAME="credential_check.sh"

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

# Security risk patterns
SECURITY_PATTERNS=(
  # Command injection risks
  "eval[ ]*\("
  "exec[ ]*\("
  "system[ ]*\("
  "\`.*\`"
  # Injection patterns
  "sql[ ]*="
  "query[ ]*="
  # Permissions/path issues
  "chmod[ ]+777"
  "0777"
  # Potential hardcoded secrets
  "[\"']-----BEGIN[ ]*(PRIVATE|RSA|DSA)"
  "[0-9a-fA-F]{32,}"
  "github_pat_"
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

# Function to scan the codebase for potential security issues
security_scan() {
  echo -e "${GREEN}======= Comprehensive Security Scan =======${NC}"
  echo "Scanning codebase for potential security vulnerabilities..."
  
  local issue_count=0
  local security_files=()
  
  # Scan all tracked files (exclude binaries and certain file types)
  for file in $(git ls-files | grep -v "\.jpg$\|\.png$\|\.gif$\|\.env\|\.md$"); do
    # Skip binary files and non-text files
    if [[ ! -f "$file" || "$(file --mime "$file" | grep -c "text")" -eq 0 ]]; then
      continue
    fi
    
    # Only scan shell and code files
    if [[ "$file" != *".sh" && "$file" != *".js" && "$file" != *".py" && "$file" != *".php" ]]; then
      continue
    fi
    
    # Check for security patterns
    local file_has_issues=0
    
    for pattern in "${SECURITY_PATTERNS[@]}"; do
      matches=$(grep -E "$pattern" "$file" | wc -l)
      
      if [ "$matches" -gt 0 ]; then
        # Check if it's in a comment (might be a false positive)
        comment_matches=$(grep -E "$pattern" "$file" | grep -c "#\|//\|/\*\|\*")
        
        if [ "$matches" -gt "$comment_matches" ]; then
          if [ "$file_has_issues" -eq 0 ]; then
            echo -e "${YELLOW}Potential security issue in: $file${NC}"
            file_has_issues=1
            issue_count=$((issue_count + 1))
            security_files+=("$file")
          fi
          
          echo -e "${YELLOW}  Pattern: $pattern${NC}"
          echo -e "${YELLOW}  Occurrences:${NC}"
          grep -E -n "$pattern" "$file" | head -n 2
        fi
      fi
    done
    
    # Additional shell script specific checks
    if [[ "$file" == *".sh" ]]; then
      # Check for shellcheck warnings if shellcheck is installed
      if command -v shellcheck &> /dev/null; then
        shellcheck_output=$(shellcheck -s bash -f gcc "$file" 2>&1)
        shellcheck_count=$(echo "$shellcheck_output" | wc -l)
        
        if [ "$shellcheck_count" -gt 1 ]; then
          if [ "$file_has_issues" -eq 0 ]; then
            echo -e "${YELLOW}Shell script issues in: $file${NC}"
            file_has_issues=1
            issue_count=$((issue_count + 1))
            security_files+=("$file")
          fi
          
          echo -e "${YELLOW}  ShellCheck warnings:${NC}"
          echo "$shellcheck_output" | head -n 5
          echo ""
        fi
      fi
    fi
    
    if [ "$file_has_issues" -eq 1 ]; then
      echo ""
    fi
  done
  
  # Check for any dangling .env files that might have been accidentally committed
  env_files=$(git ls-files | grep "\.env$") 
  if [ -n "$env_files" ]; then
    echo -e "${RED}⚠️  WARNING: .env files found in repository!${NC}"
    echo -e "${RED}  These files might contain credentials and should not be committed:${NC}"
    echo "$env_files"
    echo ""
    issue_count=$((issue_count + 1))
  fi
  
  # Check for potentially dangerous file permissions
  world_writable=$(find . -type f -perm -002 -not -path "*/\.git/*" | grep -v "node_modules" | head -n 10)
  if [ -n "$world_writable" ]; then
    echo -e "${YELLOW}⚠️  World-writable files detected:${NC}"
    echo "$world_writable"
    echo ""
    issue_count=$((issue_count + 1))
  fi
  
  # Summary
  if [ "$issue_count" -gt 0 ]; then
    echo -e "${YELLOW}===== Security Scan Summary =====${NC}"
    echo -e "${YELLOW}⚠️  $issue_count potential security issues detected.${NC}"
    echo -e "${YELLOW}Files to review: ${security_files[*]}${NC}"
    echo -e "${YELLOW}Recommendations:${NC}"
    echo -e "${YELLOW}  - Review all identified files for potential security vulnerabilities${NC}"
    echo -e "${YELLOW}  - Avoid using eval, exec, or system commands with unsanitized input${NC}"
    echo -e "${YELLOW}  - Check for command injection, path traversal, and insecure permissions${NC}"
    echo -e "${YELLOW}  - Install shellcheck for better shell script security analysis${NC}"
    return 1
  else
    echo -e "${GREEN}===== Security Scan Summary =====${NC}"
    echo -e "${GREEN}✅ No potential security issues detected in codebase.${NC}"
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
  "security")
    security_scan
    ;;
  "full")
    echo -e "${GREEN}======= Running Full Security Audit =======${NC}"
    scan_codebase
    echo ""
    security_scan
    ;;
  *)
    echo "Usage: $0 {check|scan|security|full}"
    echo "  check    - Check staged files for potential credentials (pre-commit)"
    echo "  scan     - Scan entire codebase for potential credential references"
    echo "  security - Run comprehensive security vulnerability scan"
    echo "  full     - Run both credential and security scans"
    ;;
esac

exit 0