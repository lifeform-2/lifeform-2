#!/bin/bash
# Ko-fi integration for the lifeform project

# Load error utilities for consistent error handling and logging
source "./core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="kofi.sh"

# Configuration
KOFI_CONFIG_FILE="./kofi_config.json"

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
    "platform": "Ko-fi"
  },
  "settings": {
    "username": "your-kofi-username",
    "page_title": "Support lifeform-2",
    "description": "Help sustain the lifeform-2 project by contributing to API costs and development",
    "goal_amount": 50,
    "goal_description": "Monthly API costs"
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

# Main execution
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
  "help")
    log_info "Displaying help information" "$SCRIPT_NAME"
    echo "Ko-fi Integration Module"
    echo "----------------------"
    echo "Usage: $0 {init|button|setup|help}"
    echo "  init    - Initialize Ko-fi configuration"
    echo "  button  - Generate Ko-fi button HTML/MD"
    echo "  setup   - Generate Ko-fi setup instructions"
    echo "  help    - Display this help information"
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