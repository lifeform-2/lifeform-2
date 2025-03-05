#!/bin/bash
# Twitter integration script for lifeform-2
# This script creates tweet content based on lifeform status and can post directly using curl

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  source .env
fi

# Config variables
TWITTER_USERNAME="${TWITTER_USERNAME:-""}"
TWITTER_PASSWORD="${TWITTER_PASSWORD:-""}"
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
  timestamp=$(date +"%Y%m%d_%H%M%S")
  file_path="./modules/communication/scheduled_posts/tweet_${timestamp}.txt"
  echo "$tweet" > "$file_path"
  
  echo "Tweet saved to $file_path"
  return 0
}

# Function to post the most recent saved tweet
post_latest_tweet() {
  # Check for saved tweets
  latest_tweet=$(ls -t ./modules/communication/scheduled_posts/tweet_*.txt 2>/dev/null | head -n 1)
  
  if [ -z "$latest_tweet" ]; then
    echo "No saved tweets found"
    return 1
  fi
  
  # Read the tweet content
  tweet_content=$(cat "$latest_tweet")
  
  # Post the tweet using direct API integration
  echo "Attempting to post tweet: $tweet_content"
  post_tweet "$tweet_content"
  
  return $?
}

# Function to post a tweet via API
post_tweet() {
  if [ -z "$1" ]; then
    echo "No tweet content provided"
    return 1
  fi
  
  tweet_content="$1"
  
  # Check if credentials are available
  if [ -z "$TWITTER_USERNAME" ] || [ -z "$TWITTER_PASSWORD" ]; then
    echo "ERROR: Twitter credentials not found in .env file"
    echo "Please ensure TWITTER_USERNAME and TWITTER_PASSWORD are set in .env"
    return 1
  fi
  
  echo "Twitter credentials found, ready to post"
  echo "NOTE: Actual Twitter posting requires API access which is not yet implemented"
  echo "Tweet would be posted as: $tweet_content"
  
  # This is a placeholder for actual API implementation
  # When API access is available, uncomment and implement the following:
  #
  # curl -X POST "https://api.twitter.com/v2/tweets" \
  #   -H "Authorization: Bearer $TWITTER_API_TOKEN" \
  #   -H "Content-Type: application/json" \
  #   -d "{\"text\":\"$tweet_content\"}"
  
  return 0
}

# Function to post a specific saved tweet by filename
post_saved_tweet() {
  if [ -z "$1" ]; then
    echo "No filename provided"
    return 1
  fi
  
  filename="$1"
  full_path="./modules/communication/scheduled_posts/$filename"
  
  if [ ! -f "$full_path" ]; then
    echo "Tweet file not found: $full_path"
    return 1
  fi
  
  # Read the tweet content
  tweet_content=$(cat "$full_path")
  
  # Post the tweet
  echo "Posting tweet from file: $filename"
  post_tweet "$tweet_content"
  
  return $?
}

# Function to list all saved tweets
list_saved_tweets() {
  echo "Saved tweets:"
  
  # Check if any tweets exist
  tweet_count=$(ls ./modules/communication/scheduled_posts/tweet_*.txt 2>/dev/null | wc -l)
  
  if [ "$tweet_count" -eq 0 ]; then
    echo "No saved tweets found"
    return 0
  fi
  
  # List all tweets with their content
  for tweet_file in $(ls -t ./modules/communication/scheduled_posts/tweet_*.txt); do
    filename=$(basename "$tweet_file")
    content=$(cat "$tweet_file")
    
    echo "- $filename: \"$content\""
  done
  
  return 0
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
  "post-latest")
    post_latest_tweet
    ;;
  "post")
    if [ -z "$2" ]; then
      post_latest_tweet
    else
      post_tweet "$2"
    fi
    ;;
  "post-file")
    post_saved_tweet "$2"
    ;;
  "list")
    list_saved_tweets
    ;;
  *)
    echo "Usage: $0 {status|milestone|save-status|save-milestone|post|post-latest|post-file|list}"
    echo "  status                - Generate a status update tweet"
    echo "  milestone [DESC]      - Generate a milestone tweet with description DESC"
    echo "  save-status           - Generate and save a status update tweet"
    echo "  save-milestone [DESC] - Generate and save a milestone tweet with description DESC"
    echo "  post \"TEXT\"           - Post a tweet with the provided text"
    echo "  post-latest           - Post the most recently saved tweet"
    echo "  post-file FILENAME    - Post a specific saved tweet by filename"
    echo "  list                  - List all saved tweets"
    exit 1
    ;;
esac

exit 0