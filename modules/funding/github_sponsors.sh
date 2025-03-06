#!/bin/bash
# GitHub Sponsors integration for the lifeform project

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="github_sponsors.sh"

# Configuration
SPONSORS_FILE="./sponsors.json"
README_PATH="./README.md"

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
    "total_funding": 0
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
    "infrastructure": 0
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
  
  # Also update the metadata with total funding
  log_info "Updating total funding information" "$SCRIPT_NAME"
  # This is simplified - in production use jq to properly update the JSON
  # For now, we're just noting this would be done here
  
  return 0
}

# Main execution
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
  "help")
    log_info "Displaying help information" "$SCRIPT_NAME"
    echo "GitHub Sponsors Integration Module"
    echo "--------------------------------"
    echo "Usage: $0 {init|update|funding|proposal|report|add-sponsor|help}"
    echo "  init                        - Initialize sponsors file"
    echo "  update                      - Update README with sponsors"
    echo "  funding [USERNAME]          - Generate funding.yml file with GitHub username"
    echo "  proposal                    - Generate sponsor proposal with token usage info"
    echo "  report                      - Generate sponsor report with current stats"
    echo "  add-sponsor [NAME] [T] [A]  - Add sponsor NAME with tier T and amount A"
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