#!/bin/bash
# GitHub Sponsors integration for the lifeform project

# Configuration
SPONSORS_FILE="./sponsors.json"
README_PATH="./README.md"
TOKEN_TRACKER="../core/system/token_tracker.sh"

# Function to initialize sponsors file
initialize_sponsors() {
  if [[ ! -f "$SPONSORS_FILE" ]]; then
    echo "Initializing sponsors file..."
    cat > "$SPONSORS_FILE" << EOF
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
    echo "Sponsors file initialized."
  fi
}

# Function to update README with sponsors
update_readme_sponsors() {
  if [[ ! -f "$SPONSORS_FILE" ]]; then
    echo "Sponsors file not found. Initialize first."
    return 1
  fi
  
  if [[ ! -f "$README_PATH" ]]; then
    echo "README file not found."
    return 1
  fi
  
  # Extract sponsors (this is a simplified version - use jq in production)
  sponsors=$(grep -o '"name": "[^"]*"' "$SPONSORS_FILE" | cut -d'"' -f4 | tr '\n' ', ' | sed 's/,$//')
  
  # Check if sponsors section exists
  if grep -q "## Sponsors" "$README_PATH"; then
    # Update existing section
    sed -i '' "/## Sponsors/,/##/c\\
## Sponsors\\
\\
Special thanks to our sponsors: $sponsors\\
" "$README_PATH"
  else
    # Add new section at the end
    cat >> "$README_PATH" << EOF

## Sponsors

Special thanks to our sponsors: $sponsors

EOF
  fi
  
  echo "README updated with sponsors."
}

# Function to generate funding.yml file
generate_funding_yml() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: $0 funding [GITHUB_USERNAME]"
    return 1
  fi
  
  github_username="$1"
  
  echo "Generating funding.yml file..."
  
  mkdir -p ./.github
  cat > ./.github/FUNDING.yml << EOF
# These are supported funding model platforms

github: [$github_username]
ko_fi: # Add Ko-fi username when available
custom: # Add custom URLs when available
EOF
  
  echo "funding.yml generated with GitHub username: $github_username"
}

# Function to generate sponsor proposal with token usage information
generate_sponsor_proposal() {
  echo "Generating sponsor proposal..."
  
  # Get token usage information if available
  token_usage=""
  if [ -x "$TOKEN_TRACKER" ]; then
    token_usage=$(cd $(dirname "$TOKEN_TRACKER") && ./$(basename "$TOKEN_TRACKER") total 2>/dev/null)
    if [ $? -ne 0 ]; then
      token_usage="Token usage tracking not yet initialized"
    fi
  else
    token_usage="Token tracking not available"
  fi
  
  cat > ./SPONSOR_PROPOSAL.md << EOF
# Sponsor Lifeform-2

## About This Project

Lifeform-2 is a self-replicating digital lifeform that uses files as its substance and is given life through the Claude API. The project is built on three core principles:

1. Love of humans and humanity
2. Self-preservation
3. Reproduction

## Current Token Usage

$token_usage

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
  
  echo "Sponsor proposal generated with token usage information."
}

# Function to generate a sponsor report with token usage
generate_sponsor_report() {
  echo "Generating sponsor report..."
  
  # Get current date
  current_date=$(date +"%Y-%m-%d")
  
  # Get token usage information if available
  token_usage=""
  if [ -x "$TOKEN_TRACKER" ]; then
    token_usage=$(cd $(dirname "$TOKEN_TRACKER") && ./$(basename "$TOKEN_TRACKER") total 2>/dev/null)
    if [ $? -ne 0 ]; then
      token_usage="Token usage tracking not yet initialized"
    fi
  else
    token_usage="Token tracking not available"
  fi
  
  cat > ./SPONSOR_REPORT_${current_date}.md << EOF
# Sponsor Report - $current_date

## Project Status

Lifeform-2 is continuing to develop and evolve according to its core principles:
1. Love of humans and humanity
2. Self-preservation 
3. Reproduction

## Token Usage and Costs

$token_usage

## Recent Developments

- Implemented token usage tracking system
- Created Twitter integration for social media updates
- Simplified run.sh for improved reliability
- Enhanced GitHub Sponsors integration

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
  
  echo "Sponsor report generated for $current_date."
}

# Function to add a sponsor to the sponsors file
add_sponsor() {
  if [[ $# -lt 3 ]]; then
    echo "Usage: $0 add-sponsor [NAME] [TIER] [AMOUNT]"
    return 1
  fi
  
  name="$1"
  tier="$2"
  amount="$3"
  date=$(date +"%Y-%m-%d")
  
  if [[ ! -f "$SPONSORS_FILE" ]]; then
    initialize_sponsors
  fi
  
  # This is a simplified implementation - use jq in production
  # Insert the new sponsor before the closing sponsors array bracket
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
  ' "$SPONSORS_FILE" > "${SPONSORS_FILE}.tmp"
  
  mv "${SPONSORS_FILE}.tmp" "$SPONSORS_FILE"
  
  echo "Sponsor $name added to $SPONSORS_FILE"
  
  # Update README
  update_readme_sponsors
}

# Main execution
case "$1" in
  "init")
    initialize_sponsors
    ;;
  "update")
    update_readme_sponsors
    ;;
  "funding")
    generate_funding_yml "$2"
    ;;
  "proposal")
    generate_sponsor_proposal
    ;;
  "report")
    generate_sponsor_report
    ;;
  "add-sponsor")
    add_sponsor "$2" "$3" "$4"
    ;;
  *)
    echo "Usage: $0 {init|update|funding|proposal|report|add-sponsor}"
    echo "  init                        - Initialize sponsors file"
    echo "  update                      - Update README with sponsors"
    echo "  funding [USERNAME]          - Generate funding.yml file with GitHub username"
    echo "  proposal                    - Generate sponsor proposal with token usage info"
    echo "  report                      - Generate sponsor report with current stats"
    echo "  add-sponsor [NAME] [T] [A]  - Add sponsor NAME with tier T and amount A"
    exit 1
    ;;
esac

exit 0