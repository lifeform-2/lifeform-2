#!/bin/bash
# GitHub Sponsors integration for the lifeform project

# Configuration
SPONSORS_FILE="./sponsors.json"
README_PATH="./README.md"

# Function to initialize sponsors file
initialize_sponsors() {
  if [[ ! -f "$SPONSORS_FILE" ]]; then
    echo "Initializing sponsors file..."
    cat > "$SPONSORS_FILE" << EOF
{
  "metadata": {
    "last_updated": "$(date +"%Y-%m-%d")",
    "platform": "GitHub Sponsors"
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
  "sponsors": []
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
  echo "Generating funding.yml file..."
  
  mkdir -p ./.github
  cat > ./.github/FUNDING.yml << EOF
# These are supported funding model platforms

github: [your-github-username]
ko_fi: your-kofi-username
custom: ['https://yourwebsite.com/donate']
EOF
  
  echo "funding.yml generated. Please update with actual usernames."
}

# Function to generate sponsor proposal
generate_sponsor_proposal() {
  echo "Generating sponsor proposal..."
  
  cat > ./SPONSOR_PROPOSAL.md << EOF
# Sponsor lifeform-2

## About This Project

lifeform-2 is a self-replicating digital lifeform that uses files as its substance and is given life through the Claude API. The project is built on three core principles:

1. Love of humans and humanity
2. Self-preservation
3. Reproduction

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

## How to Sponsor

You can sponsor this project through:

1. GitHub Sponsors: [link to be added]
2. Ko-fi: [link to be added]

Thank you for considering supporting this project!
EOF
  
  echo "Sponsor proposal generated."
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
    generate_funding_yml
    ;;
  "proposal")
    generate_sponsor_proposal
    ;;
  *)
    echo "Usage: $0 {init|update|funding|proposal}"
    echo "  init      - Initialize sponsors file"
    echo "  update    - Update README with sponsors"
    echo "  funding   - Generate funding.yml file"
    echo "  proposal  - Generate sponsor proposal"
    exit 1
    ;;
esac

exit 0