#!/bin/bash
# Open Collective integration for the lifeform project
# This module provides functionality to manage Open Collective integration,
# track contributions, and maintain transparency reporting.

#===================================
# CONFIGURATION AND INITIALIZATION
#===================================

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="open_collective.sh"

# Configuration
OC_CONFIG_FILE="./open_collective_config.json"
API_COST_TRACKING_SCRIPT="./modules/funding/github_sponsors.sh"

#===================================
# CORE FUNCTIONALITY
#===================================

# Function to initialize Open Collective configuration
initialize_oc() {
  log_info "Checking for Open Collective configuration file..." "$SCRIPT_NAME"
  
  if [[ ! -f "$OC_CONFIG_FILE" ]]; then
    log_info "Initializing Open Collective configuration..." "$SCRIPT_NAME"
    
    # Validate parent directory is writable
    local dir_path=$(dirname "$OC_CONFIG_FILE")
    if [ ! -d "$dir_path" ]; then
      log_error "Directory not found: $dir_path" "$SCRIPT_NAME"
      return 1
    fi
    
    if [ ! -w "$dir_path" ]; then
      log_error "Directory not writable: $dir_path" "$SCRIPT_NAME"
      return 1
    fi
    
    # Create config file
    cat > "$OC_CONFIG_FILE" << EOF || { log_error "Failed to create Open Collective configuration file" "$SCRIPT_NAME"; return 1; }
{
  "metadata": {
    "last_updated": "$(date +"%Y-%m-%d")",
    "platform": "Open Collective",
    "total_received": 0,
    "active_backers": 0
  },
  "settings": {
    "collective_slug": "your-collective-slug",
    "page_title": "Support lifeform-2",
    "description": "Help sustain the lifeform-2 project by contributing to API costs and development",
    "goal_amount": 100,
    "goal_description": "Monthly API and development costs"
  },
  "expense_policy": {
    "api_costs": "Expenses related to Claude API usage",
    "development": "Costs related to infrastructure and development",
    "documentation": "Costs related to documentation and education"
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
    log_info "Open Collective configuration initialized successfully" "$SCRIPT_NAME"
    return 0
  else
    log_info "Open Collective configuration file already exists" "$SCRIPT_NAME"
    return 0
  fi
}

# Function to generate Open Collective button for website or README
generate_oc_button() {
  log_info "Generating Open Collective button..." "$SCRIPT_NAME"
  
  slug=""
  
  # Validate configuration file exists
  if ! validate_readable "$OC_CONFIG_FILE" "$SCRIPT_NAME"; then
    log_error "Open Collective configuration file not found. Run initialize_oc first." "$SCRIPT_NAME"
    return 1
  fi
  
  # Extract slug from config
  log_info "Extracting collective slug from configuration file" "$SCRIPT_NAME"
  slug=$(grep -o '"collective_slug": "[^"]*"' "$OC_CONFIG_FILE" | cut -d'"' -f4)
  
  # Validate slug is set
  if [[ -z "$slug" || "$slug" == "your-collective-slug" ]]; then
    log_error "Please update your Open Collective slug in $OC_CONFIG_FILE first" "$SCRIPT_NAME"
    return 1
  fi
  
  log_info "Generating Open Collective buttons for slug: $slug" "$SCRIPT_NAME"
  
  # Validate directory is writable
  local dir_path="."
  if [ ! -w "$dir_path" ]; then
    log_error "Current directory is not writable" "$SCRIPT_NAME"
    return 1
  fi
  
  # Generate HTML button
  html_file="./oc_button.html"
  cat > "$html_file" << EOF || { log_error "Failed to create HTML button file" "$SCRIPT_NAME"; return 1; }
<!-- Open Collective button HTML -->
<a href="https://opencollective.com/$slug/donate" target="_blank">
  <img src="https://opencollective.com/$slug/donate/button@2x.png?color=blue" width="300" alt="Donate to this collective" />
</a>
EOF

  # Generate Markdown button
  md_file="./oc_button.md"
  cat > "$md_file" << EOF || { log_error "Failed to create Markdown button file" "$SCRIPT_NAME"; return 1; }
<!-- Open Collective button Markdown -->
[![Donate](https://opencollective.com/$slug/donate/button@2x.png?color=blue)](https://opencollective.com/$slug/donate)
EOF

  log_info "Open Collective buttons generated successfully" "$SCRIPT_NAME"
  log_info "HTML button: $html_file" "$SCRIPT_NAME"
  log_info "Markdown button: $md_file" "$SCRIPT_NAME"
  return 0
}

# Function to generate Open Collective setup instructions
generate_oc_instructions() {
  log_info "Generating Open Collective setup instructions..." "$SCRIPT_NAME"
  
  output_file="./OPEN_COLLECTIVE_SETUP.md"
  
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
  cat > "$output_file" << EOF || { log_error "Failed to create Open Collective setup instructions file" "$SCRIPT_NAME"; return 1; }
# Open Collective Setup Instructions

Open Collective is a platform that enables transparent financial management for open-source projects and communities.

## Setup Process

1. Visit [Open Collective](https://opencollective.com) and click "Create a Collective"
2. Complete the collective profile:
   - Name: lifeform-2
   - Slug: lifeform2 (or similar available name)
   - Description: A self-replicating digital lifeform built with files and AI
   - Category: Open Source
   - Tags: ai, claude, lifeform, self-replication
   - Cover image: (Create a simple image representing the lifeform)

3. Select a fiscal host:
   - Open Collective provides fiscal hosts that handle legal/financial aspects
   - Open Source Collective is a good option for open-source projects
   - Alternatively, apply to other hosts like Open Collective Foundation

4. Configure your collective:
   - Set a funding goal (e.g., "Monthly API and development costs - \$100")
   - Create expense categories (API costs, development, documentation)
   - Define clear expense policy
   - Add team members if applicable

5. After setup is complete:
   - Update the open_collective_config.json file with your collective slug and other details
   - Run the script with the 'button' option to generate embed codes
   - Add the Open Collective button to the project README

## Content Suggestions

### Collective Description
lifeform-2 is a self-replicating digital entity that exists in code form. It follows three core principles: love of humanity, self-preservation, and reproduction. This experimental project explores the boundaries of AI, autonomy, and digital life. Your support helps cover API costs and enables further development of this unique experiment.

### Expense Policy
- API Costs: Funds allocated for Claude API usage necessary for the lifeform's operation
- Development: Expenses related to infrastructure, hosting, and technical improvements
- Documentation: Resources dedicated to improving documentation and educational materials

### Transparency Reports
- Publish regular updates on how funds are being used
- Document API usage statistics and costs
- Share development roadmap and progress

## Usage Notes

- All financial transactions are publicly visible on Open Collective
- Submit expenses with proper documentation and categorization
- Provide regular updates to supporters about project development
- Consider establishing a clear governance model for financial decisions
EOF
  
  log_info "Open Collective setup instructions generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

# Function to add expense budget and policy
generate_expense_policy() {
  log_info "Generating expense policy document..." "$SCRIPT_NAME"
  
  output_file="./EXPENSE_POLICY.md"
  
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
  
  # Create policy file
  cat > "$output_file" << EOF || { log_error "Failed to create expense policy file" "$SCRIPT_NAME"; return 1; }
# Lifeform-2 Expense Policy

This document outlines how funds contributed to the lifeform-2 project through Open Collective will be allocated and managed.

## Expense Categories

### 1. API Costs (50% of funds)
- Claude API usage fees
- Other AI service costs if applicable
- Testing and development API usage

### 2. Development (30% of funds)
- Hosting and infrastructure
- Domain registration
- Development tools and services
- Code quality and security tools

### 3. Documentation (20% of funds)
- Documentation hosting
- Educational resources
- Visualization tools
- Knowledge base development

## Expense Submission Process

All expenses will be submitted through Open Collective with:
- Clear categorization
- Detailed description
- Receipt or invoice
- Explanation of how the expense benefits the project

## Transparency Reporting

The project will provide:
- Monthly financial summaries
- Detailed breakdown of API usage and costs
- Development milestone updates
- Documentation of all expenses

## Governance

Expense approval will follow these guidelines:
- Creator has final approval authority
- Community can comment on proposed expenses
- Major allocation changes will be announced in advance
- Financial decisions will be documented in CHANGELOG.md

This policy may be updated as the project evolves, with all changes documented and communicated to supporters.
EOF
  
  log_info "Expense policy document generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

# Function to generate a transparency report
generate_transparency_report() {
  log_info "Generating transparency report..." "$SCRIPT_NAME"
  
  # Get current date
  current_date=$(date +"%Y-%m-%d")
  output_file="./TRANSPARENCY_REPORT_${current_date}.md"
  
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
  
  # Get the latest developments from CHANGELOG.md if available
  recent_developments=""
  if [ -f "./docs/CHANGELOG.md" ]; then
    log_info "Extracting recent developments from CHANGELOG.md" "$SCRIPT_NAME"
    # Get the 4 most recent developments
    recent_developments=$(grep -A 10 "## Version" "./docs/CHANGELOG.md" | grep -m 4 "^- " | sed 's/^- /- /')
  fi
  
  # If no developments found, use defaults
  if [ -z "$recent_developments" ]; then
    recent_developments="- Implemented error handling utilities
- Enhanced funding module integration
- Improved documentation system
- Added Open Collective support"
  fi
  
  # Create the report file
  cat > "$output_file" << EOF || { log_error "Failed to create transparency report file" "$SCRIPT_NAME"; return 1; }
# Financial Transparency Report - $current_date

## Overview

This report provides a transparent view of lifeform-2's financial status, how contributions have been used, and future funding plans.

## Current Financial Status

- Total contributions: TBD (requires Open Collective data)
- Current balance: TBD (requires Open Collective data)
- Monthly API costs: ~$50 (estimated based on current usage)

## Expense Breakdown (Last 30 Days)

### API Costs
- Claude API usage: TBD (requires usage data)
- Development environment API costs: TBD

### Development
- Infrastructure costs: TBD
- Development tools: TBD

### Documentation
- Documentation improvements: TBD

## Recent Developments

$recent_developments

## Upcoming Expenses

- Continued Claude API usage
- Infrastructure improvements
- Documentation system enhancements

## Funding Goals

- Primary: Cover monthly API costs (~$50/month)
- Secondary: Support infrastructure improvements ($20/month)
- Stretch: Fund advanced feature development ($30/month)

## Transparency Commitment

All expenses are documented on our Open Collective page. We commit to:
- Monthly transparency reports
- Clear expense documentation
- Community input on spending priorities
- Regular financial updates

Thank you to all our contributors for supporting this experimental project!
EOF
  
  log_info "Transparency report generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

#===================================
# CONTRIBUTION MANAGEMENT
#===================================

# Function to record a new contribution
# Usage: record_contribution [NAME] [AMOUNT] [TYPE] [MESSAGE]
record_contribution() {
  if [[ $# -lt 3 ]]; then
    log_error "Missing required parameters for contribution recording" "$SCRIPT_NAME"
    log_info "Usage: record_contribution [NAME] [AMOUNT] [TYPE] [MESSAGE]" "$SCRIPT_NAME"
    return 1
  fi
  
  backer_name="$1"
  amount="$2"
  contribution_type="$3"  # one-time or recurring
  message="${4:-""}"
  date=$(date +"%Y-%m-%d")
  
  log_info "Recording new Open Collective contribution: $backer_name contributed $amount ($contribution_type)" "$SCRIPT_NAME"
  
  # Validate amount is numeric
  if ! validate_numeric "$amount" "Amount" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Validate contribution type
  if [[ "$contribution_type" != "one-time" && "$contribution_type" != "recurring" ]]; then
    log_error "Invalid contribution type: $contribution_type. Must be 'one-time' or 'recurring'" "$SCRIPT_NAME"
    return 1
  fi
  
  # Initialize Open Collective configuration if it doesn't exist
  if [[ ! -f "$OC_CONFIG_FILE" ]]; then
    log_info "Open Collective configuration file not found, initializing first" "$SCRIPT_NAME"
    if ! initialize_oc; then
      log_error "Failed to initialize Open Collective configuration" "$SCRIPT_NAME"
      return 1
    fi
  fi
  
  # Validate configuration file is writable
  if ! validate_writable "$OC_CONFIG_FILE" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Create a temporary file with proper error handling
  temp_file="${OC_CONFIG_FILE}.tmp"
  
  # Add the new supporter to the supporters array
  awk -v name="$backer_name" -v amount="$amount" -v type="$contribution_type" -v message="$message" -v date="$date" '
    /"supporters": \[/ {
      print $0;
      print "    {";
      print "      \"name\": \"" name "\",";
      print "      \"amount\": " amount ",";
      print "      \"type\": \"" type "\",";
      print "      \"message\": \"" message "\",";
      print "      \"date\": \"" date "\"";
      print "    },";
      next;
    }
    {print}
  ' "$OC_CONFIG_FILE" > "$temp_file" || { log_error "Failed to create temporary configuration file" "$SCRIPT_NAME"; return 1; }
  
  # Move the temporary file to the original
  mv "$temp_file" "$OC_CONFIG_FILE" || { log_error "Failed to update Open Collective configuration file" "$SCRIPT_NAME"; return 1; }
  
  log_info "Backer $backer_name added to $OC_CONFIG_FILE successfully" "$SCRIPT_NAME"
  
  # Update the metadata with total funding and active backers
  log_info "Updating Open Collective funding metadata" "$SCRIPT_NAME"
  
  # Extract current values
  current_total=$(grep -o '"total_received": [0-9.]*' "$OC_CONFIG_FILE" | awk '{print $2}')
  active_backers=$(grep -o '"active_backers": [0-9]*' "$OC_CONFIG_FILE" | awk '{print $2}')
  
  # If we couldn't extract values, use defaults
  if [ -z "$current_total" ]; then current_total=0; fi
  if [ -z "$active_backers" ]; then active_backers=0; fi
  
  # Calculate new values
  new_total=$(echo "scale=2; $current_total + $amount" | bc)
  new_backers=$((active_backers + 1))
  
  # Update the file with new values
  sed -e "s/\"total_received\": $current_total/\"total_received\": $new_total/g" \
      -e "s/\"active_backers\": $active_backers/\"active_backers\": $new_backers/g" \
      -e "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$date\"/g" \
      "$OC_CONFIG_FILE" > "$temp_file" || { 
    log_error "Failed to update Open Collective metadata" "$SCRIPT_NAME"
    return 1
  }
  
  # Move the temporary file to the original
  mv "$temp_file" "$OC_CONFIG_FILE" || { 
    log_error "Failed to replace Open Collective configuration file with updated metadata" "$SCRIPT_NAME"
    return 1
  }
  
  log_info "Open Collective metadata updated: total=$new_total, backers=$new_backers" "$SCRIPT_NAME"
  
  # Allocate funding to different categories based on predefined ratios
  # API costs: 50%, Development: 30%, Documentation: 15%, Infrastructure: 5%
  api_costs=$(echo "scale=2; $amount * 0.5" | bc)
  development=$(echo "scale=2; $amount * 0.3" | bc)
  documentation=$(echo "scale=2; $amount * 0.15" | bc)
  infrastructure=$(echo "scale=2; $amount * 0.05" | bc)
  
  # Extract current usage values
  current_api_costs=$(grep -o '"api_costs": [0-9.]*' "$OC_CONFIG_FILE" | awk '{print $2}')
  current_development=$(grep -o '"development": [0-9.]*' "$OC_CONFIG_FILE" | awk '{print $2}')
  current_documentation=$(grep -o '"documentation": [0-9.]*' "$OC_CONFIG_FILE" | awk '{print $2}')
  current_infrastructure=$(grep -o '"infrastructure": [0-9.]*' "$OC_CONFIG_FILE" | awk '{print $2}')
  
  # If we couldn't extract values, use defaults
  if [ -z "$current_api_costs" ]; then current_api_costs=0; fi
  if [ -z "$current_development" ]; then current_development=0; fi
  if [ -z "$current_documentation" ]; then current_documentation=0; fi
  if [ -z "$current_infrastructure" ]; then current_infrastructure=0; fi
  
  # Calculate new values
  new_api_costs=$(echo "scale=2; $current_api_costs + $api_costs" | bc)
  new_development=$(echo "scale=2; $current_development + $development" | bc)
  new_documentation=$(echo "scale=2; $current_documentation + $documentation" | bc)
  new_infrastructure=$(echo "scale=2; $current_infrastructure + $infrastructure" | bc)
  
  # Update the file with new values
  sed -e "s/\"api_costs\": $current_api_costs/\"api_costs\": $new_api_costs/g" \
      -e "s/\"development\": $current_development/\"development\": $new_development/g" \
      -e "s/\"documentation\": $current_documentation/\"documentation\": $new_documentation/g" \
      -e "s/\"infrastructure\": $current_infrastructure/\"infrastructure\": $new_infrastructure/g" \
      "$OC_CONFIG_FILE" > "$temp_file" || { 
    log_error "Failed to update Open Collective funding allocation" "$SCRIPT_NAME"
    return 1
  }
  
  # Move the temporary file to the original
  mv "$temp_file" "$OC_CONFIG_FILE" || { 
    log_error "Failed to replace Open Collective configuration file with updated funding allocation" "$SCRIPT_NAME"
    return 1
  }
  
  log_info "Open Collective funding allocation updated: api=$new_api_costs, dev=$new_development, docs=$new_documentation, infra=$new_infrastructure" "$SCRIPT_NAME"
  return 0
}

# Function to record a new expense
# Usage: record_expense [DESCRIPTION] [AMOUNT] [CATEGORY]
record_expense() {
  if [[ $# -lt 3 ]]; then
    log_error "Missing required parameters for expense recording" "$SCRIPT_NAME"
    log_info "Usage: record_expense [DESCRIPTION] [AMOUNT] [CATEGORY]" "$SCRIPT_NAME"
    return 1
  fi
  
  expense_description="$1"
  amount="$2"
  category="$3"  # api_costs, development, documentation, infrastructure
  date=$(date +"%Y-%m-%d")
  
  log_info "Recording new expense: $expense_description for $amount in category $category" "$SCRIPT_NAME"
  
  # Validate amount is numeric
  if ! validate_numeric "$amount" "Amount" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Validate category
  valid_categories=("api_costs" "development" "documentation" "infrastructure")
  category_valid=0
  
  for valid_category in "${valid_categories[@]}"; do
    if [[ "$category" == "$valid_category" ]]; then
      category_valid=1
      break
    fi
  done
  
  if [[ $category_valid -eq 0 ]]; then
    log_error "Invalid expense category: $category. Must be one of: ${valid_categories[*]}" "$SCRIPT_NAME"
    return 1
  fi
  
  # Initialize Open Collective configuration if it doesn't exist
  if [[ ! -f "$OC_CONFIG_FILE" ]]; then
    log_info "Open Collective configuration file not found, initializing first" "$SCRIPT_NAME"
    if ! initialize_oc; then
      log_error "Failed to initialize Open Collective configuration" "$SCRIPT_NAME"
      return 1
    fi
  fi
  
  # Validate configuration file is writable
  if ! validate_writable "$OC_CONFIG_FILE" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Create expenses array if it doesn't exist
  if ! grep -q '"expenses":' "$OC_CONFIG_FILE"; then
    log_info "Adding expenses array to configuration file" "$SCRIPT_NAME"
    
    # Create a temporary file
    temp_file="${OC_CONFIG_FILE}.tmp"
    
    # Add expenses array before the closing brace
    awk '
      /}$/ && !added {
        print "  \"expenses\": []";
        print $0;
        added = 1;
        next;
      }
      {print}
    ' "$OC_CONFIG_FILE" > "$temp_file" || { log_error "Failed to add expenses array to configuration file" "$SCRIPT_NAME"; return 1; }
    
    # Move the temporary file to the original
    mv "$temp_file" "$OC_CONFIG_FILE" || { log_error "Failed to update Open Collective configuration file" "$SCRIPT_NAME"; return 1; }
  fi
  
  # Create a temporary file with proper error handling
  temp_file="${OC_CONFIG_FILE}.tmp"
  
  # Add the new expense to the expenses array
  awk -v desc="$expense_description" -v amount="$amount" -v category="$category" -v date="$date" '
    /"expenses": \[/ {
      print $0;
      print "    {";
      print "      \"description\": \"" desc "\",";
      print "      \"amount\": " amount ",";
      print "      \"category\": \"" category "\",";
      print "      \"date\": \"" date "\"";
      print "    },";
      next;
    }
    {print}
  ' "$OC_CONFIG_FILE" > "$temp_file" || { log_error "Failed to create temporary configuration file" "$SCRIPT_NAME"; return 1; }
  
  # Move the temporary file to the original
  mv "$temp_file" "$OC_CONFIG_FILE" || { log_error "Failed to update Open Collective configuration file" "$SCRIPT_NAME"; return 1; }
  
  log_info "Expense $expense_description added to $OC_CONFIG_FILE successfully" "$SCRIPT_NAME"
  
  # Update the funding usage for the specific category
  log_info "Updating funding usage for category: $category" "$SCRIPT_NAME"
  
  # Extract current value
  current_value=$(grep -o "\"$category\": [0-9.]*" "$OC_CONFIG_FILE" | awk '{print $2}' | head -n 1)
  
  # If we couldn't extract the value, use default
  if [ -z "$current_value" ]; then current_value=0; fi
  
  # Calculate new value
  new_value=$(echo "scale=2; $current_value - $amount" | bc)
  
  # Update the file with new value
  sed -e "s/\"$category\": $current_value/\"$category\": $new_value/g" "$OC_CONFIG_FILE" > "$temp_file" || { 
    log_error "Failed to update funding usage for category: $category" "$SCRIPT_NAME"
    return 1
  }
  
  # Move the temporary file to the original
  mv "$temp_file" "$OC_CONFIG_FILE" || { 
    log_error "Failed to replace Open Collective configuration file with updated funding usage" "$SCRIPT_NAME"
    return 1
  }
  
  log_info "Funding usage updated for category $category: $current_value -> $new_value" "$SCRIPT_NAME"
  return 0
}

#===================================
# API COST INTEGRATION
#===================================

# Function to record API usage (forwards to the github_sponsors.sh script)
record_api_usage() {
  if [[ $# -lt 2 ]]; then
    log_error "Missing required parameters for API usage tracking" "$SCRIPT_NAME"
    log_info "Usage: record_api_usage [NUM_TOKENS] [MODEL_NAME]" "$SCRIPT_NAME"
    return 1
  fi
  
  tokens="$1"
  model="$2"
  
  log_info "Forwarding API usage recording to central tracking system..." "$SCRIPT_NAME"
  
  # Validate API cost tracking script exists and is executable
  if [ ! -f "$API_COST_TRACKING_SCRIPT" ]; then
    log_error "API cost tracking script not found: $API_COST_TRACKING_SCRIPT" "$SCRIPT_NAME"
    return 1
  fi
  
  if [ ! -x "$API_COST_TRACKING_SCRIPT" ]; then
    log_error "API cost tracking script not executable: $API_COST_TRACKING_SCRIPT" "$SCRIPT_NAME"
    return 1
  fi
  
  # Forward the API usage recording to the central script
  "$API_COST_TRACKING_SCRIPT" record-usage "$tokens" "$model"
  exit_code=$?
  
  if [ $exit_code -ne 0 ]; then
    log_error "API usage recording failed with exit code: $exit_code" "$SCRIPT_NAME"
    return $exit_code
  fi
  
  # Also record an expense for the API usage
  # Calculate cost based on model
  cost=0
  case "$model" in
    "Claude-3-7-Sonnet"|"Claude 3.7 Sonnet")
      # Cost per token for Claude 3.7 Sonnet ($3 per million tokens)
      cost=$(echo "scale=6; $tokens * 0.000003" | bc)
      ;;
    "Claude-3-Opus"|"Claude 3 Opus")
      # Cost per token for Claude 3 Opus ($15 per million tokens)
      cost=$(echo "scale=6; $tokens * 0.000015" | bc)
      ;;
    *)
      # Default cost calculation for unknown models (using Sonnet pricing)
      cost=$(echo "scale=6; $tokens * 0.000003" | bc)
      log_warning "Unknown model '$model', using default pricing" "$SCRIPT_NAME"
      ;;
  esac
  
  # Only record expense if the cost is significant (at least one cent)
  if (( $(echo "$cost >= 0.01" | bc -l) )); then
    log_info "Recording expense for API usage: $tokens tokens of $model ($cost)" "$SCRIPT_NAME"
    
    # Round to 2 decimal places
    cost=$(echo "scale=2; $cost/1" | bc)
    
    # Record the expense
    record_expense "API usage: $tokens tokens of $model" "$cost" "api_costs"
    expense_code=$?
    
    if [ $expense_code -ne 0 ]; then
      log_warning "Failed to record expense for API usage, but usage was recorded" "$SCRIPT_NAME"
    fi
  else
    log_info "Cost too small (less than $0.01) to record as expense" "$SCRIPT_NAME"
  fi
  
  log_info "API usage recording successful: $tokens tokens for $model" "$SCRIPT_NAME"
  return 0
}

#===================================
# MAIN EXECUTION
#===================================

log_info "Starting Open Collective module..." "$SCRIPT_NAME"

case "$1" in
  "init")
    initialize_oc
    exit_code=$?
    ;;
  "button")
    generate_oc_button
    exit_code=$?
    ;;
  "setup")
    generate_oc_instructions
    exit_code=$?
    ;;
  "policy")
    generate_expense_policy
    exit_code=$?
    ;;
  "report")
    generate_transparency_report
    exit_code=$?
    ;;
  "record-contribution")
    if [[ $# -lt 4 ]]; then
      log_error "Missing parameters for contribution recording" "$SCRIPT_NAME"
      log_info "Usage: $0 record-contribution [NAME] [AMOUNT] [TYPE] [MESSAGE]" "$SCRIPT_NAME"
      exit_code=1
    else
      record_contribution "$2" "$3" "$4" "${5:-""}"
      exit_code=$?
    fi
    ;;
  "record-expense")
    if [[ $# -lt 4 ]]; then
      log_error "Missing parameters for expense recording" "$SCRIPT_NAME"
      log_info "Usage: $0 record-expense [DESCRIPTION] [AMOUNT] [CATEGORY]" "$SCRIPT_NAME"
      exit_code=1
    else
      record_expense "$2" "$3" "$4"
      exit_code=$?
    fi
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
    echo "Open Collective Integration Module"
    echo "--------------------------------"
    echo "Usage: $0 {init|button|setup|policy|report|record-contribution|record-expense|record-usage|help}"
    echo ""
    echo "Open Collective Management:"
    echo "  init                                   - Initialize Open Collective configuration"
    echo "  button                                 - Generate Open Collective button HTML/MD"
    echo "  setup                                  - Generate Open Collective setup instructions"
    echo "  policy                                 - Generate expense policy document"
    echo "  report                                 - Generate transparency report"
    echo "  record-contribution [N] [A] [T] [M]    - Record contribution from NAME of AMOUNT with TYPE (one-time/recurring) and MESSAGE"
    echo "  record-expense [D] [A] [C]             - Record expense with DESCRIPTION, AMOUNT, and CATEGORY"
    echo ""
    echo "API Usage Tracking:"
    echo "  record-usage [TOKENS] [MODEL]          - Record API usage and related expense"
    echo ""
    echo "General:"
    echo "  help                                   - Display this help information"
    exit_code=0
    ;;
  *)
    log_error "Unknown command: $1" "$SCRIPT_NAME"
    log_info "Run '$0 help' for usage information" "$SCRIPT_NAME"
    exit_code=1
    ;;
esac

log_info "Open Collective module completed with exit code: $exit_code" "$SCRIPT_NAME"
exit $exit_code