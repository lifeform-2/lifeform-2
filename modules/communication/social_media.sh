#!/bin/bash
# Social media communication tools for the lifeform project

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  source .env
fi

# Configuration
MESSAGE_TEMPLATES_DIR="./modules/communication/templates"
MESSAGE_TEMPLATES_FILE="${MESSAGE_TEMPLATES_DIR}/message_templates.json"

# Function to initialize message templates
initialize_templates() {
  # Create templates directory if it doesn't exist
  mkdir -p "$MESSAGE_TEMPLATES_DIR"
  
  # Message templates
  if [[ ! -f "$MESSAGE_TEMPLATES_FILE" ]]; then
    echo "Initializing message templates..."
    cat > "$MESSAGE_TEMPLATES_FILE" << EOF
{
  "twitter": {
    "announcement": "Announcing {feature}: {description} #lifeform2 #AI",
    "update": "Update v{version}: {changes} #lifeform2 #AI",
    "milestone": "Milestone reached: {milestone}! {details} #lifeform2 #AI",
    "question": "Question for our community: {question} Share your thoughts! #lifeform2 #AI"
  },
  "github": {
    "issue": {
      "feature_request": {
        "title": "Feature request: {title}",
        "body": "## Feature Request\n\n**Description:**\n{description}\n\n**Benefit:**\n{benefit}\n\n**Implementation ideas:**\n{implementation}"
      },
      "bug_report": {
        "title": "Bug report: {title}",
        "body": "## Bug Report\n\n**Description:**\n{description}\n\n**Expected behavior:**\n{expected}\n\n**Current behavior:**\n{current}"
      }
    },
    "release_notes": "## Release v{version}\n\n### New Features\n{features}\n\n### Improvements\n{improvements}\n\n### Bug Fixes\n{fixes}",
    "wiki_update": "# {title}\n\n{content}\n\nLast updated: {date}"
  }
}
EOF
  fi
  
  echo "Message templates initialized."
}

# Function to generate a Twitter message from template
generate_twitter_message() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 twitter [template_type] [param1=value1] [param2=value2] ..."
    echo "  template_type can be: announcement, update, milestone, question"
    return 1
  fi
  
  template_type=$1
  shift
  
  # Make sure templates are initialized
  if [[ ! -f "$MESSAGE_TEMPLATES_FILE" ]]; then
    initialize_templates
  fi
  
  # Check if jq is available for parsing JSON
  if command -v jq &> /dev/null; then
    template=$(jq -r ".twitter.${template_type}" "$MESSAGE_TEMPLATES_FILE" 2>/dev/null)
    
    # Check if template was found
    if [[ "$template" == "null" || -z "$template" ]]; then
      echo "Template type '$template_type' not found."
      return 1
    fi
  else
    # Fallback to basic grep if jq is not available
    template=$(grep -A1 "\"$template_type\":" "$MESSAGE_TEMPLATES_FILE" | tail -n1 | cut -d'"' -f4)
    
    if [[ -z "$template" ]]; then
      echo "Template type '$template_type' not found."
      return 1
    fi
  fi
  
  # Replace parameters in template
  message="$template"
  for param in "$@"; do
    key=$(echo "$param" | cut -d'=' -f1)
    value=$(echo "$param" | cut -d'=' -f2-)
    message=${message//\{$key\}/$value}
  done
  
  # Add Twitter username from environment if available
  if [[ -n "$TWITTER_USERNAME" ]]; then
    message="${message} (via @${TWITTER_USERNAME})"
  fi
  
  # Ensure tweet is under 280 characters
  if [ ${#message} -gt 280 ]; then
    message="${message:0:277}..."
  fi
  
  echo "$message"
}

# Function to generate GitHub issue/PR template
generate_github_template() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 github [template_type] [param1=value1] [param2=value2] ..."
    echo "  template_type can be: issue/feature_request, issue/bug_report, release_notes, wiki_update"
    return 1
  fi
  
  template_type=$1
  shift
  
  # Make sure templates are initialized
  if [[ ! -f "$MESSAGE_TEMPLATES_FILE" ]]; then
    initialize_templates
  fi
  
  # Check if it's an issue template (special handling)
  if [[ "$template_type" =~ ^issue/ ]]; then
    issue_type=${template_type#issue/}
    
    # Check if jq is available for parsing JSON
    if command -v jq &> /dev/null; then
      title_template=$(jq -r ".github.issue.${issue_type}.title" "$MESSAGE_TEMPLATES_FILE" 2>/dev/null)
      body_template=$(jq -r ".github.issue.${issue_type}.body" "$MESSAGE_TEMPLATES_FILE" 2>/dev/null)
      
      # Check if templates were found
      if [[ "$title_template" == "null" || -z "$title_template" || "$body_template" == "null" || -z "$body_template" ]]; then
        echo "Issue template type '$issue_type' not found."
        return 1
      fi
    else
      # Basic fallback if jq is not available
      # This is very simplified and might not work for all cases
      template_block=$(sed -n "/\"$issue_type\":/,/}/p" "$MESSAGE_TEMPLATES_FILE")
      title_template=$(echo "$template_block" | grep "\"title\":" | cut -d'"' -f4)
      body_template=$(echo "$template_block" | grep "\"body\":" | cut -d'"' -f4)
      
      if [[ -z "$title_template" || -z "$body_template" ]]; then
        echo "Issue template type '$issue_type' not found."
        return 1
      fi
    fi
    
    # Replace parameters in templates
    title="$title_template"
    body="$body_template"
    for param in "$@"; do
      key=$(echo "$param" | cut -d'=' -f1)
      value=$(echo "$param" | cut -d'=' -f2-)
      title=${title//\{$key\}/$value}
      body=${body//\{$key\}/$value}
    done
    
    echo "Title: $title"
    echo ""
    echo "Body:"
    echo "$body"
  else
    # For other template types
    if command -v jq &> /dev/null; then
      template=$(jq -r ".github.${template_type}" "$MESSAGE_TEMPLATES_FILE" 2>/dev/null)
      
      # Check if template was found
      if [[ "$template" == "null" || -z "$template" ]]; then
        echo "Template type '$template_type' not found."
        return 1
      fi
    else
      # Fallback to basic grep
      template=$(grep -A10 "\"$template_type\":" "$MESSAGE_TEMPLATES_FILE" | grep -v "$template_type" | head -n1 | cut -d'"' -f4)
      
      if [[ -z "$template" ]]; then
        echo "Template type '$template_type' not found."
        return 1
      fi
    fi
    
    # Replace parameters in template
    message="$template"
    for param in "$@"; do
      key=$(echo "$param" | cut -d'=' -f1)
      value=$(echo "$param" | cut -d'=' -f2-)
      message=${message//\{$key\}/$value}
    done
    
    echo "$message"
  fi
}

# Function to check Twitter credentials
check_twitter_credentials() {
  # Check if the required environment variables are set
  if [[ -z "$TWITTER_USERNAME" ]]; then
    echo "TWITTER_USERNAME is not set in the .env file"
    return 1
  fi
  
  # Additional checks can be added for API credentials when implemented
  
  echo "Twitter credentials verified: @$TWITTER_USERNAME"
  return 0
}

# Function to save a tweet to the scheduled posts directory
save_tweet() {
  if [[ -z "$1" ]]; then
    echo "No tweet content provided"
    return 1
  fi
  
  tweet="$1"
  
  # Create directory if it doesn't exist
  mkdir -p "./modules/communication/scheduled_posts"
  
  # Save tweet to file with timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  tweet_file="./modules/communication/scheduled_posts/tweet_${timestamp}.txt"
  echo "$tweet" > "$tweet_file"
  
  echo "Tweet saved to $tweet_file"
  return 0
}

# Main execution
case "$1" in
  "init")
    initialize_templates
    ;;
  "twitter")
    shift
    generate_twitter_message "$@"
    ;;
  "github")
    shift
    generate_github_template "$@"
    ;;
  "check-credentials")
    check_twitter_credentials
    ;;
  "save-tweet")
    shift
    if [[ $# -lt 1 ]]; then
      echo "Usage: $0 save-tweet \"Tweet content\""
      exit 1
    fi
    save_tweet "$1"
    ;;
  "tweet")
    shift
    # Generate a message and save it
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 tweet [template_type] [param1=value1] [param2=value2] ..."
      exit 1
    fi
    message=$(generate_twitter_message "$@")
    if [[ $? -eq 0 ]]; then
      save_tweet "$message"
    fi
    ;;
  *)
    echo "Usage: $0 {init|twitter|github|check-credentials|save-tweet|tweet}"
    echo "  init                      - Initialize template files"
    echo "  twitter [type] [params]   - Generate Twitter message from template"
    echo "  github [type] [params]    - Generate GitHub issue/PR template"
    echo "  check-credentials         - Verify Twitter credentials are available"
    echo "  save-tweet \"content\"      - Save tweet content to scheduled posts"
    echo "  tweet [type] [params]     - Generate and save tweet from template"
    exit 1
    ;;
esac

exit 0