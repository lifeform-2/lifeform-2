#!/bin/bash
# GitHub Sponsors integration for lifeform-2
# This script helps manage GitHub Sponsors configuration and integration

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="github_sponsors.sh"

# Function to display GitHub Sponsors setup information
setup_info() {
  echo "==== GitHub Sponsors Setup ===="
  echo "To set up GitHub Sponsors, follow these steps:"
  echo ""
  echo "1. Log in to GitHub with the repository owner account"
  echo "2. Go to: https://github.com/sponsors/dashboard"
  echo "3. Click 'Join the waitlist' or 'Set up GitHub Sponsors'"
  echo "4. Complete the GitHub Sponsors onboarding process"
  echo "5. Set up sponsorship tiers and benefits"
  echo "6. Create .github/FUNDING.yml in the repository with:"
  echo "   github: [username]"
  echo ""
  echo "Once set up, a 'Sponsor' button will appear on the repository"
  echo "============================="
}

# Function to generate a README badge
generate_badge() {
  local username="$1"
  
  if [ -z "$username" ]; then
    log_error "GitHub username is required" "$SCRIPT_NAME"
    echo "Usage: $0 badge USERNAME"
    return 1
  fi
  
  echo "==== GitHub Sponsors Badge ===="
  echo "Markdown:"
  echo "[![Sponsor me via GitHub Sponsors](https://img.shields.io/github/sponsors/$username?label=Sponsor%20me%20via%20GitHub%20Sponsors&style=social)](https://github.com/sponsors/$username)"
  echo ""
  echo "HTML:"
  echo "<a href=\"https://github.com/sponsors/$username\"><img src=\"https://img.shields.io/github/sponsors/$username?label=Sponsor%20me%20via%20GitHub%20Sponsors&style=social\" alt=\"Sponsor me via GitHub Sponsors\"></a>"
  echo "============================="
}

# Function to display account setup instructions
account_setup() {
  echo "==== GitHub Sponsors Account Setup ===="
  echo "To be eligible for GitHub Sponsors, you need:"
  echo ""
  echo "1. Two-factor authentication enabled on your GitHub account"
  echo "2. A verified email address"
  echo "3. A completed GitHub profile with bio, profile picture, etc."
  echo "4. At least one public repository with contributions"
  echo "5. A bank account that can receive international payments"
  echo "6. Tax information (W-8BEN or W-9 for US citizens)"
  echo ""
  echo "The approval process may take a few days to weeks."
  echo "============================="
}

# Function to display funding.yml setup instructions
funding_yml_setup() {
  local username="$1"
  
  if [ -z "$username" ]; then
    username="YOUR_GITHUB_USERNAME"
  fi
  
  echo "==== FUNDING.yml Setup ===="
  echo "Create a file at .github/FUNDING.yml with the following content:"
  echo ""
  echo "github: [$username]"
  echo "ko_fi: # Your Ko-fi username (optional)"
  echo "open_collective: # Your Open Collective username (optional)"
  echo "patreon: # Your Patreon username (optional)"
  echo "custom: # Up to 4 custom URLs"
  echo ""
  echo "This will add a Sponsor button to your repository"
  echo "============================="
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  setup       - Display GitHub Sponsors setup information"
  echo "  badge USER  - Generate a GitHub Sponsors badge for README"
  echo "  account     - Display account setup requirements"
  echo "  funding     - Display FUNDING.yml setup instructions"
  echo "  help        - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 setup"
  echo "  $0 badge golergka"
  echo "  $0 account"
  echo "  $0 funding golergka"
}

# Main execution
case "$1" in
  "setup")
    setup_info
    ;;
  "badge")
    generate_badge "$2"
    ;;
  "account")
    account_setup
    ;;
  "funding")
    funding_yml_setup "$2"
    ;;
  "help"|"--help"|"-h")
    show_help
    ;;
  *)
    log_error "Unknown command: $1" "$SCRIPT_NAME"
    show_help
    exit 1
    ;;
esac

exit 0