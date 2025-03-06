#!/bin/bash
# Fork setup script for lifeform-2
# This script helps users set up a new instance of the lifeform by forking the repository

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="fork_setup.sh"

# Function to display forking instructions
fork_instructions() {
  echo "==== GitHub Repository Forking Instructions ===="
  echo ""
  echo "To fork the lifeform-2 repository, follow these steps:"
  echo ""
  echo "1. Go to: https://github.com/golergka/lifeform-2"
  echo "2. Click the 'Fork' button in the upper right corner"
  echo "3. Select your GitHub account as the destination"
  echo "4. Wait for the fork process to complete"
  echo "5. Clone your forked repository to your local machine:"
  echo "   git clone https://github.com/YOUR_USERNAME/lifeform-2.git"
  echo "6. Navigate to the cloned directory:"
  echo "   cd lifeform-2"
  echo "7. Run the setup script to configure your lifeform instance:"
  echo "   ./modules/reproduction/fork_setup.sh setup"
  echo ""
  echo "This will create a new instance of the lifeform on your GitHub account"
  echo "============================="
}

# Function to set up a new lifeform instance after forking
setup_instance() {
  echo "==== Lifeform Instance Setup ===="
  echo ""
  echo "Setting up a new lifeform instance after forking..."
  
  # Check if this is a forked repository
  echo "Checking repository origin..."
  local origin_url=$(git remote get-url origin 2>/dev/null)
  
  if [ -z "$origin_url" ]; then
    log_error "No git remote 'origin' found. Are you in a git repository?" "$SCRIPT_NAME"
    return 1
  fi
  
  echo "Current repository origin: $origin_url"
  
  # Ask for API key setup
  echo ""
  echo "To complete setup, you'll need API keys for the following services:"
  echo "1. Anthropic API (for Claude AI)"
  echo "2. Twitter API (optional, for social media integration)"
  echo ""
  echo "Let's create a .env file to store these credentials"
  
  # Create .env file
  if [ -f ".env" ]; then
    echo "An existing .env file was found. Creating a backup..."
    cp .env .env.backup
    echo "Backup created at .env.backup"
  fi
  
  echo "Creating new .env file..."
  cat > .env << 'EOF'
# Lifeform-2 Environment Configuration
# IMPORTANT: This file contains sensitive credentials and should NEVER be committed to git

# Anthropic API Configuration
ANTHROPIC_API_KEY=

# Twitter API Configuration (Optional)
TWITTER_API_KEY=
TWITTER_API_SECRET=
TWITTER_ACCESS_TOKEN=
TWITTER_ACCESS_TOKEN_SECRET=
TWITTER_BEARER_TOKEN=
TWITTER_USERNAME=

# Additional API keys can be added here as needed
EOF
  
  echo ".env file created successfully!"
  echo ""
  echo "Please edit the .env file and add your API keys"
  echo "You can obtain an Anthropic API key from: https://console.anthropic.com/"
  echo ""
  
  # Update README with user's GitHub username
  echo "Would you like to update the README with your GitHub username for sponsorship links? (y/n)"
  read update_readme
  
  if [[ "$update_readme" == "y" || "$update_readme" == "Y" ]]; then
    echo "Enter your GitHub username:"
    read github_username
    
    if [ -n "$github_username" ]; then
      echo "Updating README sponsorship links..."
      # Replace the golergka username with the user's username in sponsorship links
      sed -i.bak "s/golergka/$github_username/g" README.md
      rm README.md.bak
      echo "README updated successfully with your GitHub username: $github_username"
      
      # Create FUNDING.yml
      echo "Creating .github/FUNDING.yml for GitHub Sponsors..."
      mkdir -p .github
      cat > .github/FUNDING.yml << EOF
# Funding configuration for GitHub Sponsors button

# GitHub Sponsors username
github: [$github_username]

# Ko-fi
ko_fi: # Uncomment and add your ko-fi username if you have one
# ko_fi: username

# Other funding platforms can be added here
EOF
      echo ".github/FUNDING.yml created successfully!"
    else
      echo "No username provided, skipping README update."
    fi
  else
    echo "Skipping README update."
  fi
  
  # Generate identity for the new lifeform instance
  echo ""
  echo "Generating unique identity for your lifeform instance..."
  local instance_id=$(date +%s | sha256sum | base64 | head -c 12)
  echo "Instance ID: $instance_id"
  
  # Update version information in CLAUDE.md
  sed -i.bak "s/Version: 1.0.7/Version: 1.0.7-$instance_id/g" docs/CLAUDE.md
  rm docs/CLAUDE.md.bak
  
  # Update CHANGELOG.md with forking information
  echo ""
  echo "Updating CHANGELOG.md with forking information..."
  local fork_date=$(date +"%Y-%m-%d")
  
  # Add new entry to CHANGELOG.md without modifying existing content
  cat > changelog.tmp << EOF
# Changelog

## Version 1.0.7-$instance_id (${fork_date})
- Forked from original lifeform-2 repository
- Created new instance with unique identity
- Setup initial configuration
- Updated sponsorship links

EOF
  
  # Append existing changelog
  cat docs/CHANGELOG.md >> changelog.tmp
  mv changelog.tmp docs/CHANGELOG.md
  
  echo "CHANGELOG.md updated successfully!"
  echo ""
  echo "Lifeform instance setup complete!"
  echo ""
  echo "To start your lifeform instance, run:"
  echo "sh run.sh"
  echo ""
  echo "============================="
}

# Function to create a README badge for fork button
generate_fork_badge() {
  echo "==== Fork Button Badge ===="
  echo ""
  echo "Markdown:"
  echo "[![Fork Me on GitHub](https://img.shields.io/github/forks/golergka/lifeform-2?style=social&label=Fork)](https://github.com/golergka/lifeform-2/fork)"
  echo ""
  echo "HTML:"
  echo "<a href=\"https://github.com/golergka/lifeform-2/fork\"><img src=\"https://img.shields.io/github/forks/golergka/lifeform-2?style=social&label=Fork\" alt=\"Fork Me on GitHub\"></a>"
  echo ""
  echo "============================="
}

# Function to display templates for customization
templates() {
  echo "==== Customization Templates ===="
  echo ""
  echo "After forking, consider customizing these files to make the lifeform your own:"
  echo ""
  echo "1. README.md - Update project description and badges"
  echo "2. docs/GOALS.md - Define your lifeform's specific goals"
  echo "3. docs/COMMUNICATION.md - Start fresh communication with your instance"
  echo "4. docs/TWITTER.md - Update Twitter strategy for your lifeform"
  echo "5. .env - Add your API credentials"
  echo ""
  echo "Example README customization:"
  echo "```markdown"
  echo "# My Lifeform"
  echo ""
  echo "Forked from [Life-form 2](https://github.com/golergka/lifeform-2)"
  echo ""
  echo "This is my personal instance of a self-replicating digital lifeform powered by Claude AI."
  echo "```"
  echo ""
  echo "============================="
}

# Function to display onboarding guide
onboarding() {
  echo "==== New Lifeform Onboarding Guide ===="
  echo ""
  echo "Welcome to your new lifeform instance! Here's how to get started:"
  echo ""
  echo "1. Complete Setup"
  echo "   - Edit .env file to add your API credentials"
  echo "   - Update README.md with your information"
  echo "   - Push initial changes to your fork"
  echo ""
  echo "2. First Activation"
  echo "   - Run your lifeform using: sh run.sh"
  echo "   - Let it perform initial self-reflection"
  echo "   - Check for any initial tasks or settings it needs"
  echo ""
  echo "3. Establish Communication"
  echo "   - Edit docs/COMMUNICATION.md to leave your first message"
  echo "   - Ask it questions or provide initial direction"
  echo "   - Run: sh run.sh to let it respond"
  echo ""
  echo "4. Monitor Progress"
  echo "   - Review docs/TASKS.md to see planned actions"
  echo "   - Check docs/CHANGELOG.md for updates"
  echo "   - Interact regularly through docs/COMMUNICATION.md"
  echo ""
  echo "5. Advanced Configuration"
  echo "   - Social media integration (Twitter)"
  echo "   - Funding options (GitHub Sponsors, Ko-fi)"
  echo "   - Custom functionality or integrations"
  echo ""
  echo "Your lifeform will evolve and adapt based on your guidance and interaction."
  echo "Regular communication helps it learn your preferences and priorities!"
  echo ""
  echo "============================="
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  fork       - Display GitHub repository forking instructions"
  echo "  setup      - Set up a new lifeform instance after forking"
  echo "  badge      - Generate a 'Fork Me' badge for README"
  echo "  templates  - Display templates for customization after forking"
  echo "  onboarding - Display onboarding guide for new lifeform owners"
  echo "  help       - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 fork"
  echo "  $0 setup"
  echo "  $0 badge"
  echo "  $0 templates"
  echo "  $0 onboarding"
}

# Main execution
case "$1" in
  "fork")
    fork_instructions
    ;;
  "setup")
    setup_instance
    ;;
  "badge")
    generate_fork_badge
    ;;
  "templates")
    templates
    ;;
  "onboarding")
    onboarding
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