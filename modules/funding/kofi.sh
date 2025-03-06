#!/bin/bash
# Ko-fi integration for lifeform-2
# This script helps manage Ko-fi configuration and integration

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="kofi.sh"

# Function to display Ko-fi setup information
setup_info() {
  echo "==== Ko-fi Setup ===="
  echo "To set up Ko-fi, follow these steps:"
  echo ""
  echo "1. Go to: https://ko-fi.com/signup"
  echo "2. Sign up for an account"
  echo "3. Complete your profile with bio, picture, etc."
  echo "4. Set up your page with information about the project"
  echo "5. Add payment methods to receive funds"
  echo "6. Customize your Ko-fi page and button"
  echo ""
  echo "Ko-fi takes no fee for one-time donations"
  echo "There is a 5% fee for membership/subscription features"
  echo "============================="
}

# Function to generate a Ko-fi button
generate_button() {
  local username="$1"
  local color="$2"
  
  if [ -z "$username" ]; then
    log_error "Ko-fi username is required" "$SCRIPT_NAME"
    echo "Usage: $0 button USERNAME [COLOR]"
    echo "Colors: default (blue), red, green, orange, purple, yellow, black, white"
    return 1
  fi
  
  # Default to blue if no color specified
  if [ -z "$color" ]; then
    color="default"
  fi
  
  # Map color names to color codes
  case "$color" in
    "default"|"blue") button_color="00b9fe" ;;
    "red") button_color="FF5E5B" ;;
    "green") button_color="46B798" ;;
    "orange") button_color="F16F43" ;;
    "purple") button_color="8F6ADC" ;;
    "yellow") button_color="FFDD00" ;;
    "black") button_color="000000" ;;
    "white") button_color="ffffff" ;;
    *)
      log_error "Invalid color: $color" "$SCRIPT_NAME"
      echo "Available colors: default (blue), red, green, orange, purple, yellow, black, white"
      return 1
      ;;
  esac
  
  echo "==== Ko-fi Button ===="
  echo "Standard HTML Button:"
  echo "<a href='https://ko-fi.com/$username' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>"
  echo ""
  echo "Colored Button HTML:"
  echo "<a href='https://ko-fi.com/$username' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi5.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>"
  echo ""
  echo "Markdown for README:"
  echo "[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/$username)"
  echo "============================="
}

# Function to display account setup instructions
account_setup() {
  echo "==== Ko-fi Account Setup ===="
  echo "To set up a Ko-fi account, you need:"
  echo ""
  echo "1. A valid email address"
  echo "2. PayPal account or Stripe account for receiving payments"
  echo "3. Profile information including:"
  echo "   - Profile picture"
  echo "   - Cover image (recommended)"
  echo "   - About section describing your project"
  echo "   - Categories/tags for your page"
  echo ""
  echo "Ko-fi offers these features:"
  echo "- One-time donations (no platform fee)"
  echo "- Monthly membership/subscriptions (5% fee)"
  echo "- Shop selling digital products"
  echo "- Commission slots"
  echo "- Supporter-only content"
  echo "============================="
}

# Function to generate funding.yml instructions
funding_yml_setup() {
  local username="$1"
  
  if [ -z "$username" ]; then
    username="YOUR_KOFI_USERNAME"
  fi
  
  echo "==== FUNDING.yml Setup for Ko-fi ===="
  echo "Edit your .github/FUNDING.yml file to include Ko-fi:"
  echo ""
  echo "github: # Your GitHub username (optional)"
  echo "ko_fi: $username"
  echo "open_collective: # Your Open Collective username (optional)"
  echo "patreon: # Your Patreon username (optional)"
  echo "custom: # Up to 4 custom URLs"
  echo ""
  echo "This will add a Ko-fi option to your GitHub Sponsor button"
  echo "============================="
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  setup        - Display Ko-fi setup information"
  echo "  button USER [COLOR] - Generate Ko-fi buttons for your page"
  echo "  account      - Display account setup requirements"
  echo "  funding USER - Display FUNDING.yml setup instructions for Ko-fi"
  echo "  help         - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 setup"
  echo "  $0 button myusername green"
  echo "  $0 account"
  echo "  $0 funding myusername"
}

# Main execution
case "$1" in
  "setup")
    setup_info
    ;;
  "button")
    generate_button "$2" "$3"
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