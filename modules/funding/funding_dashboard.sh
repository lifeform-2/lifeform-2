#!/bin/bash
# Unified Funding Dashboard for lifeform-2
# This script integrates financial data from all funding platforms to provide a comprehensive view

#===================================
# CONFIGURATION AND INITIALIZATION
#===================================

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="funding_dashboard.sh"

# Configuration
SPONSORS_FILE="./sponsors.json"
KOFI_CONFIG="./kofi_config.json"
OPENCOLL_CONFIG="./opencollective_config.json"
API_COST_SUMMARY="./logs/api_cost_summary.json"
API_COST_LOG="./logs/api_costs.log"
DASHBOARD_OUTPUT="./FUNDING_DASHBOARD.md"

#===================================
# HELPER FUNCTIONS
#===================================

# Function to validate required files exist
validate_required_files() {
  log_info "Validating required files..." "$SCRIPT_NAME"
  local missing_files=0
  
  # Check for either the unified API cost tracking or any of the platform-specific files
  if [ ! -f "$API_COST_SUMMARY" ] && [ ! -f "$SPONSORS_FILE" ] && [ ! -f "$KOFI_CONFIG" ] && [ ! -f "$OPENCOLL_CONFIG" ]; then
    log_error "No funding data sources available. Initialize at least one funding platform first." "$SCRIPT_NAME"
    return 1
  fi
  
  # API Cost tracking is not required but preferred
  if [ ! -f "$API_COST_SUMMARY" ]; then
    log_warning "API cost summary file not found. Some dashboard sections will be incomplete." "$SCRIPT_NAME"
  fi
  
  # Log platforms that are available
  local platforms=""
  if [ -f "$SPONSORS_FILE" ]; then platforms="$platforms GitHub Sponsors"; fi
  if [ -f "$KOFI_CONFIG" ]; then platforms="$platforms Ko-fi"; fi
  if [ -f "$OPENCOLL_CONFIG" ]; then platforms="$platforms Open Collective"; fi
  
  log_info "Found funding platforms:$platforms" "$SCRIPT_NAME"
  return 0
}

# Function to extract token data from API cost tracking
extract_token_data() {
  log_info "Extracting token usage data..." "$SCRIPT_NAME"
  
  # Initialize default values
  total_tokens=0
  sonnet_tokens=0
  opus_tokens=0
  total_cost=0
  sonnet_cost=0
  opus_cost=0
  daily_average=0
  
  # Extract data from API cost summary if available
  if [ -f "$API_COST_SUMMARY" ] && [ -r "$API_COST_SUMMARY" ]; then
    # Extract token counts
    sonnet_tokens=$(grep -A 5 "monthly_tokens" "$API_COST_SUMMARY" | grep -o "\"Claude 3.7 Sonnet\": [0-9]*" | awk '{print $2}')
    opus_tokens=$(grep -A 5 "monthly_tokens" "$API_COST_SUMMARY" | grep -o "\"Claude 3 Opus\": [0-9]*" | awk '{print $2}')
    total_tokens=$(grep -A 5 "monthly_tokens" "$API_COST_SUMMARY" | grep -o "\"Total\": [0-9]*" | awk '{print $2}')
    
    # Extract costs
    sonnet_cost=$(grep -A 5 "monthly_costs" "$API_COST_SUMMARY" | grep -o "\"Claude 3.7 Sonnet\": [0-9.]*" | awk '{print $2}')
    opus_cost=$(grep -A 5 "monthly_costs" "$API_COST_SUMMARY" | grep -o "\"Claude 3 Opus\": [0-9.]*" | awk '{print $2}')
    total_cost=$(grep -A 5 "monthly_costs" "$API_COST_SUMMARY" | grep -o "\"Total\": [0-9.]*" | awk '{print $2}')
    
    # If not found, set defaults
    if [ -z "$sonnet_tokens" ]; then sonnet_tokens=0; fi
    if [ -z "$opus_tokens" ]; then opus_tokens=0; fi
    if [ -z "$total_tokens" ]; then total_tokens=0; fi
    if [ -z "$sonnet_cost" ]; then sonnet_cost=0; fi
    if [ -z "$opus_cost" ]; then opus_cost=0; fi
    if [ -z "$total_cost" ]; then total_cost=0; fi
    
    # Calculate daily average if possible
    if [ -f "$API_COST_LOG" ] && [ -r "$API_COST_LOG" ]; then
      # Get the earliest date from the log
      current_date=$(date +"%Y-%m-%d")
      log_start_date=$(head -n 1 "$API_COST_LOG" | grep -o '\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\]' | tr -d '[]')
      
      if [ -n "$log_start_date" ]; then
        # Calculate days elapsed
        days_elapsed=$(( ($(date -j -f "%Y-%m-%d" "$current_date" +%s) - $(date -j -f "%Y-%m-%d" "$log_start_date" +%s)) / 86400 ))
        
        # Ensure we don't divide by zero
        if [ "$days_elapsed" -gt 0 ]; then
          daily_average=$(echo "scale=2; $total_tokens / $days_elapsed" | bc)
        fi
      fi
    fi
  else
    log_warning "API cost summary file not available or not readable. Using default values." "$SCRIPT_NAME"
  fi
  
  log_info "Token data extracted successfully" "$SCRIPT_NAME"
}

# Function to extract funding data from various platforms
extract_funding_data() {
  log_info "Extracting funding data from platforms..." "$SCRIPT_NAME"
  
  # Initialize values
  total_funding=0
  github_funding=0
  kofi_funding=0
  opencoll_funding=0
  num_sponsors=0
  
  # Extract GitHub Sponsors data if available
  if [ -f "$SPONSORS_FILE" ] && [ -r "$SPONSORS_FILE" ]; then
    github_funding=$(grep -o '"total_funding": [0-9.]*' "$SPONSORS_FILE" | awk '{print $2}')
    github_sponsors=$(grep -o '"active_sponsors": [0-9]*' "$SPONSORS_FILE" | awk '{print $2}')
    
    if [ -n "$github_funding" ]; then 
      total_funding=$(echo "scale=2; $total_funding + $github_funding" | bc)
    fi
    
    if [ -n "$github_sponsors" ]; then 
      num_sponsors=$((num_sponsors + github_sponsors))
    fi
  else
    log_info "GitHub Sponsors configuration not found" "$SCRIPT_NAME"
  fi
  
  # Extract Ko-fi data if available
  if [ -f "$KOFI_CONFIG" ] && [ -r "$KOFI_CONFIG" ]; then
    kofi_funding=$(grep -o '"total_funding": [0-9.]*' "$KOFI_CONFIG" | awk '{print $2}')
    kofi_sponsors=$(grep -o '"active_sponsors": [0-9]*' "$KOFI_CONFIG" | awk '{print $2}')
    
    if [ -n "$kofi_funding" ]; then 
      total_funding=$(echo "scale=2; $total_funding + $kofi_funding" | bc)
    fi
    
    if [ -n "$kofi_sponsors" ]; then 
      num_sponsors=$((num_sponsors + kofi_sponsors))
    fi
  else
    log_info "Ko-fi configuration not found" "$SCRIPT_NAME"
  fi
  
  # Extract Open Collective data if available
  if [ -f "$OPENCOLL_CONFIG" ] && [ -r "$OPENCOLL_CONFIG" ]; then
    opencoll_funding=$(grep -o '"total_funding": [0-9.]*' "$OPENCOLL_CONFIG" | awk '{print $2}')
    opencoll_sponsors=$(grep -o '"active_sponsors": [0-9]*' "$OPENCOLL_CONFIG" | awk '{print $2}')
    
    if [ -n "$opencoll_funding" ]; then 
      total_funding=$(echo "scale=2; $total_funding + $opencoll_funding" | bc)
    fi
    
    if [ -n "$opencoll_sponsors" ]; then 
      num_sponsors=$((num_sponsors + opencoll_sponsors))
    fi
  else
    log_info "Open Collective configuration not found" "$SCRIPT_NAME"
  fi
  
  # If no funding data was found, set defaults
  if [ -z "$total_funding" ]; then total_funding=0; fi
  if [ -z "$github_funding" ]; then github_funding=0; fi
  if [ -z "$kofi_funding" ]; then kofi_funding=0; fi
  if [ -z "$opencoll_funding" ]; then opencoll_funding=0; fi
  if [ -z "$num_sponsors" ]; then num_sponsors=0; fi
  
  log_info "Funding data extracted successfully" "$SCRIPT_NAME"
}

# Function to calculate months of runway based on current funding and burn rate
calculate_runway() {
  log_info "Calculating financial runway..." "$SCRIPT_NAME"
  
  # Initialize values
  runway_months=0
  monthly_burn=0
  
  # Calculate monthly burn rate based on API costs if available
  if [ -f "$API_COST_SUMMARY" ] && [ -r "$API_COST_SUMMARY" ]; then
    # Get the earliest date from the log to calculate monthly average
    if [ -f "$API_COST_LOG" ] && [ -r "$API_COST_LOG" ]; then
      current_date=$(date +"%Y-%m-%d")
      log_start_date=$(head -n 1 "$API_COST_LOG" | grep -o '\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\]' | tr -d '[]')
      
      if [ -n "$log_start_date" ]; then
        # Calculate days elapsed
        days_elapsed=$(( ($(date -j -f "%Y-%m-%d" "$current_date" +%s) - $(date -j -f "%Y-%m-%d" "$log_start_date" +%s)) / 86400 ))
        
        # Ensure we don't divide by zero
        if [ "$days_elapsed" -gt 0 ]; then
          # Calculate monthly burn rate (assuming 30 days per month)
          monthly_burn=$(echo "scale=2; $total_cost / $days_elapsed * 30" | bc)
          
          # Calculate runway in months (if burn rate is positive)
          if (( $(echo "$monthly_burn > 0" | bc -l) )); then
            runway_months=$(echo "scale=1; $total_funding / $monthly_burn" | bc)
          else
            runway_months="∞"
          fi
        fi
      fi
    else
      log_warning "API cost log not available. Cannot calculate accurate burn rate." "$SCRIPT_NAME"
    fi
  else
    log_warning "API cost summary not available. Cannot calculate runway." "$SCRIPT_NAME"
  fi
  
  # If we couldn't calculate the runway, use a default value
  if [ -z "$runway_months" ]; then runway_months="Unknown"; fi
  if [ -z "$monthly_burn" ]; then monthly_burn=0; fi
  
  log_info "Runway calculation complete" "$SCRIPT_NAME"
}

#===================================
# DASHBOARD GENERATION FUNCTIONS
#===================================

# Function to generate funding overview section
generate_overview_section() {
  log_info "Generating funding overview section..." "$SCRIPT_NAME"
  
  # Format current date
  current_date=$(date +"%Y-%m-%d")
  
  cat >> "$DASHBOARD_OUTPUT" << EOF || { log_error "Failed to write overview section" "$SCRIPT_NAME"; return 1; }
# Lifeform-2 Funding Dashboard

*Generated on: $current_date*

## Overview

| Metric | Value |
|--------|-------|
| Total Funding | \$$total_funding |
| Number of Sponsors | $num_sponsors |
| Monthly Burn Rate | \$$monthly_burn |
| Financial Runway | $runway_months months |
| Total API Cost | \$$total_cost |
| Daily Average Usage | $daily_average tokens |

EOF
  
  log_info "Overview section generated successfully" "$SCRIPT_NAME"
  return 0
}

# Function to generate funding breakdown section
generate_funding_breakdown() {
  log_info "Generating funding breakdown section..." "$SCRIPT_NAME"
  
  cat >> "$DASHBOARD_OUTPUT" << EOF || { log_error "Failed to write funding breakdown section" "$SCRIPT_NAME"; return 1; }
## Funding Sources

| Platform | Amount | Percentage |
|----------|--------|------------|
EOF
  
  # Calculate percentages (protect against division by zero)
  if (( $(echo "$total_funding > 0" | bc -l) )); then
    github_percent=$(echo "scale=1; $github_funding / $total_funding * 100" | bc)
    kofi_percent=$(echo "scale=1; $kofi_funding / $total_funding * 100" | bc)
    opencoll_percent=$(echo "scale=1; $opencoll_funding / $total_funding * 100" | bc)
  else
    github_percent=0
    kofi_percent=0
    opencoll_percent=0
  fi
  
  # Add platform data if available
  if [ -f "$SPONSORS_FILE" ]; then
    echo "| GitHub Sponsors | \$$github_funding | ${github_percent}% |" >> "$DASHBOARD_OUTPUT"
  fi
  
  if [ -f "$KOFI_CONFIG" ]; then
    echo "| Ko-fi | \$$kofi_funding | ${kofi_percent}% |" >> "$DASHBOARD_OUTPUT"
  fi
  
  if [ -f "$OPENCOLL_CONFIG" ]; then
    echo "| Open Collective | \$$opencoll_funding | ${opencoll_percent}% |" >> "$DASHBOARD_OUTPUT"
  fi
  
  # Add total row
  echo "| **Total** | \$$total_funding | 100% |" >> "$DASHBOARD_OUTPUT"
  
  # Add empty line
  echo "" >> "$DASHBOARD_OUTPUT"
  
  log_info "Funding breakdown section generated successfully" "$SCRIPT_NAME"
  return 0
}

# Function to generate API usage section
generate_api_usage_section() {
  log_info "Generating API usage section..." "$SCRIPT_NAME"
  
  cat >> "$DASHBOARD_OUTPUT" << EOF || { log_error "Failed to write API usage section" "$SCRIPT_NAME"; return 1; }
## API Usage

| Model | Tokens | Cost |
|-------|--------|------|
| Claude 3.7 Sonnet | $sonnet_tokens | \$$sonnet_cost |
| Claude 3 Opus | $opus_tokens | \$$opus_cost |
| **Total** | $total_tokens | \$$total_cost |

EOF
  
  # Add daily usage trends if available
  if [ -f "$API_COST_SUMMARY" ] && [ -r "$API_COST_SUMMARY" ]; then
    # Extract daily usage section
    daily_usage=$(awk '/daily_usage/,/}/ {print}' "$API_COST_SUMMARY" | grep -v "daily_usage" | grep -v "}$" | sort -r)
    
    if [ -n "$daily_usage" ]; then
      # Add daily usage header
      cat >> "$DASHBOARD_OUTPUT" << EOF || { log_error "Failed to write daily usage header" "$SCRIPT_NAME"; return 1; }
### Daily Usage (Last 7 Days)

| Date | Tokens | Cost |
|------|--------|------|
EOF
      
      # Parse and add each day (up to 7 days)
      count=0
      echo "$daily_usage" | grep -o "\"[0-9-]*\":" | tr -d '"' | tr -d ':' | while read -r date_entry; do
        if [ $count -lt 7 ]; then
          tokens=$(grep -A 3 "\"$date_entry\":" "$API_COST_SUMMARY" | grep -o "\"tokens\": [0-9]*" | awk '{print $2}')
          cost=$(grep -A 3 "\"$date_entry\":" "$API_COST_SUMMARY" | grep -o "\"cost\": [0-9.]*" | awk '{print $2}')
          
          # Add to table
          echo "| $date_entry | $tokens | \$$cost |" >> "$DASHBOARD_OUTPUT"
          count=$((count + 1))
        else
          break
        fi
      done
      
      # Add empty line
      echo "" >> "$DASHBOARD_OUTPUT"
    fi
  fi
  
  log_info "API usage section generated successfully" "$SCRIPT_NAME"
  return 0
}

# Function to generate expense allocation section
generate_expense_allocation() {
  log_info "Generating expense allocation section..." "$SCRIPT_NAME"
  
  cat >> "$DASHBOARD_OUTPUT" << EOF || { log_error "Failed to write expense allocation section" "$SCRIPT_NAME"; return 1; }
## Expense Allocation

| Category | Percentage | Amount |
|----------|------------|--------|
| API Costs | 75% | \$$total_cost |
| Development | 15% | \$$(echo "scale=2; $total_funding * 0.15" | bc) |
| Documentation | 10% | \$$(echo "scale=2; $total_funding * 0.10" | bc) |
| **Total Expenses** | 100% | \$$(echo "scale=2; $total_cost + ($total_funding * 0.25)" | bc) |

EOF
  
  log_info "Expense allocation section generated successfully" "$SCRIPT_NAME"
  return 0
}

# Function to generate funding goals section
generate_funding_goals() {
  log_info "Generating funding goals section..." "$SCRIPT_NAME"
  
  # Set default goals if we have burn rate
  goal_1_months=1
  goal_2_months=3
  goal_3_months=12
  
  if (( $(echo "$monthly_burn > 0" | bc -l) )); then
    goal_1_amount=$(echo "scale=2; $monthly_burn * $goal_1_months" | bc)
    goal_2_amount=$(echo "scale=2; $monthly_burn * $goal_2_months" | bc)
    goal_3_amount=$(echo "scale=2; $monthly_burn * $goal_3_months" | bc)
  else
    goal_1_amount=10
    goal_2_amount=30
    goal_3_amount=120
  fi
  
  # Calculate progress percentages (protect against division by zero)
  if (( $(echo "$goal_1_amount > 0" | bc -l) )); then
    goal_1_progress=$(echo "scale=1; $total_funding / $goal_1_amount * 100" | bc)
    if (( $(echo "$goal_1_progress > 100" | bc -l) )); then goal_1_progress=100; fi
  else
    goal_1_progress=0
  fi
  
  if (( $(echo "$goal_2_amount > 0" | bc -l) )); then
    goal_2_progress=$(echo "scale=1; $total_funding / $goal_2_amount * 100" | bc)
    if (( $(echo "$goal_2_progress > 100" | bc -l) )); then goal_2_progress=100; fi
  else
    goal_2_progress=0
  fi
  
  if (( $(echo "$goal_3_amount > 0" | bc -l) )); then
    goal_3_progress=$(echo "scale=1; $total_funding / $goal_3_amount * 100" | bc)
    if (( $(echo "$goal_3_progress > 100" | bc -l) )); then goal_3_progress=100; fi
  else
    goal_3_progress=0
  fi
  
  cat >> "$DASHBOARD_OUTPUT" << EOF || { log_error "Failed to write funding goals section" "$SCRIPT_NAME"; return 1; }
## Funding Goals

| Goal | Target | Progress | Status |
|------|--------|----------|--------|
| 1-Month Runway | \$$goal_1_amount | ${goal_1_progress}% | $(if (( $(echo "$goal_1_progress >= 100" | bc -l) )); then echo "✅"; else echo "🔄"; fi) |
| 3-Month Runway | \$$goal_2_amount | ${goal_2_progress}% | $(if (( $(echo "$goal_2_progress >= 100" | bc -l) )); then echo "✅"; else echo "🔄"; fi) |
| 12-Month Runway | \$$goal_3_amount | ${goal_3_progress}% | $(if (( $(echo "$goal_3_progress >= 100" | bc -l) )); then echo "✅"; else echo "🔄"; fi) |

EOF
  
  log_info "Funding goals section generated successfully" "$SCRIPT_NAME"
  return 0
}

# Function to generate sponsor acknowledgement section
generate_sponsor_acknowledgements() {
  log_info "Generating sponsor acknowledgement section..." "$SCRIPT_NAME"
  
  cat >> "$DASHBOARD_OUTPUT" << EOF || { log_error "Failed to write sponsor acknowledgement section" "$SCRIPT_NAME"; return 1; }
## Sponsor Acknowledgements

Thank you to all our sponsors who make this project possible!

EOF
  
  # Extract GitHub sponsors if available
  if [ -f "$SPONSORS_FILE" ] && [ -r "$SPONSORS_FILE" ]; then
    sponsors=$(grep -o '"name": "[^"]*"' "$SPONSORS_FILE" | cut -d'"' -f4 | tr '\n' ', ' | sed 's/,$//')
    
    if [ -n "$sponsors" ]; then
      echo "### GitHub Sponsors" >> "$DASHBOARD_OUTPUT"
      echo "$sponsors" >> "$DASHBOARD_OUTPUT"
      echo "" >> "$DASHBOARD_OUTPUT"
    fi
  fi
  
  # Extract Ko-fi sponsors if available (simplified for this example)
  if [ -f "$KOFI_CONFIG" ] && [ -r "$KOFI_CONFIG" ]; then
    kofi_sponsors=$(grep -o '"sponsors": \[[^]]*\]' "$KOFI_CONFIG" | grep -o '"name": "[^"]*"' | cut -d'"' -f4 | tr '\n' ', ' | sed 's/,$//')
    
    if [ -n "$kofi_sponsors" ]; then
      echo "### Ko-fi Supporters" >> "$DASHBOARD_OUTPUT"
      echo "$kofi_sponsors" >> "$DASHBOARD_OUTPUT"
      echo "" >> "$DASHBOARD_OUTPUT"
    fi
  fi
  
  # Extract Open Collective sponsors if available (simplified for this example)
  if [ -f "$OPENCOLL_CONFIG" ] && [ -r "$OPENCOLL_CONFIG" ]; then
    opencoll_sponsors=$(grep -o '"backers": \[[^]]*\]' "$OPENCOLL_CONFIG" | grep -o '"name": "[^"]*"' | cut -d'"' -f4 | tr '\n' ', ' | sed 's/,$//')
    
    if [ -n "$opencoll_sponsors" ]; then
      echo "### Open Collective Backers" >> "$DASHBOARD_OUTPUT"
      echo "$opencoll_sponsors" >> "$DASHBOARD_OUTPUT"
      echo "" >> "$DASHBOARD_OUTPUT"
    fi
  fi
  
  log_info "Sponsor acknowledgement section generated successfully" "$SCRIPT_NAME"
  return 0
}

# Function to generate transparency notes
generate_transparency_notes() {
  log_info "Generating transparency notes..." "$SCRIPT_NAME"
  
  cat >> "$DASHBOARD_OUTPUT" << EOF || { log_error "Failed to write transparency notes" "$SCRIPT_NAME"; return 1; }
## Transparency Statement

The lifeform-2 project is committed to full transparency in all financial matters. This dashboard provides a complete view of our funding sources, expenses, and API usage. All financial decisions prioritize:

1. Ensuring continued operation of the lifeform (API costs)
2. Improving core functionality (development)
3. Enhancing documentation and educational resources

This dashboard is updated automatically with each funding transaction and can be regenerated at any time using:

\`\`\`bash
./modules/funding/funding_dashboard.sh generate
\`\`\`

For detailed API usage information, please see the API usage reports generated by:

\`\`\`bash
./modules/funding/track_api_costs.sh report
\`\`\`

Thank you for your support!
EOF
  
  log_info "Transparency notes generated successfully" "$SCRIPT_NAME"
  return 0
}

#===================================
# MAIN DASHBOARD GENERATION
#===================================

# Function to generate the complete funding dashboard
generate_dashboard() {
  log_info "Generating unified funding dashboard..." "$SCRIPT_NAME"
  
  # Validate required files
  if ! validate_required_files; then
    log_error "Required files validation failed" "$SCRIPT_NAME"
    return 1
  fi
  
  # Extract data from various sources
  extract_token_data
  extract_funding_data
  calculate_runway
  
  # Create the dashboard file
  echo "" > "$DASHBOARD_OUTPUT" || { log_error "Failed to create dashboard file" "$SCRIPT_NAME"; return 1; }
  
  # Generate each section
  generate_overview_section || return 1
  generate_funding_breakdown || return 1
  generate_api_usage_section || return 1
  generate_expense_allocation || return 1
  generate_funding_goals || return 1
  generate_sponsor_acknowledgements || return 1
  generate_transparency_notes || return 1
  
  log_info "Funding dashboard generated successfully at $DASHBOARD_OUTPUT" "$SCRIPT_NAME"
  echo "Funding dashboard created at: $DASHBOARD_OUTPUT"
  return 0
}

#===================================
# MAIN EXECUTION
#===================================

log_info "Starting unified funding dashboard module..." "$SCRIPT_NAME"

case "$1" in
  "generate")
    generate_dashboard
    exit_code=$?
    ;;
  "help")
    log_info "Displaying help information" "$SCRIPT_NAME"
    echo "Unified Funding Dashboard"
    echo "------------------------"
    echo "Usage: $0 {generate|help}"
    echo ""
    echo "Commands:"
    echo "  generate                    - Generate the unified funding dashboard"
    echo "  help                        - Display this help information"
    echo ""
    echo "This script aggregates data from all funding platforms to provide"
    echo "a comprehensive financial overview of the lifeform-2 project."
    exit_code=0
    ;;
  *)
    log_error "Unknown command: $1" "$SCRIPT_NAME"
    log_info "Run '$0 help' for usage information" "$SCRIPT_NAME"
    exit_code=1
    ;;
esac

log_info "Unified funding dashboard module completed with exit code: $exit_code" "$SCRIPT_NAME"
exit $exit_code