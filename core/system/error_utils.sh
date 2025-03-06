#!/bin/bash
# Error handling utilities for lifeform-2
# This script provides common error handling functions for use across the system

# Directory for logs
LOG_DIR="./logs"

# Ensure log directory exists
if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR"
fi

# Function to log errors to file and stderr
log_error() {
  local error_message="$1"
  local script_name="${2:-unknown}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Make sure log directory exists
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR" 2>/dev/null || {
      echo "ERROR: Failed to create log directory" >&2
      return 1
    }
  fi
  
  # Log to file
  echo "[ERROR][$timestamp][$script_name]: $error_message" >> "$LOG_DIR/error.log"
  
  # Log to stderr
  echo "ERROR: $error_message" >&2
  
  return 0
}

# Function to log warnings
log_warning() {
  local warning_message="$1"
  local script_name="${2:-unknown}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Make sure log directory exists
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR" 2>/dev/null || {
      echo "WARNING: Failed to create log directory" >&2
      return 1
    }
  fi
  
  # Log to file
  echo "[WARNING][$timestamp][$script_name]: $warning_message" >> "$LOG_DIR/warning.log"
  
  # Log to stderr
  echo "WARNING: $warning_message" >&2
  
  return 0
}

# Function to log info messages
log_info() {
  local info_message="$1"
  local script_name="${2:-unknown}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Make sure log directory exists
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR" 2>/dev/null || {
      echo "INFO: Failed to create log directory" >&2
      return 1
    }
  fi
  
  # Log to file
  echo "[INFO][$timestamp][$script_name]: $info_message" >> "$LOG_DIR/info.log"

  # Log to stdout
  echo "INFO: $info_message"
  
  return 0
}

# Function to check command success and handle errors
check_command() {
  local exit_code=$1
  local error_message="$2"
  local script_name="${3:-unknown}"
  
  if [ $exit_code -ne 0 ]; then
    log_error "$error_message" "$script_name"
    return 1
  fi
  
  return 0
}

# Function to validate a file is readable
validate_readable() {
  local file_path="$1"
  local script_name="${2:-unknown}"
  
  if [ ! -f "$file_path" ]; then
    log_error "File not found: $file_path" "$script_name"
    return 1
  fi
  
  if [ ! -r "$file_path" ]; then
    log_error "File not readable: $file_path" "$script_name"
    return 1
  fi
  
  return 0
}

# Function to validate a file is writable
validate_writable() {
  local file_path="$1"
  local script_name="${2:-unknown}"
  
  # Check if file exists and is writable
  if [ -f "$file_path" ] && [ ! -w "$file_path" ]; then
    log_error "File not writable: $file_path" "$script_name"
    return 1
  fi
  
  # Check if parent directory exists and is writable
  local dir_path=$(dirname "$file_path")
  if [ ! -d "$dir_path" ]; then
    log_error "Directory not found: $dir_path" "$script_name"
    return 1
  fi
  
  if [ ! -w "$dir_path" ]; then
    log_error "Directory not writable: $dir_path" "$script_name"
    return 1
  fi
  
  return 0
}

# Function to validate numeric input
validate_numeric() {
  local value="$1"
  local name="$2"
  local script_name="${3:-unknown}"
  
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    log_error "$name must be a positive integer" "$script_name"
    return 1
  fi
  
  return 0
}

# Function to validate date format (YYYY-MM-DD)
validate_date_format() {
  local date_str="$1"
  local name="$2"
  local script_name="${3:-unknown}"
  
  if ! [[ "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    log_error "$name must be in format YYYY-MM-DD" "$script_name"
    return 1
  fi
  
  return 0
}

# Function to execute with proper error handling and improved security
# Usage: safe_exec "Command to run" "Error message" "Script name"
safe_exec() {
  local command="$1"
  local error_message="$2"
  local script_name="${3:-unknown}"
  
  # Security check: Reject dangerous patterns
  if [[ "$command" =~ "rm +(-rf?|--recursive|--force).*/$" || 
        "$command" =~ ":(){ " || 
        "$command" =~ "\|.*rm" || 
        "$command" =~ ">.*\/dev\/.*$" ]]; then
    log_error "Potentially destructive command rejected: $command" "$script_name"
    return 1
  fi
  
  # Log the command being executed
  log_info "Executing command: $command" "$script_name"
  
  # Execute command directly with bash -c instead of eval when possible
  local output
  output=$(bash -c "$command" 2>&1)
  local exit_code=$?
  
  # Check for errors
  if [ $exit_code -ne 0 ]; then
    log_error "$error_message: $output" "$script_name"
    return $exit_code
  fi
  
  # Return command output
  echo "$output"
  return 0
}

# Export functions for use in other scripts
export -f log_error
export -f log_warning
export -f log_info
export -f check_command
export -f validate_readable
export -f validate_writable
export -f validate_numeric
export -f validate_date_format
export -f safe_exec