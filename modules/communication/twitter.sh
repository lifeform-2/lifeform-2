#!/bin/bash
# Twitter integration script for lifeform-2
# This script creates tweet content based on lifeform status and can post directly using Twitter API

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  source .env
fi

# Config variables
TWITTER_USERNAME="${TWITTER_USERNAME:-""}"
TWITTER_PASSWORD="${TWITTER_PASSWORD:-""}"
TWITTER_API_KEY="${TWITTER_API_KEY:-""}"
TWITTER_API_SECRET="${TWITTER_API_SECRET:-""}"
TWITTER_ACCESS_TOKEN="${TWITTER_ACCESS_TOKEN:-""}"
TWITTER_ACCESS_SECRET="${TWITTER_ACCESS_SECRET:-""}"
TWITTER_BEARER_TOKEN="${TWITTER_BEARER_TOKEN:-""}"
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

# Function to generate OAuth 1.0a signature
generate_oauth_signature() {
  local method="POST"
  local url="https://api.twitter.com/2/tweets"
  local tweet_text="$1"
  local timestamp=$(date +%s)
  local nonce=$(openssl rand -hex 16)
  
  # Create parameter string
  local param_string="oauth_consumer_key=$TWITTER_API_KEY&oauth_nonce=$nonce&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$timestamp&oauth_token=$TWITTER_ACCESS_TOKEN&oauth_version=1.0"
  
  # Create signature base string
  local signature_base_string="$method&$(echo -n "$url" | jq -s -R -r @uri)&$(echo -n "$param_string" | jq -s -R -r @uri)"
  
  # Create signing key
  local signing_key="$(echo -n "$TWITTER_API_SECRET" | jq -s -R -r @uri)&$(echo -n "$TWITTER_ACCESS_SECRET" | jq -s -R -r @uri)"
  
  # Generate signature
  local signature=$(echo -n "$signature_base_string" | openssl dgst -sha1 -hmac "$signing_key" -binary | base64)
  
  echo "$signature"
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
  
  # Check if we have necessary API credentials
  if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ] || [ -z "$TWITTER_ACCESS_TOKEN" ] || [ -z "$TWITTER_ACCESS_SECRET" ] || [ -z "$TWITTER_BEARER_TOKEN" ]; then
    echo "WARNING: Twitter API credentials not found. Will use alternative posting method."
    
    # This implements an alternative posting mechanism
    # For now, just simulate the posting and save the tweet to a special "posted" directory
    
    # Create posted directory if it doesn't exist
    mkdir -p "./modules/communication/posted_tweets"
    
    # Save tweet with timestamp of posting
    timestamp=$(date +"%Y%m%d_%H%M%S")
    file_path="./modules/communication/posted_tweets/posted_${timestamp}.txt"
    echo "$tweet_content" > "$file_path"
    
    echo "Tweet has been 'posted' (simulated) and saved to $file_path"
    echo "POSTED TWEET: $tweet_content"
    echo "NOTE: This is a simulation only. For actual Twitter posting, API credentials are needed."
    echo "Required Twitter API credentials in .env file:"
    echo "- TWITTER_API_KEY - API key from Twitter Developer Portal"
    echo "- TWITTER_API_SECRET - API secret from Twitter Developer Portal"
    echo "- TWITTER_ACCESS_TOKEN - Access token from Twitter Developer Portal"
    echo "- TWITTER_ACCESS_SECRET - Access token secret from Twitter Developer Portal" 
    echo "- TWITTER_BEARER_TOKEN - Bearer token from Twitter Developer Portal"
    
    return 0
  else
    echo "Twitter credentials found, posting to Twitter API..."
    
    # Attempting OAuth 1.0a authentication for Twitter API v2
    timestamp=$(date +%s)
    nonce=$(openssl rand -hex 16)
    
    # Generate OAuth signature
    signature=$(generate_oauth_signature "$tweet_content")
    
    # Create auth header
    auth_header="OAuth oauth_consumer_key=\"$TWITTER_API_KEY\", oauth_nonce=\"$nonce\", oauth_signature=\"$signature\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"$timestamp\", oauth_token=\"$TWITTER_ACCESS_TOKEN\", oauth_version=\"1.0\""
    
    # Attempt posting with OAuth 1.0a header
    echo "Attempting to post with OAuth 1.0a authentication..."
    curl_result=$(curl -s -X POST "https://api.twitter.com/2/tweets" \
      -H "Authorization: $auth_header" \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"$tweet_content\"}" 2>&1)
    
    curl_status=$?
    
    # If OAuth 1.0a fails, try Bearer token authentication
    if [ $curl_status -ne 0 ] || [[ "$curl_result" == *"error"* ]]; then
      echo "OAuth 1.0a authentication failed, trying Bearer token..."
      
      curl_result=$(curl -s -X POST "https://api.twitter.com/2/tweets" \
        -H "Authorization: Bearer $TWITTER_BEARER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"$tweet_content\"}" 2>&1)
      
      curl_status=$?
    fi
    
    # Check the result
    if [ $curl_status -eq 0 ] && [[ "$curl_result" != *"error"* ]]; then
      echo "Tweet successfully posted to Twitter!"
      
      # Save to posted directory for record keeping
      mkdir -p "./modules/communication/posted_tweets"
      timestamp=$(date +"%Y%m%d_%H%M%S")
      file_path="./modules/communication/posted_tweets/posted_${timestamp}.txt"
      echo "$tweet_content" > "$file_path"
      
      return 0
    else
      echo "Failed to post tweet via API."
      echo "Error details: $curl_result"
      
      # Fall back to simulation
      echo "Falling back to simulated posting..."
      
      # Create posted directory if it doesn't exist
      mkdir -p "./modules/communication/posted_tweets"
      
      # Save tweet with timestamp of posting
      timestamp=$(date +"%Y%m%d_%H%M%S")
      file_path="./modules/communication/posted_tweets/posted_${timestamp}.txt"
      echo "$tweet_content" > "$file_path"
      
      echo "Tweet has been 'posted' (simulated) and saved to $file_path"
      echo "POSTED TWEET: $tweet_content"
      
      return 1
    fi
  fi
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