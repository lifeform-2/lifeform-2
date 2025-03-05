#!/bin/bash
# Token usage tracking system for lifeform-2
# This script tracks API token usage and estimates costs

# Constants for token pricing (as of 2025-03-05)
# Update these values if pricing changes
CLAUDE_INPUT_PRICE_PER_1K=0.008  # $0.008 per 1K tokens
CLAUDE_OUTPUT_PRICE_PER_1K=0.024 # $0.024 per 1K tokens

# File to store token usage data
USAGE_FILE="./logs/token_usage.csv"

# Initialize usage file if it doesn't exist
initialize_usage_file() {
  if [ ! -f "$USAGE_FILE" ]; then
    mkdir -p ./logs
    echo "date,session_id,input_tokens,output_tokens,estimated_cost" > "$USAGE_FILE"
    echo "Usage tracking initialized."
  fi
}

# Function to log token usage
log_usage() {
  if [[ $# -lt 3 ]]; then
    echo "Usage: $0 log [SESSION_ID] [INPUT_TOKENS] [OUTPUT_TOKENS]"
    return 1
  fi
  
  initialize_usage_file
  
  session_id=$1
  input_tokens=$2
  output_tokens=$3
  
  # Calculate estimated cost
  input_cost=$(echo "scale=6; $input_tokens * $CLAUDE_INPUT_PRICE_PER_1K / 1000" | bc)
  output_cost=$(echo "scale=6; $output_tokens * $CLAUDE_OUTPUT_PRICE_PER_1K / 1000" | bc)
  total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc)
  
  # Log to file
  echo "$(date +"%Y-%m-%d"),$session_id,$input_tokens,$output_tokens,$total_cost" >> "$USAGE_FILE"
  
  echo "Token usage logged: $input_tokens input, $output_tokens output, \$$total_cost estimated cost"
}

# Function to get total usage statistics
get_total_usage() {
  if [ ! -f "$USAGE_FILE" ]; then
    echo "No usage data found."
    return 1
  fi
  
  # Skip header row, then sum columns
  total_input=$(tail -n +2 "$USAGE_FILE" | cut -d',' -f3 | paste -sd+ | bc)
  total_output=$(tail -n +2 "$USAGE_FILE" | cut -d',' -f4 | paste -sd+ | bc)
  total_cost=$(tail -n +2 "$USAGE_FILE" | cut -d',' -f5 | paste -sd+ | bc)
  
  if [ -z "$total_input" ]; then
    total_input=0
    total_output=0
    total_cost=0
  fi
  
  echo "Total token usage:"
  echo "Input tokens: $total_input"
  echo "Output tokens: $total_output"
  echo "Estimated cost: \$$total_cost"
}

# Function to get usage for a specific date range
get_usage_by_date() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 date-range [START_DATE] [END_DATE]"
    echo "Date format: YYYY-MM-DD"
    return 1
  fi
  
  if [ ! -f "$USAGE_FILE" ]; then
    echo "No usage data found."
    return 1
  fi
  
  start_date=$1
  end_date=$2
  
  echo "Token usage from $start_date to $end_date:"
  
  # Filter by date range and sum
  awk -F, -v start="$start_date" -v end="$end_date" '
    NR > 1 && $1 >= start && $1 <= end {
      input_sum += $3;
      output_sum += $4;
      cost_sum += $5;
    }
    END {
      print "Input tokens: " input_sum;
      print "Output tokens: " output_sum;
      print "Estimated cost: $" cost_sum;
    }
  ' "$USAGE_FILE"
}

# Function to estimate cost for a given number of tokens
estimate_cost() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 estimate [INPUT_TOKENS] [OUTPUT_TOKENS]"
    return 1
  fi
  
  input_tokens=$1
  output_tokens=$2
  
  # Calculate estimated cost
  input_cost=$(echo "scale=6; $input_tokens * $CLAUDE_INPUT_PRICE_PER_1K / 1000" | bc)
  output_cost=$(echo "scale=6; $output_tokens * $CLAUDE_OUTPUT_PRICE_PER_1K / 1000" | bc)
  total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc)
  
  echo "Estimated cost for $input_tokens input tokens and $output_tokens output tokens:"
  echo "Input cost: \$$input_cost"
  echo "Output cost: \$$output_cost"
  echo "Total cost: \$$total_cost"
}

# Main execution
case "$1" in
  "init")
    initialize_usage_file
    ;;
  "log")
    log_usage "$2" "$3" "$4"
    ;;
  "total")
    get_total_usage
    ;;
  "date-range")
    get_usage_by_date "$2" "$3"
    ;;
  "estimate")
    estimate_cost "$2" "$3"
    ;;
  *)
    echo "Usage: $0 {init|log|total|date-range|estimate}"
    echo "  init                    - Initialize usage tracking file"
    echo "  log [ID] [IN] [OUT]     - Log usage for session ID with IN input and OUT output tokens"
    echo "  total                   - Show total usage statistics"
    echo "  date-range [S] [E]      - Show usage between start date S and end date E (YYYY-MM-DD)"
    echo "  estimate [IN] [OUT]     - Estimate cost for IN input and OUT output tokens"
    exit 1
    ;;
esac

exit 0