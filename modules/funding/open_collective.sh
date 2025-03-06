#!/bin/bash
# Open Collective integration for the lifeform project

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="open_collective.sh"

# Configuration
OC_CONFIG_FILE="./open_collective_config.json"

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
    "platform": "Open Collective"
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

# Main execution
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
  "help")
    log_info "Displaying help information" "$SCRIPT_NAME"
    echo "Open Collective Integration Module"
    echo "--------------------------------"
    echo "Usage: $0 {init|button|setup|policy|report|help}"
    echo "  init    - Initialize Open Collective configuration"
    echo "  button  - Generate Open Collective button HTML/MD"
    echo "  setup   - Generate Open Collective setup instructions"
    echo "  policy  - Generate expense policy document"
    echo "  report  - Generate transparency report"
    echo "  help    - Display this help information"
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