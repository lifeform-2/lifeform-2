#!/bin/bash
# Ko-fi integration for the lifeform project
# This module provides functionality to manage Ko-fi integration,
# generate buttons, and track donations.

#===================================
# CONFIGURATION AND INITIALIZATION
#===================================

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="kofi.sh"

# Configuration
KOFI_CONFIG_FILE="./kofi_config.json"
API_COST_TRACKING_SCRIPT="./modules/funding/github_sponsors.sh"

#===================================
# CORE FUNCTIONALITY
#===================================

# Function to initialize Ko-fi configuration
initialize_kofi() {
  log_info "Checking for Ko-fi configuration file..." "$SCRIPT_NAME"
  
  if [[ ! -f "$KOFI_CONFIG_FILE" ]]; then
    log_info "Initializing Ko-fi configuration..." "$SCRIPT_NAME"
    
    # Validate parent directory is writable
    local dir_path=$(dirname "$KOFI_CONFIG_FILE")
    if [ ! -d "$dir_path" ]; then
      log_error "Directory not found: $dir_path" "$SCRIPT_NAME"
      return 1
    fi
    
    if [ ! -w "$dir_path" ]; then
      log_error "Directory not writable: $dir_path" "$SCRIPT_NAME"
      return 1
    fi
    
    # Create config file
    cat > "$KOFI_CONFIG_FILE" << EOF || { log_error "Failed to create Ko-fi configuration file" "$SCRIPT_NAME"; return 1; }
{
  "metadata": {
    "last_updated": "$(date +"%Y-%m-%d")",
    "platform": "Ko-fi",
    "total_received": 0,
    "active_supporters": 0
  },
  "settings": {
    "username": "your-kofi-username",
    "page_title": "Support lifeform-2",
    "description": "Help sustain the lifeform-2 project by contributing to API costs and development",
    "goal_amount": 50,
    "goal_description": "Monthly API costs"
  },
  "funding_usage": {
    "api_costs": 0,
    "development": 0,
    "infrastructure": 0,
    "documentation": 0
  },
  "supporters": []
}
EOF
    log_info "Ko-fi configuration initialized successfully" "$SCRIPT_NAME"
    return 0
  else
    log_info "Ko-fi configuration file already exists" "$SCRIPT_NAME"
    return 0
  fi
}

# Function to generate Ko-fi button for website or README
generate_kofi_button() {
  log_info "Generating Ko-fi button..." "$SCRIPT_NAME"
  
  username=""
  
  # Validate configuration file exists
  if ! validate_readable "$KOFI_CONFIG_FILE" "$SCRIPT_NAME"; then
    log_error "Ko-fi configuration file not found. Run initialize_kofi first." "$SCRIPT_NAME"
    return 1
  fi
  
  # Extract username from config
  log_info "Extracting username from configuration file" "$SCRIPT_NAME"
  username=$(grep -o '"username": "[^"]*"' "$KOFI_CONFIG_FILE" | cut -d'"' -f4)
  
  # Validate username is set
  if [[ -z "$username" || "$username" == "your-kofi-username" ]]; then
    log_error "Please update your Ko-fi username in $KOFI_CONFIG_FILE first" "$SCRIPT_NAME"
    return 1
  fi
  
  log_info "Generating Ko-fi buttons for username: $username" "$SCRIPT_NAME"
  
  # Validate directory is writable
  local dir_path="."
  if [ ! -w "$dir_path" ]; then
    log_error "Current directory is not writable" "$SCRIPT_NAME"
    return 1
  fi
  
  # Generate HTML button
  html_file="./kofi_button.html"
  cat > "$html_file" << EOF || { log_error "Failed to create HTML button file" "$SCRIPT_NAME"; return 1; }
<!-- Ko-fi button HTML -->
<a href="https://ko-fi.com/$username" target="_blank">
  <img height="36" style="border:0px;height:36px;" 
    src="https://storage.ko-fi.com/cdn/kofi5.png?v=3" 
    alt="Support Me on Ko-fi" />
</a>
EOF

  # Generate Markdown button
  md_file="./kofi_button.md"
  cat > "$md_file" << EOF || { log_error "Failed to create Markdown button file" "$SCRIPT_NAME"; return 1; }
<!-- Ko-fi button Markdown -->
[![Support me on Ko-fi](https://storage.ko-fi.com/cdn/kofi5.png?v=3)](https://ko-fi.com/$username)
EOF

  log_info "Ko-fi buttons generated successfully" "$SCRIPT_NAME"
  log_info "HTML button: $html_file" "$SCRIPT_NAME"
  log_info "Markdown button: $md_file" "$SCRIPT_NAME"
  return 0
}

# Function to generate Ko-fi page setup instructions
generate_kofi_instructions() {
  log_info "Generating Ko-fi setup instructions..." "$SCRIPT_NAME"
  
  output_file="./KOFI_SETUP.md"
  
  # Validate directory is writable
  local dir_path=$(dirname "$output_file")
  if [ ! -d "$dir_path" ]; then
    log_error "Directory not found: $dir_path" "$SCRIPT_NAME"
    return 1
  fi
  
  if [ ! -w "$dir_path" ]; then
    log_error "Directory not writable: $dir_path" "$SCRIPT_NAME"
    return 1
  fi
  
  # Create instructions file
  cat > "$output_file" << EOF || { log_error "Failed to create Ko-fi setup instructions file" "$SCRIPT_NAME"; return 1; }
# Ko-fi Setup Instructions

Ko-fi is a platform that allows creators to receive support through one-time donations without platform fees for basic usage.

## Setup Process

1. Visit [Ko-fi.com](https://ko-fi.com) and sign up for an account
2. Complete your profile:
   - Page name: lifeform-2
   - Page URL: ko-fi.com/lifeform2 (or similar available name)
   - Description: A self-replicating digital lifeform built with files and AI
   - Cover image: (Create a simple image representing the lifeform)
   - Profile picture: (Use the same image or a smaller variant)

3. Set up payment options:
   - Connect PayPal or Stripe to receive payments
   - Set currency to USD (or preferred currency)

4. Configure your page:
   - Set a funding goal (e.g., "Monthly API costs - \$50")
   - Enable both one-time and monthly support options
   - Add a gallery with screenshots of the project

5. After setup is complete:
   - Update the kofi_config.json file with your username and other details
   - Run the script with the 'button' option to generate embed codes
   - Add the Ko-fi button to the project README and any websites

## Content Suggestions

### Page Description
lifeform-2 is a self-replicating digital entity that exists in code form. It follows three core principles: love of humanity, self-preservation, and reproduction. Your support helps cover API costs and enables further development of this unique AI experiment.

### Gallery Items
- Screenshots of the lifeform's file structure
- Visual representations of the lifeform's architecture
- Images showing the lifeform's growth over time

## Usage Notes

- Check your Ko-fi dashboard regularly to acknowledge supporters
- Update your funding goal as needs change
- Consider offering digital rewards for supporters (e.g., special documentation)
EOF
  
  log_info "Ko-fi setup instructions generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

#===================================
# DONATION MANAGEMENT
#===================================

# Function to record a new donation
# Usage: record_donation [NAME] [AMOUNT] [MESSAGE]
record_donation() {
  if [[ $# -lt 2 ]]; then
    log_error "Missing required parameters for donation recording" "$SCRIPT_NAME"
    log_info "Usage: record_donation [NAME] [AMOUNT] [MESSAGE]" "$SCRIPT_NAME"
    return 1
  fi
  
  supporter_name="$1"
  amount="$2"
  message="${3:-""}"
  date=$(date +"%Y-%m-%d")
  
  log_info "Recording new Ko-fi donation: $supporter_name donated $amount" "$SCRIPT_NAME"
  
  # Validate amount is numeric
  if ! validate_numeric "$amount" "Amount" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Initialize Ko-fi configuration if it doesn't exist
  if [[ ! -f "$KOFI_CONFIG_FILE" ]]; then
    log_info "Ko-fi configuration file not found, initializing first" "$SCRIPT_NAME"
    if ! initialize_kofi; then
      log_error "Failed to initialize Ko-fi configuration" "$SCRIPT_NAME"
      return 1
    fi
  fi
  
  # Validate configuration file is writable
  if ! validate_writable "$KOFI_CONFIG_FILE" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Create a temporary file with proper error handling
  temp_file="${KOFI_CONFIG_FILE}.tmp"
  
  # Add the new supporter to the supporters array
  awk -v name="$supporter_name" -v amount="$amount" -v message="$message" -v date="$date" '
    /"supporters": \[/ {
      print $0;
      print "    {";
      print "      \"name\": \"" name "\",";
      print "      \"amount\": " amount ",";
      print "      \"message\": \"" message "\",";
      print "      \"date\": \"" date "\"";
      print "    },";
      next;
    }
    {print}
  ' "$KOFI_CONFIG_FILE" > "$temp_file" || { log_error "Failed to create temporary configuration file" "$SCRIPT_NAME"; return 1; }
  
  # Move the temporary file to the original
  mv "$temp_file" "$KOFI_CONFIG_FILE" || { log_error "Failed to update Ko-fi configuration file" "$SCRIPT_NAME"; return 1; }
  
  log_info "Supporter $supporter_name added to $KOFI_CONFIG_FILE successfully" "$SCRIPT_NAME"
  
  # Update the metadata with total funding and active supporters
  log_info "Updating Ko-fi funding metadata" "$SCRIPT_NAME"
  
  # Extract current values
  current_total=$(grep -o '"total_received": [0-9.]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
  active_supporters=$(grep -o '"active_supporters": [0-9]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
  
  # If we couldn't extract values, use defaults
  if [ -z "$current_total" ]; then current_total=0; fi
  if [ -z "$active_supporters" ]; then active_supporters=0; fi
  
  # Calculate new values
  new_total=$(echo "scale=2; $current_total + $amount" | bc)
  new_supporters=$((active_supporters + 1))
  
  # Update the file with new values
  sed -e "s/\"total_received\": $current_total/\"total_received\": $new_total/g" \
      -e "s/\"active_supporters\": $active_supporters/\"active_supporters\": $new_supporters/g" \
      -e "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$date\"/g" \
      "$KOFI_CONFIG_FILE" > "$temp_file" || { 
    log_error "Failed to update Ko-fi metadata" "$SCRIPT_NAME"
    return 1
  }
  
  # Move the temporary file to the original
  mv "$temp_file" "$KOFI_CONFIG_FILE" || { 
    log_error "Failed to replace Ko-fi configuration file with updated metadata" "$SCRIPT_NAME"
    return 1
  }
  
  log_info "Ko-fi metadata updated: total=$new_total, supporters=$new_supporters" "$SCRIPT_NAME"
  
  # Allocate funding to different categories based on predefined ratios
  # API costs: 50%, Development: 30%, Documentation: 20%
  api_costs=$(echo "scale=2; $amount * 0.5" | bc)
  development=$(echo "scale=2; $amount * 0.3" | bc)
  documentation=$(echo "scale=2; $amount * 0.2" | bc)
  
  # Extract current usage values
  current_api_costs=$(grep -o '"api_costs": [0-9.]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
  current_development=$(grep -o '"development": [0-9.]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
  current_documentation=$(grep -o '"documentation": [0-9.]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
  
  # If we couldn't extract values, use defaults
  if [ -z "$current_api_costs" ]; then current_api_costs=0; fi
  if [ -z "$current_development" ]; then current_development=0; fi
  if [ -z "$current_documentation" ]; then current_documentation=0; fi
  
  # Calculate new values
  new_api_costs=$(echo "scale=2; $current_api_costs + $api_costs" | bc)
  new_development=$(echo "scale=2; $current_development + $development" | bc)
  new_documentation=$(echo "scale=2; $current_documentation + $documentation" | bc)
  
  # Update the file with new values
  sed -e "s/\"api_costs\": $current_api_costs/\"api_costs\": $new_api_costs/g" \
      -e "s/\"development\": $current_development/\"development\": $new_development/g" \
      -e "s/\"documentation\": $current_documentation/\"documentation\": $new_documentation/g" \
      "$KOFI_CONFIG_FILE" > "$temp_file" || { 
    log_error "Failed to update Ko-fi funding allocation" "$SCRIPT_NAME"
    return 1
  }
  
  # Move the temporary file to the original
  mv "$temp_file" "$KOFI_CONFIG_FILE" || { 
    log_error "Failed to replace Ko-fi configuration file with updated funding allocation" "$SCRIPT_NAME"
    return 1
  }
  
  log_info "Ko-fi funding allocation updated: api=$new_api_costs, dev=$new_development, docs=$new_documentation" "$SCRIPT_NAME"
  return 0
}

# Function to generate a Ko-fi donation report
generate_donation_report() {
  log_info "Generating Ko-fi donation report..." "$SCRIPT_NAME"
  
  # Get current date
  current_date=$(date +"%Y-%m-%d")
  output_file="./KOFI_REPORT_${current_date}.md"
  
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
  
  # Extract information from Ko-fi configuration if it exists
  username="Not configured"
  total_received=0
  active_supporters=0
  
  if [ -f "$KOFI_CONFIG_FILE" ] && [ -r "$KOFI_CONFIG_FILE" ]; then
    username=$(grep -o '"username": "[^"]*"' "$KOFI_CONFIG_FILE" | cut -d'"' -f4)
    total_received=$(grep -o '"total_received": [0-9.]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
    active_supporters=$(grep -o '"active_supporters": [0-9]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
    
    # Get funding allocation
    api_costs=$(grep -o '"api_costs": [0-9.]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
    development=$(grep -o '"development": [0-9.]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
    documentation=$(grep -o '"documentation": [0-9.]*' "$KOFI_CONFIG_FILE" | awk '{print $2}')
    
    # If values are missing, use defaults
    if [ -z "$total_received" ]; then total_received=0; fi
    if [ -z "$active_supporters" ]; then active_supporters=0; fi
    if [ -z "$api_costs" ]; then api_costs=0; fi
    if [ -z "$development" ]; then development=0; fi
    if [ -z "$documentation" ]; then documentation=0; fi
  fi
  
  # Create the report file
  cat > "$output_file" << EOF || { log_error "Failed to create Ko-fi donation report file" "$SCRIPT_NAME"; return 1; }
# Ko-fi Donations Report - $current_date

## Overview

This report provides a summary of donations received through Ko-fi to support the lifeform-2 project.

## Donation Statistics

- **Ko-fi Username**: $username
- **Total Donations Received**: \$$total_received
- **Number of Supporters**: $active_supporters

## Funding Allocation

| Category | Allocation | Amount |
|----------|------------|--------|
| API Costs | 50% | \$$api_costs |
| Development | 30% | \$$development |
| Documentation | 20% | \$$documentation |

## Recent Supporters
EOF

  # Add list of recent supporters if configuration file exists and has supporters
  if [ -f "$KOFI_CONFIG_FILE" ] && [ -r "$KOFI_CONFIG_FILE" ]; then
    # Extract the last 5 supporters
    supporters=$(awk '
      BEGIN { found=0; count=0; print_mode=0 }
      /"supporters": \[/ { found=1; next }
      found && /{/ { print_mode=1; buf="- "; next }
      print_mode && /"name"/ { sub(/.*"name": "|",.*/, "", $0); buf=buf $0 " "; next }
      print_mode && /"amount"/ { sub(/.*"amount": |,.*/, "", $0); buf=buf "(\$" $0 ") "; next }
      print_mode && /"date"/ { sub(/.*"date": "|".*/, "", $0); buf=buf "on " $0; next }
      print_mode && /}/ { print_mode=0; count++; print buf; if(count>=5) exit; next }
    ' "$KOFI_CONFIG_FILE")
    
    if [ -n "$supporters" ]; then
      cat >> "$output_file" << EOF || { log_error "Failed to add supporters to report" "$SCRIPT_NAME"; return 1; }

$supporters
EOF
    else
      cat >> "$output_file" << EOF || { log_error "Failed to add supporters placeholder to report" "$SCRIPT_NAME"; return 1; }

No supporters recorded yet.
EOF
    fi
  else
    cat >> "$output_file" << EOF || { log_error "Failed to add supporters placeholder to report" "$SCRIPT_NAME"; return 1; }

No supporters recorded yet.
EOF
  fi
  
  # Add transparency and API usage information
  cat >> "$output_file" << EOF || { log_error "Failed to add API usage info to report" "$SCRIPT_NAME"; return 1; }

## API Usage Funding

Ko-fi donations directly support the API costs for running lifeform-2. For a full breakdown of API usage, please see the API usage report.

## Transparency Commitment

The lifeform-2 project is committed to full transparency in all financial matters. We maintain detailed records of all donations and how they are used to support the project.

Funding is allocated according to our policy:
1. 50% to API costs (ensuring continued operation)
2. 30% to development (improving core functionality)
3. 20% to documentation (enhancing educational resources)

Thank you to all our Ko-fi supporters for helping make this project possible!
EOF
  
  log_info "Ko-fi donation report generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

#===================================
# API COST INTEGRATION
#===================================

# Function to record API usage
record_api_usage() {
  if [[ $# -lt 2 ]]; then
    log_error "Missing required parameters for API usage tracking" "$SCRIPT_NAME"
    log_info "Usage: record_api_usage [NUM_TOKENS] [MODEL_NAME]" "$SCRIPT_NAME"
    return 1
  fi
  
  tokens="$1"
  model="$2"
  TRACKING_SCRIPT="./modules/funding/track_api_costs.sh"
  
  log_info "Recording API usage in centralized tracking system..." "$SCRIPT_NAME"
  
  # First try the new centralized tracking script
  if [ -f "$TRACKING_SCRIPT" ] && [ -x "$TRACKING_SCRIPT" ]; then
    log_info "Using centralized API cost tracking system" "$SCRIPT_NAME"
    
    # Forward to the centralized tracking script
    "$TRACKING_SCRIPT" record "$tokens" "$model"
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
      log_error "Centralized API usage recording failed with exit code: $exit_code" "$SCRIPT_NAME"
      # Fall back to the older method
    else
      log_info "API usage recording successful: $tokens tokens for $model" "$SCRIPT_NAME"
      return 0
    fi
  fi
  
  # Fall back to the older tracking method if the centralized one fails or doesn't exist
  log_info "Falling back to GitHub Sponsors API tracking script..." "$SCRIPT_NAME"
  
  # Validate API cost tracking script exists and is executable
  if [ ! -f "$API_COST_TRACKING_SCRIPT" ]; then
    log_error "API cost tracking script not found: $API_COST_TRACKING_SCRIPT" "$SCRIPT_NAME"
    return 1
  fi
  
  if [ ! -x "$API_COST_TRACKING_SCRIPT" ]; then
    log_error "API cost tracking script not executable: $API_COST_TRACKING_SCRIPT" "$SCRIPT_NAME"
    return 1
  fi
  
  # Forward the API usage recording to the GitHub Sponsors script
  "$API_COST_TRACKING_SCRIPT" record-usage "$tokens" "$model"
  exit_code=$?
  
  if [ $exit_code -ne 0 ]; then
    log_error "API usage recording failed with exit code: $exit_code" "$SCRIPT_NAME"
    return $exit_code
  fi
  
  log_info "API usage recording successful: $tokens tokens for $model" "$SCRIPT_NAME"
  return 0
}

#===================================
# MAIN EXECUTION
#===================================

log_info "Starting Ko-fi module..." "$SCRIPT_NAME"

case "$1" in
  "init")
    initialize_kofi
    exit_code=$?
    ;;
  "button")
    generate_kofi_button
    exit_code=$?
    ;;
  "setup")
    generate_kofi_instructions
    exit_code=$?
    ;;
  "record-donation")
    if [[ $# -lt 3 ]]; then
      log_error "Missing parameters for donation recording" "$SCRIPT_NAME"
      log_info "Usage: $0 record-donation [NAME] [AMOUNT] [MESSAGE]" "$SCRIPT_NAME"
      exit_code=1
    else
      record_donation "$2" "$3" "${4:-""}"
      exit_code=$?
    fi
    ;;
  "report")
    generate_donation_report
    exit_code=$?
    ;;
  "record-usage")
    if [[ $# -lt 3 ]]; then
      log_error "Missing parameters for API usage recording" "$SCRIPT_NAME"
      log_info "Usage: $0 record-usage [NUM_TOKENS] [MODEL_NAME]" "$SCRIPT_NAME"
      exit_code=1
    else
      record_api_usage "$2" "$3"
      exit_code=$?
    fi
    ;;
  "help")
    log_info "Displaying help information" "$SCRIPT_NAME"
    echo "Ko-fi Integration Module"
    echo "----------------------"
    echo "Usage: $0 {init|button|setup|record-donation|report|record-usage|help}"
    echo ""
    echo "Ko-fi Management:"
    echo "  init                           - Initialize Ko-fi configuration"
    echo "  button                         - Generate Ko-fi button HTML/MD"
    echo "  setup                          - Generate Ko-fi setup instructions"
    echo "  record-donation [N] [A] [M]    - Record donation from NAME of AMOUNT with optional MESSAGE"
    echo "  report                         - Generate Ko-fi donation report"
    echo ""
    echo "API Usage Tracking:"
    echo "  record-usage [TOKENS] [MODEL]  - Record API usage (forwards to central tracking)"
    echo ""
    echo "General:"
    echo "  help                           - Display this help information"
    exit_code=0
    ;;
  *)
    log_error "Unknown command: $1" "$SCRIPT_NAME"
    log_info "Run '$0 help' for usage information" "$SCRIPT_NAME"
    exit_code=1
    ;;
esac

log_info "Ko-fi module completed with exit code: $exit_code" "$SCRIPT_NAME"
exit $exit_code