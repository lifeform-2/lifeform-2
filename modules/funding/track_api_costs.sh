#!/bin/bash
# Centralized API cost tracking for lifeform-2
# This script provides a unified system for tracking API costs across all funding modules

#===================================
# CONFIGURATION AND INITIALIZATION
#===================================

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="track_api_costs.sh"

# Configuration
API_COST_LOG="./logs/api_costs.log"
API_COST_SUMMARY="./logs/api_cost_summary.json"

#===================================
# CORE FUNCTIONALITY
#===================================

# Function to initialize cost tracking system
initialize_tracking() {
  log_info "Initializing API cost tracking system..." "$SCRIPT_NAME"
  
  # Ensure logs directory exists
  if [ ! -d "./logs" ]; then
    mkdir -p "./logs" || { 
      log_error "Failed to create logs directory" "$SCRIPT_NAME"
      return 1
    }
  fi
  
  # Create API cost summary file if it doesn't exist
  if [ ! -f "$API_COST_SUMMARY" ]; then
    log_info "Creating API cost summary file" "$SCRIPT_NAME"
    
    # Create initial summary file
    cat > "$API_COST_SUMMARY" << EOF || { log_error "Failed to create API cost summary file" "$SCRIPT_NAME"; return 1; }
{
  "last_updated": "$(date +"%Y-%m-%d")",
  "monthly_tokens": {
    "Claude 3.7 Sonnet": 0,
    "Claude 3 Opus": 0,
    "Total": 0
  },
  "monthly_costs": {
    "Claude 3.7 Sonnet": 0,
    "Claude 3 Opus": 0,
    "Total": 0
  },
  "model_rates": {
    "Claude 3.7 Sonnet": 0.000003,
    "Claude 3 Opus": 0.000015,
    "Default": 0.000003
  },
  "daily_usage": {}
}
EOF
    log_info "API cost summary file created successfully" "$SCRIPT_NAME"
  }
  
  return 0
}

# Function to record API usage
# Usage: record_usage [NUM_TOKENS] [MODEL_NAME]
record_usage() {
  if [[ $# -lt 2 ]]; then
    log_error "Missing required parameters for API usage tracking" "$SCRIPT_NAME"
    log_info "Usage: record_usage [NUM_TOKENS] [MODEL_NAME]" "$SCRIPT_NAME"
    return 1
  fi
  
  tokens="$1"
  model="$2"
  date=$(date +"%Y-%m-%d")
  
  # Validate tokens is numeric
  if ! validate_numeric "$tokens" "Tokens" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Initialize tracking if necessary
  if [ ! -f "$API_COST_SUMMARY" ]; then
    if ! initialize_tracking; then
      log_error "Failed to initialize API cost tracking" "$SCRIPT_NAME"
      return 1
    fi
  fi
  
  # Record usage in the log file
  echo "[$date][$model] Tokens: $tokens" >> "$API_COST_LOG" || { 
    log_error "Failed to write to API cost log" "$SCRIPT_NAME"
    return 1
  }
  
  # Calculate cost based on model
  cost=0
  case "$model" in
    "Claude-3-7-Sonnet"|"Claude 3.7 Sonnet")
      # Cost per token for Claude 3.7 Sonnet ($3 per million tokens)
      cost=$(echo "scale=6; $tokens * 0.000003" | bc)
      model_key="Claude 3.7 Sonnet"
      ;;
    "Claude-3-Opus"|"Claude 3 Opus")
      # Cost per token for Claude 3 Opus ($15 per million tokens)
      cost=$(echo "scale=6; $tokens * 0.000015" | bc)
      model_key="Claude 3 Opus"
      ;;
    *)
      # Default cost calculation for unknown models (using Sonnet pricing)
      cost=$(echo "scale=6; $tokens * 0.000003" | bc)
      model_key="Claude 3.7 Sonnet"
      log_warning "Unknown model '$model', using default pricing" "$SCRIPT_NAME"
      ;;
  esac
  
  # Update summary file
  if [ -f "$API_COST_SUMMARY" ] && [ -w "$API_COST_SUMMARY" ]; then
    # Create a temporary file
    temp_file="${API_COST_SUMMARY}.tmp"
    
    # Extract current values
    current_tokens=$(grep -o "\"$model_key\": [0-9]*" "$API_COST_SUMMARY" | head -1 | awk '{print $2}')
    current_total_tokens=$(grep -o "\"Total\": [0-9]*" "$API_COST_SUMMARY" | head -1 | awk '{print $2}')
    current_cost=$(grep -o "\"$model_key\": [0-9.]*" "$API_COST_SUMMARY" | head -2 | tail -1 | awk '{print $2}')
    current_total_cost=$(grep -o "\"Total\": [0-9.]*" "$API_COST_SUMMARY" | tail -1 | awk '{print $2}')
    
    # If values couldn't be extracted, use defaults
    if [ -z "$current_tokens" ]; then current_tokens=0; fi
    if [ -z "$current_total_tokens" ]; then current_total_tokens=0; fi
    if [ -z "$current_cost" ]; then current_cost=0; fi
    if [ -z "$current_total_cost" ]; then current_total_cost=0; fi
    
    # Calculate new values
    new_tokens=$((current_tokens + tokens))
    new_total_tokens=$((current_total_tokens + tokens))
    new_cost=$(echo "scale=6; $current_cost + $cost" | bc)
    new_total_cost=$(echo "scale=6; $current_total_cost + $cost" | bc)
    
    # Update monthly tokens
    sed -e "s/\"$model_key\": $current_tokens/\"$model_key\": $new_tokens/g" \
        -e "s/\"Total\": $current_total_tokens/\"Total\": $new_total_tokens/g" \
        "$API_COST_SUMMARY" > "$temp_file" || { 
      log_error "Failed to update token counts in API cost summary" "$SCRIPT_NAME"
      return 1
    }
    
    # Move the temporary file to the original
    mv "$temp_file" "$API_COST_SUMMARY" || { 
      log_error "Failed to replace API cost summary with updated token counts" "$SCRIPT_NAME"
      return 1
    }
    
    # Update monthly costs
    sed -e "s/\"$model_key\": $current_cost/\"$model_key\": $new_cost/g" \
        -e "s/\"Total\": $current_total_cost/\"Total\": $new_total_cost/g" \
        -e "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$date\"/g" \
        "$API_COST_SUMMARY" > "$temp_file" || { 
      log_error "Failed to update costs in API cost summary" "$SCRIPT_NAME"
      return 1
    }
    
    # Move the temporary file to the original
    mv "$temp_file" "$API_COST_SUMMARY" || { 
      log_error "Failed to replace API cost summary with updated costs" "$SCRIPT_NAME"
      return 1
    }
    
    # Update daily usage
    if grep -q "\"$date\":" "$API_COST_SUMMARY"; then
      # Date entry exists, update it
      current_daily_tokens=$(grep -A 3 "\"$date\":" "$API_COST_SUMMARY" | grep -o "\"tokens\": [0-9]*" | awk '{print $2}')
      current_daily_cost=$(grep -A 3 "\"$date\":" "$API_COST_SUMMARY" | grep -o "\"cost\": [0-9.]*" | awk '{print $2}')
      
      # If values couldn't be extracted, use defaults
      if [ -z "$current_daily_tokens" ]; then current_daily_tokens=0; fi
      if [ -z "$current_daily_cost" ]; then current_daily_cost=0; fi
      
      # Calculate new values
      new_daily_tokens=$((current_daily_tokens + tokens))
      new_daily_cost=$(echo "scale=6; $current_daily_cost + $cost" | bc)
      
      # Update the daily entry
      awk -v date="$date" -v tokens="$new_daily_tokens" -v cost="$new_daily_cost" '
        /daily_usage/,/}/ {
          if ($0 ~ "\"" date "\":") {
            print $0;
            getline; # Skip to next line
            sub(/[0-9]+/, tokens); print;
            getline; # Skip to next line
            sub(/[0-9.]+/, cost); print;
            next;
          }
        }
        {print}
      ' "$API_COST_SUMMARY" > "$temp_file" || { 
        log_error "Failed to update daily usage in API cost summary" "$SCRIPT_NAME"
        return 1
      }
      
      # Move the temporary file to the original
      mv "$temp_file" "$API_COST_SUMMARY" || { 
        log_error "Failed to replace API cost summary with updated daily usage" "$SCRIPT_NAME"
        return 1
      }
    else
      # Date entry doesn't exist, add it
      awk -v date="$date" -v tokens="$tokens" -v cost="$cost" '
        /daily_usage/ {
          print $0;
          print "    \"" date "\": {";
          print "      \"tokens\": " tokens ",";
          print "      \"cost\": " cost;
          print "    },";
          next;
        }
        {print}
      ' "$API_COST_SUMMARY" > "$temp_file" || { 
        log_error "Failed to add daily usage in API cost summary" "$SCRIPT_NAME"
        return 1
      }
      
      # Move the temporary file to the original
      mv "$temp_file" "$API_COST_SUMMARY" || { 
        log_error "Failed to replace API cost summary with added daily usage" "$SCRIPT_NAME"
        return 1
      }
    }
    
    log_info "API usage updated: $tokens tokens ($cost cost) for $model" "$SCRIPT_NAME"
  else
    log_warning "API cost summary file not accessible, usage recorded only in log" "$SCRIPT_NAME"
  }
  
  return 0
}

# Function to generate API usage report
generate_usage_report() {
  log_info "Generating API usage report..." "$SCRIPT_NAME"
  
  # Get current date
  current_date=$(date +"%Y-%m-%d")
  output_file="./API_USAGE_REPORT_${current_date}.md"
  
  # Validate output directory is writable
  local dir_path=$(dirname "$output_file")
  if [ ! -d "$dir_path" ]; then
    log_error "Directory not found: $dir_path" "$SCRIPT_NAME"
    return 1
  fi
  
  if [ ! -w "$dir_path" ]; then
    log_error "Directory not writable: $dir_path" "$SCRIPT_NAME"
    return 1
  fi
  
  # Extract API usage data if summary file exists
  monthly_tokens_sonnet=0
  monthly_tokens_opus=0
  monthly_tokens_total=0
  monthly_cost_sonnet=0
  monthly_cost_opus=0
  monthly_cost_total=0
  
  if [ -f "$API_COST_SUMMARY" ] && [ -r "$API_COST_SUMMARY" ]; then
    monthly_tokens_sonnet=$(grep -A 5 "monthly_tokens" "$API_COST_SUMMARY" | grep -o "\"Claude 3.7 Sonnet\": [0-9]*" | awk '{print $2}')
    monthly_tokens_opus=$(grep -A 5 "monthly_tokens" "$API_COST_SUMMARY" | grep -o "\"Claude 3 Opus\": [0-9]*" | awk '{print $2}')
    monthly_tokens_total=$(grep -A 5 "monthly_tokens" "$API_COST_SUMMARY" | grep -o "\"Total\": [0-9]*" | awk '{print $2}')
    
    monthly_cost_sonnet=$(grep -A 5 "monthly_costs" "$API_COST_SUMMARY" | grep -o "\"Claude 3.7 Sonnet\": [0-9.]*" | awk '{print $2}')
    monthly_cost_opus=$(grep -A 5 "monthly_costs" "$API_COST_SUMMARY" | grep -o "\"Claude 3 Opus\": [0-9.]*" | awk '{print $2}')
    monthly_cost_total=$(grep -A 5 "monthly_costs" "$API_COST_SUMMARY" | grep -o "\"Total\": [0-9.]*" | awk '{print $2}')
  fi
  
  # Calculate daily average
  daily_average=0
  log_start_date=""
  
  if [ -f "$API_COST_LOG" ] && [ -r "$API_COST_LOG" ]; then
    # Get the earliest date from the log
    log_start_date=$(head -n 1 "$API_COST_LOG" | grep -o '\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\]' | tr -d '[]')
    
    if [ -n "$log_start_date" ]; then
      # Calculate days elapsed
      days_elapsed=$(( ($(date -j -f "%Y-%m-%d" "$current_date" +%s) - $(date -j -f "%Y-%m-%d" "$log_start_date" +%s)) / 86400 ))
      
      # Ensure we don't divide by zero
      if [ "$days_elapsed" -gt 0 ]; then
        daily_average=$(echo "scale=2; $monthly_tokens_total / $days_elapsed" | bc)
      fi
    fi
  fi
  
  # Create the report file
  cat > "$output_file" << EOF || { log_error "Failed to create API usage report file" "$SCRIPT_NAME"; return 1; }
# API Usage Transparency Report - $current_date

## Overview

This report provides transparency into the API usage and associated costs for the lifeform-2 project.

## Current Usage Statistics

- **Total Tokens Used**: $monthly_tokens_total tokens
- **Claude 3.7 Sonnet**: $monthly_tokens_sonnet tokens (\$$monthly_cost_sonnet)
- **Claude 3 Opus**: $monthly_tokens_opus tokens (\$$monthly_cost_opus)
- **Total Cost**: \$$monthly_cost_total
- **Daily Average**: $daily_average tokens per day

## Cost Breakdown

| Model | Cost Per Million Tokens | Tokens Used | Cost |
|-------|-------------------------|-------------|------|
| Claude 3.7 Sonnet | \$3.00 | $monthly_tokens_sonnet | \$$monthly_cost_sonnet |
| Claude 3 Opus | \$15.00 | $monthly_tokens_opus | \$$monthly_cost_opus |
| **Total** | | $monthly_tokens_total | \$$monthly_cost_total |

## Daily Usage Trends

EOF

  # Add daily usage data if available
  if [ -f "$API_COST_SUMMARY" ] && [ -r "$API_COST_SUMMARY" ]; then
    # Extract daily usage section
    daily_usage=$(awk '/daily_usage/,/}/ {print}' "$API_COST_SUMMARY" | grep -v "daily_usage" | grep -v "}$" | sort -r)
    
    if [ -n "$daily_usage" ]; then
      # Format as a table
      cat >> "$output_file" << EOF || { log_error "Failed to add daily usage to report" "$SCRIPT_NAME"; return 1; }
| Date | Tokens | Cost |
|------|--------|------|
EOF
      
      # Parse and add each day
      echo "$daily_usage" | grep -o "\"[0-9-]*\":" | tr -d '"' | tr -d ':' | while read -r date_entry; do
        tokens=$(grep -A 3 "\"$date_entry\":" "$API_COST_SUMMARY" | grep -o "\"tokens\": [0-9]*" | awk '{print $2}')
        cost=$(grep -A 3 "\"$date_entry\":" "$API_COST_SUMMARY" | grep -o "\"cost\": [0-9.]*" | awk '{print $2}')
        
        # Add to table
        echo "| $date_entry | $tokens | \$$cost |" >> "$output_file"
      done
    else
      cat >> "$output_file" << EOF || { log_error "Failed to add daily usage placeholder to report" "$SCRIPT_NAME"; return 1; }
No daily usage data available yet.
EOF
    fi
  else
    cat >> "$output_file" << EOF || { log_error "Failed to add daily usage placeholder to report" "$SCRIPT_NAME"; return 1; }
No daily usage data available yet.
EOF
  fi
  
  # Add recent API calls
  cat >> "$output_file" << EOF || { log_error "Failed to add recent API calls to report" "$SCRIPT_NAME"; return 1; }

## Recent API Calls

EOF

  if [ -f "$API_COST_LOG" ] && [ -r "$API_COST_LOG" ]; then
    # Get the last 10 API calls
    recent_calls=$(tail -n 10 "$API_COST_LOG")
    
    if [ -n "$recent_calls" ]; then
      cat >> "$output_file" << EOF || { log_error "Failed to add recent API calls to report" "$SCRIPT_NAME"; return 1; }
\`\`\`
$recent_calls
\`\`\`
EOF
    else
      cat >> "$output_file" << EOF || { log_error "Failed to add recent API calls placeholder to report" "$SCRIPT_NAME"; return 1; }
No recent API calls recorded.
EOF
    fi
  else
    cat >> "$output_file" << EOF || { log_error "Failed to add recent API calls placeholder to report" "$SCRIPT_NAME"; return 1; }
No API call log found.
EOF
  fi
  
  # Add transparency commitment
  cat >> "$output_file" << EOF || { log_error "Failed to add transparency commitment to report" "$SCRIPT_NAME"; return 1; }

## Transparency Commitment

The lifeform-2 project is committed to full transparency in all financial matters. This report is updated regularly to provide current information on API usage, costs, and funding allocation.

All financial decisions are made in accordance with our expense policy, which prioritizes:
1. Ensuring continued operation of the lifeform (API costs)
2. Improving core functionality (development)
3. Enhancing documentation and educational resources

Thank you to all our sponsors for supporting this project!
EOF
  
  log_info "API usage report generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

# Function to clean up old daily entries (keeping last 30 days)
cleanup_daily_entries() {
  log_info "Cleaning up old daily usage entries..." "$SCRIPT_NAME"
  
  # Validate API cost summary file exists
  if [ ! -f "$API_COST_SUMMARY" ]; then
    log_warning "API cost summary file not found, nothing to clean up" "$SCRIPT_NAME"
    return 0
  fi
  
  # Get current date and calculate date 30 days ago
  current_date=$(date +"%Y-%m-%d")
  thirty_days_ago=$(date -v -30d +"%Y-%m-%d")
  
  log_info "Removing daily usage entries older than $thirty_days_ago" "$SCRIPT_NAME"
  
  # Create a temporary file
  temp_file="${API_COST_SUMMARY}.tmp"
  
  # Extract all dates from the daily usage section
  dates=$(grep -o "\"[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\":" "$API_COST_SUMMARY" | tr -d '"' | tr -d ':')
  
  # Process each date
  for date_entry in $dates; do
    # Compare with thirty days ago
    if [[ "$date_entry" < "$thirty_days_ago" ]]; then
      log_info "Removing entry for $date_entry (older than 30 days)" "$SCRIPT_NAME"
      
      # Remove the entire entry for this date
      awk -v date="$date_entry" '
        BEGIN { skip=0; }
        $0 ~ "\"" date "\":" { skip=3; } # Skip this line and the next 3 lines
        skip > 0 { skip--; next; }
        { print; }
      ' "$API_COST_SUMMARY" > "$temp_file" || { 
        log_error "Failed to remove old daily entry for $date_entry" "$SCRIPT_NAME"
        return 1
      }
      
      # Move the temporary file to the original
      mv "$temp_file" "$API_COST_SUMMARY" || { 
        log_error "Failed to replace API cost summary after removing old entry" "$SCRIPT_NAME"
        return 1
      }
    fi
  done
  
  log_info "Daily usage cleanup completed successfully" "$SCRIPT_NAME"
  return 0
}

#===================================
# MAIN EXECUTION
#===================================

log_info "Starting API cost tracking module..." "$SCRIPT_NAME"

case "$1" in
  "init")
    initialize_tracking
    exit_code=$?
    ;;
  "record")
    if [[ $# -lt 3 ]]; then
      log_error "Missing parameters for API usage recording" "$SCRIPT_NAME"
      log_info "Usage: $0 record [NUM_TOKENS] [MODEL_NAME]" "$SCRIPT_NAME"
      exit_code=1
    else
      record_usage "$2" "$3"
      exit_code=$?
    fi
    ;;
  "report")
    generate_usage_report
    exit_code=$?
    ;;
  "cleanup")
    cleanup_daily_entries
    exit_code=$?
    ;;
  "help")
    log_info "Displaying help information" "$SCRIPT_NAME"
    echo "API Cost Tracking Module"
    echo "----------------------"
    echo "Usage: $0 {init|record|report|cleanup|help}"
    echo ""
    echo "API Cost Tracking:"
    echo "  init                        - Initialize API cost tracking"
    echo "  record [TOKENS] [MODEL]     - Record API usage"
    echo "  report                      - Generate API usage report"
    echo "  cleanup                     - Remove old daily usage entries (keep last 30 days)"
    echo ""
    echo "General:"
    echo "  help                        - Display this help information"
    exit_code=0
    ;;
  *)
    log_error "Unknown command: $1" "$SCRIPT_NAME"
    log_info "Run '$0 help' for usage information" "$SCRIPT_NAME"
    exit_code=1
    ;;
esac

log_info "API cost tracking module completed with exit code: $exit_code" "$SCRIPT_NAME"
exit $exit_code