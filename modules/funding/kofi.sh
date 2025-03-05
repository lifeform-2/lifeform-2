#!/bin/bash
# Ko-fi integration for the lifeform project

# Configuration
KOFI_CONFIG_FILE="./kofi_config.json"

# Function to initialize Ko-fi configuration
initialize_kofi() {
  if [[ ! -f "$KOFI_CONFIG_FILE" ]]; then
    echo "Initializing Ko-fi configuration..."
    cat > "$KOFI_CONFIG_FILE" << EOF
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
    echo "Ko-fi configuration initialized."
  fi
}

# Function to generate Ko-fi button for website or README
generate_kofi_button() {
  username=""
  
  # Extract username from config if available
  if [[ -f "$KOFI_CONFIG_FILE" ]]; then
    username=$(grep -o '"username": "[^"]*"' "$KOFI_CONFIG_FILE" | cut -d'"' -f4)
  fi
  
  if [[ -z "$username" || "$username" == "your-kofi-username" ]]; then
    echo "Please update your Ko-fi username in $KOFI_CONFIG_FILE first."
    return 1
  fi
  
  # Generate HTML button
  cat > ./kofi_button.html << EOF
<!-- Ko-fi button HTML -->
<a href="https://ko-fi.com/$username" target="_blank">
  <img height="36" style="border:0px;height:36px;" 
    src="https://storage.ko-fi.com/cdn/kofi5.png?v=3" 
    alt="Support Me on Ko-fi" />
</a>
EOF

  # Generate Markdown button
  cat > ./kofi_button.md << EOF
<!-- Ko-fi button Markdown -->
[![Support me on Ko-fi](https://storage.ko-fi.com/cdn/kofi5.png?v=3)](https://ko-fi.com/$username)
EOF

  echo "Ko-fi buttons generated."
}

# Function to generate Ko-fi page setup instructions
generate_kofi_instructions() {
  echo "Generating Ko-fi setup instructions..."
  
  cat > ./KOFI_SETUP.md << EOF
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
  
  echo "Ko-fi instructions generated."
}

# Main execution
case "$1" in
  "init")
    initialize_kofi
    ;;
  "button")
    generate_kofi_button
    ;;
  "setup")
    generate_kofi_instructions
    ;;
  *)
    echo "Usage: $0 {init|button|setup}"
    echo "  init    - Initialize Ko-fi configuration"
    echo "  button  - Generate Ko-fi button HTML/MD"
    echo "  setup   - Generate Ko-fi setup instructions"
    exit 1
    ;;
esac

exit 0