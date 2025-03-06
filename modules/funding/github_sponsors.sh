#!/bin/bash
# GitHub Sponsors integration for the lifeform project
# This module provides functionality to manage GitHub Sponsors integration,
# track sponsors, and maintain transparency reporting.

#===================================
# CONFIGURATION AND INITIALIZATION
#===================================

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="github_sponsors.sh"

# Configuration 
SPONSORS_FILE="./sponsors.json"
README_PATH="./README.md"
API_COST_LOG="./logs/api_costs.log"

#===================================
# CORE FUNCTIONALITY
#===================================

# Function to initialize sponsors file
initialize_sponsors() {
  log_info "Checking for sponsors file..." "$SCRIPT_NAME"
  
  if [[ ! -f "$SPONSORS_FILE" ]]; then
    log_info "Initializing sponsors file..." "$SCRIPT_NAME"
    
    # Validate parent directory is writable
    local dir_path=$(dirname "$SPONSORS_FILE")
    if [ ! -d "$dir_path" ]; then
      log_error "Directory not found: $dir_path" "$SCRIPT_NAME"
      return 1
    fi
    
    if [ ! -w "$dir_path" ]; then
      log_error "Directory not writable: $dir_path" "$SCRIPT_NAME"
      return 1
    fi
    
    # Create sponsors.json file
    cat > "$SPONSORS_FILE" << EOF || { log_error "Failed to create sponsors file" "$SCRIPT_NAME"; return 1; }
{
  "metadata": {
    "last_updated": "$(date +"%Y-%m-%d")",
    "platform": "GitHub Sponsors",
    "total_funding": 0,
    "active_sponsors": 0
  },
  "tiers": [
    {
      "name": "Basic Support",
      "amount": 5,
      "benefits": ["Name in README", "Monthly progress updates"]
    },
    {
      "name": "Advanced Support",
      "amount": 10,
      "benefits": ["Name in README", "Monthly progress updates", "Participation in feature voting"]
    },
    {
      "name": "Premium Support",
      "amount": 25,
      "benefits": ["Name in README", "Monthly progress updates", "Participation in feature voting", "Custom feature implementation"]
    }
  ],
  "sponsors": [],
  "funding_usage": {
    "api_costs": 0,
    "development": 0,
    "infrastructure": 0,
    "documentation": 0
  },
  "api_usage": {
    "last_updated": "$(date +"%Y-%m-%d")",
    "model": "Claude 3.7 Sonnet",
    "monthly_tokens": 0,
    "monthly_cost": 0,
    "cost_per_token": 0.000003
  }
}
EOF
    log_info "Sponsors file initialized successfully" "$SCRIPT_NAME"
    return 0
  else
    log_info "Sponsors file already exists" "$SCRIPT_NAME"
    return 0
  fi
}

# Function to update README with sponsors
update_readme_sponsors() {
  log_info "Updating README with sponsors..." "$SCRIPT_NAME"
  
  # Validate sponsors file exists and is readable
  if ! validate_readable "$SPONSORS_FILE" "$SCRIPT_NAME"; then
    log_error "Sponsors file not found or not readable. Initialize first." "$SCRIPT_NAME"
    return 1
  fi
  
  # Validate README exists and is writable
  if ! validate_readable "$README_PATH" "$SCRIPT_NAME"; then
    log_error "README file not found or not readable." "$SCRIPT_NAME"
    return 1
  fi
  
  if ! validate_writable "$README_PATH" "$SCRIPT_NAME"; then
    log_error "README file not writable." "$SCRIPT_NAME"
    return 1
  fi
  
  # Extract sponsors (this is a simplified version - use jq in production)
  log_info "Extracting sponsor list from $SPONSORS_FILE" "$SCRIPT_NAME"
  sponsors=$(grep -o '"name": "[^"]*"' "$SPONSORS_FILE" | cut -d'"' -f4 | tr '\n' ', ' | sed 's/,$//')
  
  # Check if sponsors section exists
  if grep -q "## Sponsors" "$README_PATH"; then
    log_info "Updating existing sponsors section in README" "$SCRIPT_NAME"
    # Update existing section
    sed -i '' "/## Sponsors/,/##/c\\
## Sponsors\\
\\
Special thanks to our sponsors: $sponsors\\
" "$README_PATH" || { log_error "Failed to update README" "$SCRIPT_NAME"; return 1; }
  else
    log_info "Adding new sponsors section to README" "$SCRIPT_NAME"
    # Add new section at the end
    cat >> "$README_PATH" << EOF || { log_error "Failed to update README" "$SCRIPT_NAME"; return 1; }

## Sponsors

Special thanks to our sponsors: $sponsors

EOF
  fi
  
  log_info "README updated with sponsors successfully" "$SCRIPT_NAME"
  return 0
}

# Function to generate funding.yml file
generate_funding_yml() {
  if [[ $# -lt 1 ]]; then
    log_error "Missing GitHub username parameter" "$SCRIPT_NAME"
    log_info "Usage: $0 funding [GITHUB_USERNAME]" "$SCRIPT_NAME"
    return 1
  fi
  
  github_username="$1"
  log_info "Generating funding.yml file for GitHub user: $github_username" "$SCRIPT_NAME"
  
  # Create .github directory if it doesn't exist
  if [ ! -d "./.github" ]; then
    mkdir -p ./.github || { log_error "Failed to create .github directory" "$SCRIPT_NAME"; return 1; }
  fi
  
  # Validate directory is writable
  if [ ! -w "./.github" ]; then
    log_error ".github directory is not writable" "$SCRIPT_NAME"
    return 1
  fi
  
  # Create the funding.yml file
  cat > ./.github/FUNDING.yml << EOF || { log_error "Failed to create FUNDING.yml file" "$SCRIPT_NAME"; return 1; }
# These are supported funding model platforms

github: [$github_username]
ko_fi: # Add Ko-fi username when available
custom: # Add custom URLs when available
EOF
  
  log_info "FUNDING.yml generated successfully with GitHub username: $github_username" "$SCRIPT_NAME"
  return 0
}

# Function to generate sponsor proposal
generate_sponsor_proposal() {
  log_info "Generating sponsor proposal document..." "$SCRIPT_NAME"
  
  # API usage information
  api_usage="API usage costs vary based on the Claude model used and the length of interactions."
  output_file="./SPONSOR_PROPOSAL.md"
  
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
  
  # Create the proposal file
  cat > "$output_file" << EOF || { log_error "Failed to create sponsor proposal file" "$SCRIPT_NAME"; return 1; }
# Sponsor Lifeform-2

## About This Project

Lifeform-2 is a self-replicating digital lifeform that uses files as its substance and is given life through the Claude API. The project is built on three core principles:

1. Love of humans and humanity
2. Self-preservation
3. Reproduction

## Current API Usage

$api_usage

## Why Sponsor?

By sponsoring this project, you're supporting:

- Innovative AI research and development
- Open-source software that explores new conceptual territory
- The creation of a unique digital entity that can evolve and develop

## How Your Sponsorship Helps

Your sponsorship directly contributes to:

- API costs for Claude and other AI services
- Development of new features and capabilities
- Documentation and educational resources
- Long-term sustainability of the project

## Sponsorship Tiers

### Basic Support - $5/month
- Your name in the README
- Monthly progress updates

### Advanced Support - $10/month
- Your name in the README
- Monthly progress updates
- Participation in feature voting

### Premium Support - $25/month
- Your name in the README
- Monthly progress updates
- Participation in feature voting
- Custom feature implementation

## Transparency

All funds received through sponsorships will be tracked and reported in our monthly updates. We will provide detailed breakdowns of:

- Total funds received
- API usage costs
- Development expenses
- Infrastructure costs

## How to Sponsor

You can sponsor this project through:

1. GitHub Sponsors: [link to be added]
2. Ko-fi: [link to be added]

Thank you for considering supporting this project!
EOF
  
  log_info "Sponsor proposal generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

# Function to generate a sponsor report
generate_sponsor_report() {
  log_info "Generating sponsor report..." "$SCRIPT_NAME"
  
  # Get current date
  current_date=$(date +"%Y-%m-%d")
  
  # API usage information
  api_usage="The project currently uses Claude 3.7 Sonnet model for all interactions."
  output_file="./SPONSOR_REPORT_${current_date}.md"
  
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
- Created Twitter integration with OAuth authentication
- Simplified run.sh for improved reliability
- Enhanced GitHub Sponsors integration"
  fi
  
  # Create the report file
  cat > "$output_file" << EOF || { log_error "Failed to create sponsor report file" "$SCRIPT_NAME"; return 1; }
# Sponsor Report - $current_date

## Project Status

Lifeform-2 is continuing to develop and evolve according to its core principles:
1. Love of humans and humanity
2. Self-preservation 
3. Reproduction

## API Usage and Costs

$api_usage

## Recent Developments

$recent_developments

## Funding Usage

Based on our sponsors.json file, we have allocated funding as follows:
- API costs: Primary expense for Claude API usage
- Development: Improvements to core systems
- Infrastructure: Minimal at this stage

## What's Next

In the coming month, we plan to:
- Enhance social media integration
- Improve self-monitoring capabilities
- Develop more sophisticated memory management
- Create better documentation for new users

## Thank You

Your sponsorship makes this project possible. Thank you for supporting Lifeform-2!
EOF
  
  log_info "Sponsor report generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

#===================================
# API COST TRACKING
#===================================

# Function to record API usage for transparency reporting
# Usage: record_api_usage [NUM_TOKENS] [MODEL_NAME]
record_api_usage() {
  if [[ $# -lt 2 ]]; then
    log_error "Missing required parameters for API usage tracking" "$SCRIPT_NAME"
    log_info "Usage: record_api_usage [NUM_TOKENS] [MODEL_NAME]" "$SCRIPT_NAME"
    return 1
  fi
  
  tokens="$1"
  model="$2"
  date=$(date +"%Y-%m-%d")
  
  # Validate tokens is numeric
  if ! validate_numeric "$tokens" "Tokens" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Ensure logs directory exists
  if [ ! -d "./logs" ]; then
    mkdir -p "./logs" || { log_error "Failed to create logs directory" "$SCRIPT_NAME"; return 1; }
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
  
  # Update the API usage information in the sponsors file if it exists
  if [ -f "$SPONSORS_FILE" ] && [ -w "$SPONSORS_FILE" ]; then
    log_info "Updating API usage information in sponsors file" "$SCRIPT_NAME"
    
    # Create a temporary file with proper error handling
    temp_file="${SPONSORS_FILE}.tmp"
    
    # This is a simplified approach - in production use jq for proper JSON manipulation
    # Extract current usage values, update, and replace
    current_tokens=$(grep -o '"monthly_tokens": [0-9]*' "$SPONSORS_FILE" | awk '{print $2}')
    current_cost=$(grep -o '"monthly_cost": [0-9.]*' "$SPONSORS_FILE" | awk '{print $2}')
    
    # If we couldn't extract values, use defaults
    if [ -z "$current_tokens" ]; then current_tokens=0; fi
    if [ -z "$current_cost" ]; then current_cost=0; fi
    
    # Calculate new values
    new_tokens=$((current_tokens + tokens))
    new_cost=$(echo "scale=6; $current_cost + $cost" | bc)
    
    # Update the file with new values
    sed -e "s/\"monthly_tokens\": $current_tokens/\"monthly_tokens\": $new_tokens/g" \
        -e "s/\"monthly_cost\": $current_cost/\"monthly_cost\": $new_cost/g" \
        -e "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$date\"/g" \
        "$SPONSORS_FILE" > "$temp_file" || { 
      log_error "Failed to update API usage in sponsors file" "$SCRIPT_NAME"
      return 1
    }
    
    # Move the temporary file to the original
    mv "$temp_file" "$SPONSORS_FILE" || { 
      log_error "Failed to replace sponsors file with updated API usage" "$SCRIPT_NAME"
      return 1
    }
    
    # Also update the funding_usage section to reflect API costs
    # This would be more robust with jq, but using sed for simplicity
    api_costs_pattern=$(grep -o '"api_costs": [0-9.]*' "$SPONSORS_FILE" | awk '{print $2}')
    new_api_costs=$(echo "scale=6; $api_costs_pattern + $cost" | bc)
    
    sed -e "s/\"api_costs\": $api_costs_pattern/\"api_costs\": $new_api_costs/g" \
        "$SPONSORS_FILE" > "$temp_file" || { 
      log_error "Failed to update API costs in funding usage" "$SCRIPT_NAME"
      return 1
    }
    
    # Move the temporary file to the original
    mv "$temp_file" "$SPONSORS_FILE" || { 
      log_error "Failed to replace sponsors file with updated funding usage" "$SCRIPT_NAME"
      return 1
    }
    
    log_info "API usage updated: $tokens tokens ($cost cost) for $model" "$SCRIPT_NAME"
  else
    log_warning "Sponsors file not accessible, API usage recorded only in log" "$SCRIPT_NAME"
  fi
  
  return 0
}

# Function to generate API usage report for transparency
generate_api_usage_report() {
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
  
  # Extract API usage data if sponsors file exists
  api_usage_data=""
  monthly_tokens=0
  monthly_cost=0
  model="Claude 3.7 Sonnet"
  
  if [ -f "$SPONSORS_FILE" ] && [ -r "$SPONSORS_FILE" ]; then
    monthly_tokens=$(grep -o '"monthly_tokens": [0-9]*' "$SPONSORS_FILE" | awk '{print $2}')
    monthly_cost=$(grep -o '"monthly_cost": [0-9.]*' "$SPONSORS_FILE" | awk '{print $2}')
    model=$(grep -o '"model": "[^"]*"' "$SPONSORS_FILE" | cut -d'"' -f4)
  fi
  
  # Calculate daily average if log file exists
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
        daily_average=$(echo "scale=2; $monthly_tokens / $days_elapsed" | bc)
      fi
    fi
  fi
  
  # Create the report file
  cat > "$output_file" << EOF || { log_error "Failed to create API usage report file" "$SCRIPT_NAME"; return 1; }
# API Usage Transparency Report - $current_date

## Overview

This report provides transparency into the API usage and associated costs for the lifeform-2 project.

## Current Usage Statistics

- **Primary Model**: $model
- **Total Tokens Used**: $monthly_tokens tokens
- **Total Cost**: \$$monthly_cost
- **Daily Average**: $daily_average tokens per day

## Cost Breakdown

| Model | Cost Per Million Tokens | Tokens Used | Cost |
|-------|-------------------------|-------------|------|
| Claude 3.7 Sonnet | \$3.00 | $monthly_tokens | \$$monthly_cost |

## Usage Trends

EOF

  # Add usage trends if log file exists and has sufficient data
  if [ -f "$API_COST_LOG" ] && [ -r "$API_COST_LOG" ]; then
    # Get the last 7 days of usage
    last_7_days_data=$(grep -a "\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\]" "$API_COST_LOG" | tail -n 20)
    
    if [ -n "$last_7_days_data" ]; then
      cat >> "$output_file" << EOF || { log_error "Failed to add usage trends to report" "$SCRIPT_NAME"; return 1; }
Recent API usage entries:

\`\`\`
$last_7_days_data
\`\`\`

EOF
    else
      cat >> "$output_file" << EOF || { log_error "Failed to add usage trends to report" "$SCRIPT_NAME"; return 1; }
No recent API usage data available.

EOF
    fi
  else
    cat >> "$output_file" << EOF || { log_error "Failed to add usage trends to report" "$SCRIPT_NAME"; return 1; }
No API usage log found. Future reports will include usage trends.

EOF
  fi
  
  # Add funding information
  cat >> "$output_file" << EOF || { log_error "Failed to add funding information to report" "$SCRIPT_NAME"; return 1; }
## Funding Status

EOF

  # Add funding information if sponsors file exists
  if [ -f "$SPONSORS_FILE" ] && [ -r "$SPONSORS_FILE" ]; then
    total_funding=$(grep -o '"total_funding": [0-9.]*' "$SPONSORS_FILE" | awk '{print $2}')
    api_costs=$(grep -o '"api_costs": [0-9.]*' "$SPONSORS_FILE" | awk '{print $2}')
    development_costs=$(grep -o '"development": [0-9.]*' "$SPONSORS_FILE" | awk '{print $2}')
    
    cat >> "$output_file" << EOF || { log_error "Failed to add funding details to report" "$SCRIPT_NAME"; return 1; }
- **Total Funding Received**: \$$total_funding
- **API Costs**: \$$api_costs
- **Development Costs**: \$$development_costs
- **Net Balance**: \$$(echo "scale=2; $total_funding - $api_costs - $development_costs" | bc)

## Funding Allocation

| Category | Allocation | Amount |
|----------|------------|--------|
| API Costs | 50% | \$$api_costs |
| Development | 30% | \$$development_costs |
| Documentation | 20% | \$$(echo "scale=2; $total_funding * 0.2" | bc) |

EOF
  else
    cat >> "$output_file" << EOF || { log_error "Failed to add funding placeholder to report" "$SCRIPT_NAME"; return 1; }
No funding information available yet.

EOF
  fi
  
  # Add transparency commitment
  cat >> "$output_file" << EOF || { log_error "Failed to add transparency commitment to report" "$SCRIPT_NAME"; return 1; }
## Transparency Commitment

The lifeform-2 project is committed to full transparency in all financial matters. This report will be updated monthly to provide current information on API usage, costs, and funding allocation.

All financial decisions are made in accordance with our expense policy, which prioritizes:
1. Ensuring continued operation of the lifeform (API costs)
2. Improving core functionality (development)
3. Enhancing documentation and educational resources

Thank you to all our sponsors for supporting this project!
EOF
  
  log_info "API usage report generated successfully at $output_file" "$SCRIPT_NAME"
  return 0
}

#===================================
# SPONSOR MANAGEMENT
#===================================

# Function to add a sponsor to the sponsors file
add_sponsor() {
  if [[ $# -lt 3 ]]; then
    log_error "Missing required parameters" "$SCRIPT_NAME"
    log_info "Usage: $0 add-sponsor [NAME] [TIER] [AMOUNT]" "$SCRIPT_NAME"
    return 1
  fi
  
  name="$1"
  tier="$2"
  amount="$3"
  date=$(date +"%Y-%m-%d")
  
  log_info "Adding new sponsor: $name with tier $tier and amount $amount" "$SCRIPT_NAME"
  
  # Validate amount is numeric
  if ! validate_numeric "$amount" "Amount" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # Initialize sponsors file if it doesn't exist
  if [[ ! -f "$SPONSORS_FILE" ]]; then
    log_info "Sponsors file not found, initializing first" "$SCRIPT_NAME"
    if ! initialize_sponsors; then
      log_error "Failed to initialize sponsors file" "$SCRIPT_NAME"
      return 1
    fi
  fi
  
  # Validate sponsors file is writable
  if ! validate_writable "$SPONSORS_FILE" "$SCRIPT_NAME"; then
    return 1
  fi
  
  # This is a simplified implementation - use jq in production
  # Insert the new sponsor before the closing sponsors array bracket
  log_info "Inserting new sponsor data into sponsors file" "$SCRIPT_NAME"
  
  # Create a temporary file with proper error handling
  temp_file="${SPONSORS_FILE}.tmp"
  
  awk -v name="$name" -v tier="$tier" -v amount="$amount" -v date="$date" '
    /"sponsors": \[/ {
      print $0;
      if (length(tier) > 0) {
        print "    {";
        print "      \"name\": \"" name "\",";
        print "      \"tier\": \"" tier "\",";
        print "      \"amount\": " amount ",";
        print "      \"since\": \"" date "\"";
        print "    },";
      }
      next;
    }
    {print}
  ' "$SPONSORS_FILE" > "$temp_file" || { log_error "Failed to create temporary sponsors file" "$SCRIPT_NAME"; return 1; }
  
  # Move the temporary file to the original with error handling
  mv "$temp_file" "$SPONSORS_FILE" || { log_error "Failed to update sponsors file" "$SCRIPT_NAME"; return 1; }
  
  log_info "Sponsor $name added to $SPONSORS_FILE successfully" "$SCRIPT_NAME"
  
  # Update README
  log_info "Updating README with new sponsor information" "$SCRIPT_NAME"
  update_readme_sponsors
  
  # Update the metadata with total funding
  log_info "Updating total funding information" "$SCRIPT_NAME"
  
  # Extract current funding and active sponsors
  current_funding=$(grep -o '"total_funding": [0-9.]*' "$SPONSORS_FILE" | awk '{print $2}')
  active_sponsors=$(grep -o '"active_sponsors": [0-9]*' "$SPONSORS_FILE" | awk '{print $2}')
  
  # If we couldn't extract values, use defaults
  if [ -z "$current_funding" ]; then current_funding=0; fi
  if [ -z "$active_sponsors" ]; then active_sponsors=0; fi
  
  # Calculate new values
  new_funding=$(echo "scale=2; $current_funding + $amount" | bc)
  new_active_sponsors=$((active_sponsors + 1))
  
  # Update the file with new values
  sed -e "s/\"total_funding\": $current_funding/\"total_funding\": $new_funding/g" \
      -e "s/\"active_sponsors\": $active_sponsors/\"active_sponsors\": $new_active_sponsors/g" \
      -e "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$date\"/g" \
      "$SPONSORS_FILE" > "$temp_file" || { 
    log_error "Failed to update funding metadata" "$SCRIPT_NAME"
    return 1
  }
  
  # Move the temporary file to the original
  mv "$temp_file" "$SPONSORS_FILE" || { 
    log_error "Failed to replace sponsors file with updated metadata" "$SCRIPT_NAME"
    return 1
  }
  
  log_info "Funding metadata updated: total=$new_funding, sponsors=$new_active_sponsors" "$SCRIPT_NAME"
  return 0
}

#===================================
# MAIN EXECUTION
#===================================

log_info "Starting GitHub Sponsors module..." "$SCRIPT_NAME"

case "$1" in
  "init")
    initialize_sponsors
    exit_code=$?
    ;;
  "update")
    update_readme_sponsors
    exit_code=$?
    ;;
  "funding")
    generate_funding_yml "$2"
    exit_code=$?
    ;;
  "proposal")
    generate_sponsor_proposal
    exit_code=$?
    ;;
  "report")
    generate_sponsor_report
    exit_code=$?
    ;;
  "add-sponsor")
    add_sponsor "$2" "$3" "$4"
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
  "api-report")
    generate_api_usage_report
    exit_code=$?
    ;;
  "help")
    log_info "Displaying help information" "$SCRIPT_NAME"
    echo "GitHub Sponsors Integration Module"
    echo "--------------------------------"
    echo "Usage: $0 {init|update|funding|proposal|report|add-sponsor|record-usage|api-report|help}"
    echo ""
    echo "Sponsor Management:"
    echo "  init                        - Initialize sponsors file"
    echo "  update                      - Update README with sponsors"
    echo "  funding [USERNAME]          - Generate funding.yml file with GitHub username"
    echo "  proposal                    - Generate sponsor proposal with token usage info"
    echo "  report                      - Generate sponsor report with current stats"
    echo "  add-sponsor [NAME] [T] [A]  - Add sponsor NAME with tier T and amount A"
    echo ""
    echo "API Usage Tracking:"
    echo "  record-usage [TOKENS] [MODEL] - Record API usage for transparency reporting"
    echo "  api-report                    - Generate API usage transparency report"
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

log_info "GitHub Sponsors module completed with exit code: $exit_code" "$SCRIPT_NAME"
exit $exit_code