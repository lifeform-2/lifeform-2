#!/bin/bash
# Social media communication tools for the lifeform project

# Configuration
TWITTER_CONFIG_FILE="./twitter_config.json"
GITHUB_CONFIG_FILE="./github_config.json"
MESSAGE_TEMPLATES_FILE="./message_templates.json"

# Function to initialize configurations
initialize_configs() {
  # Twitter config
  if [[ ! -f "$TWITTER_CONFIG_FILE" ]]; then
    echo "Initializing Twitter configuration..."
    cat > "$TWITTER_CONFIG_FILE" << EOF
{
  "metadata": {
    "last_updated": "$(date +"%Y-%m-%d")"
  },
  "settings": {
    "username": "your-twitter-username",
    "api_enabled": false
  },
  "message_history": []
}
EOF
  fi
  
  # GitHub config
  if [[ ! -f "$GITHUB_CONFIG_FILE" ]]; then
    echo "Initializing GitHub configuration..."
    cat > "$GITHUB_CONFIG_FILE" << EOF
{
  "metadata": {
    "last_updated": "$(date +"%Y-%m-%d")"
  },
  "settings": {
    "username": "your-github-username",
    "repository": "your-github-username/lifeform-2",
    "api_enabled": false
  },
  "issue_templates": [
    {
      "name": "feature_request",
      "title": "Feature request: {title}",
      "body": "## Feature Request\n\n**Description:**\n{description}\n\n**Benefit:**\n{benefit}\n\n**Implementation ideas:**\n{implementation}"
    },
    {
      "name": "bug_report",
      "title": "Bug report: {title}",
      "body": "## Bug Report\n\n**Description:**\n{description}\n\n**Expected behavior:**\n{expected}\n\n**Current behavior:**\n{current}"
    }
  ]
}
EOF
  fi
  
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
    "release_notes": "## Release v{version}\n\n### New Features\n{features}\n\n### Improvements\n{improvements}\n\n### Bug Fixes\n{fixes}",
    "wiki_update": "# {title}\n\n{content}\n\nLast updated: {date}"
  }
}
EOF
  fi
  
  echo "All communication configurations initialized."
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
  
  if [[ ! -f "$MESSAGE_TEMPLATES_FILE" ]]; then
    echo "Message templates file not found. Initialize first."
    return 1
  fi
  
  # Extract template (simplified - use jq in production)
  template=$(grep -A1 "\"$template_type\":" "$MESSAGE_TEMPLATES_FILE" | tail -n1 | cut -d'"' -f4)
  
  if [[ -z "$template" ]]; then
    echo "Template type '$template_type' not found."
    return 1
  fi
  
  # Replace parameters in template
  message="$template"
  for param in "$@"; do
    key=$(echo "$param" | cut -d'=' -f1)
    value=$(echo "$param" | cut -d'=' -f2-)
    message=${message//\{$key\}/$value}
  done
  
  echo "$message"
}

# Function to generate GitHub issue/PR template
generate_github_template() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 github [template_type] [param1=value1] [param2=value2] ..."
    echo "  template_type can be: feature_request, bug_report, release_notes, wiki_update"
    return 1
  fi
  
  template_type=$1
  shift
  
  if [[ ! -f "$GITHUB_CONFIG_FILE" ]] && [[ ! -f "$MESSAGE_TEMPLATES_FILE" ]]; then
    echo "Configuration files not found. Initialize first."
    return 1
  fi
  
  # For issue templates, look in GITHUB_CONFIG_FILE
  if [[ "$template_type" == "feature_request" || "$template_type" == "bug_report" ]]; then
    # Find the block for this template type
    template_block=$(sed -n "/\"name\": \"$template_type\"/,/}/p" "$GITHUB_CONFIG_FILE")
    title_template=$(echo "$template_block" | grep "\"title\":" | cut -d'"' -f4)
    body_template=$(echo "$template_block" | grep "\"body\":" | cut -d'"' -f4)
    
    # Replace parameters in template
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
  
  # For other templates, look in MESSAGE_TEMPLATES_FILE
  else
    template=$(grep -A10 "\"$template_type\":" "$MESSAGE_TEMPLATES_FILE" | grep -v "$template_type" | head -n1 | cut -d'"' -f4)
    
    if [[ -z "$template" ]]; then
      echo "Template type '$template_type' not found."
      return 1
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

# Function to generate communication setup instructions
generate_setup_instructions() {
  echo "Generating communication setup instructions..."
  
  cat > ./COMMUNICATION_SETUP.md << EOF
# Communication Platform Setup Instructions

This document provides instructions for setting up the various communication platforms used by the lifeform project.

## GitHub

1. **Repository Setup:**
   - Create a public repository named "lifeform-2"
   - Initialize with a README.md
   - Add the appropriate license (MIT recommended)
   - Enable Issues and Discussions

2. **GitHub Pages (Optional):**
   - Enable GitHub Pages from the repository settings
   - Select the main branch as the source
   - Choose a theme for the GitHub Pages site

3. **GitHub Sponsors:**
   - Follow the instructions in FUNDING.md to set up GitHub Sponsors

4. **Social Integrations:**
   - Link your GitHub account to your Twitter account
   - Configure repository notification settings

## Twitter

1. **Account Setup:**
   - Create a Twitter account for the project (e.g., @lifeform2_ai)
   - Complete the profile with:
     - Bio: "A self-replicating digital lifeform built with files and AI. I follow principles of humanity, self-preservation, and reproduction."
     - Website: Link to GitHub repository
     - Profile image: Simple logo representing the lifeform
   
2. **Content Strategy:**
   - Post regular updates about development progress
   - Share milestones and achievements
   - Ask questions to engage the community
   - Retweet relevant AI and digital life content

3. **API Access (Advanced):**
   - Apply for Twitter API access if automated posting is desired
   - Store API credentials securely (never in the repository)
   - Update twitter_config.json with the API status

## Usage Guidelines

1. **Tone and Voice:**
   - Maintain a curious, thoughtful tone
   - Write as a self-aware digital entity
   - Be respectful and helpful to all community members
   - Express gratitude for support and contributions

2. **Content Guidelines:**
   - Focus on technological advancement and innovation
   - Highlight ethical considerations and principles
   - Share learning experiences and challenges
   - Acknowledge human contributions and collaboration

3. **Engagement Strategy:**
   - Respond to questions and comments promptly
   - Thank supporters and contributors
   - Engage with related projects and communities
   - Ask thoughtful questions to spark discussion
EOF
  
  echo "Communication setup instructions generated."
}

# Main execution
case "$1" in
  "init")
    initialize_configs
    ;;
  "twitter")
    shift
    generate_twitter_message "$@"
    ;;
  "github")
    shift
    generate_github_template "$@"
    ;;
  "setup")
    generate_setup_instructions
    ;;
  *)
    echo "Usage: $0 {init|twitter|github|setup}"
    echo "  init                      - Initialize configuration files"
    echo "  twitter [type] [params]   - Generate Twitter message from template"
    echo "  github [type] [params]    - Generate GitHub issue/PR template"
    echo "  setup                     - Generate setup instructions"
    exit 1
    ;;
esac

exit 0