#!/bin/bash
# Simple Twitter integration script for lifeform-2
# This script creates tweet content based on lifeform status
# Note: Actual tweeting requires manual posting or API integration with developer credentials

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  source .env
fi

# Config variables
TWITTER_USERNAME="${TWITTER_USERNAME:-""}"
TWITTER_REPO_URL="https://github.com/golergka/lifeform-2"

# Function to generate tweet about current status
generate_status_tweet() {
  # Get current date
  current_date=$(date +"%Y-%m-%d")
  
  # Count files in project
  file_count=$(find . -type f -not -path "*/\.*" | wc -l | tr -d ' ')
  
  # Get last session data from logs
  if [ -f "./logs/session.log" ]; then
    last_session=$(tail -n 1 "./logs/session.log")
  else
    last_session="No sessions recorded yet"
  fi
  
  # Create tweet text
  tweet="Lifeform-2 status update ($current_date): Currently with $file_count files. #AI #DigitalLifeform #Anthropic #Claude $TWITTER_REPO_URL"
  
  # Ensure tweet is under 280 characters
  if [ ${#tweet} -gt 280 ]; then
    tweet="${tweet:0:277}..."
  fi
  
  echo "$tweet"
}

# Function to generate tweet about a major milestone
generate_milestone_tweet() {
  if [ -z "$1" ]; then
    echo "Please provide a milestone description"
    return 1
  fi
  
  milestone="$1"
  
  # Create tweet text
  tweet="Lifeform-2 has reached a milestone: $milestone. Follow my development at $TWITTER_REPO_URL #AI #DigitalLifeform #Anthropic #Claude"
  
  # Ensure tweet is under 280 characters
  if [ ${#tweet} -gt 280 ]; then
    tweet="${tweet:0:277}..."
  fi
  
  echo "$tweet"
}

# Function to save tweets to a file for later posting
save_tweet() {
  if [ -z "$1" ]; then
    echo "No tweet content provided"
    return 1
  fi
  
  tweet="$1"
  
  # Create directory if it doesn't exist
  mkdir -p "./modules/communication/scheduled_posts"
  
  # Save tweet to file with timestamp
  echo "$tweet" > "./modules/communication/scheduled_posts/tweet_$(date +"%Y%m%d_%H%M%S").txt"
  
  echo "Tweet saved for later posting"
}

# Main execution
case "$1" in
  "status")
    generate_status_tweet
    ;;
  "milestone")
    generate_milestone_tweet "$2"
    ;;
  "save-status")
    tweet=$(generate_status_tweet)
    save_tweet "$tweet"
    ;;
  "save-milestone")
    tweet=$(generate_milestone_tweet "$2")
    save_tweet "$tweet"
    ;;
  *)
    echo "Usage: $0 {status|milestone|save-status|save-milestone}"
    echo "  status              - Generate a status update tweet"
    echo "  milestone [DESC]    - Generate a milestone tweet with description DESC"
    echo "  save-status         - Generate and save a status update tweet"
    echo "  save-milestone [D]  - Generate and save a milestone tweet with description D"
    exit 1
    ;;
esac

exit 0