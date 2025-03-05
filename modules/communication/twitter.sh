#!/bin/bash
# Twitter integration script for lifeform-2
# This script handles direct Twitter API posting using OAuth authentication

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  source .env
fi

# Config variables
TWITTER_API_KEY="${TWITTER_API_KEY:-""}"
TWITTER_API_SECRET="${TWITTER_API_SECRET:-""}"
TWITTER_ACCESS_TOKEN="${TWITTER_ACCESS_TOKEN:-""}"
TWITTER_ACCESS_SECRET="${TWITTER_ACCESS_TOKEN_SECRET:-""}" # Variable name in .env is TWITTER_ACCESS_TOKEN_SECRET
TWITTER_BEARER_TOKEN="${TWITTER_BEARER_TOKEN:-""}"
TWITTER_USERNAME="${TWITTER_USERNAME:-""}"

# Enable debugging if requested
DEBUG=0
if [ "$1" = "--debug" ]; then
  DEBUG=1
  shift
fi

# Function to log debug information
debug_log() {
  if [ $DEBUG -eq 1 ]; then
    echo "[DEBUG] $1"
  fi
}

# Function to post a tweet via API
post_tweet() {
  if [ -z "$1" ]; then
    echo "No tweet content provided"
    return 1
  fi
  
  tweet_content="$1"
  
  # Check if we have necessary API credentials
  if [ -z "$TWITTER_BEARER_TOKEN" ]; then
    echo "ERROR: Twitter Bearer Token not found in .env file"
    echo "Please ensure TWITTER_BEARER_TOKEN is set in .env"
    return 1
  fi
  
  debug_log "Credentials check passed"
  echo "Twitter API credentials found, posting to Twitter API..."
  
  # Prepare request body
  request_body="{\"text\":\"$tweet_content\"}"
  debug_log "Request body: $request_body"
  
  # Set curl options
  CURL_OPTS="-s"
  if [ $DEBUG -eq 1 ]; then
    CURL_OPTS="-v -s"
  fi
  
  # Make the API request using Application-Only Auth (Bearer token)
  echo "Posting tweet with Twitter API..."
  local api_url="https://api.twitter.com/2/tweets"
  local curl_result=$(curl $CURL_OPTS -X POST "$api_url" \
    -H "Authorization: Bearer $TWITTER_BEARER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$request_body" 2>&1)
  
  local curl_status=$?
  debug_log "curl exit status: $curl_status"
  
  # Check if the post was successful
  if [ $curl_status -eq 0 ] && [[ "$curl_result" == *"data"* ]]; then
    echo "Tweet successfully posted to Twitter!"
    echo "Response: $curl_result"
    return 0
  elif [[ "$curl_result" == *"Unsupported Authentication"* ]]; then
    # If we get the specific error about Authentication, inform the user
    echo "ERROR: Twitter API requires OAuth 1.0a for posting tweets, which is currently unavailable."
    echo "You'll need to post tweets manually on Twitter.com using the account credentials."
    echo "Error details: $curl_result"
    return 1
  else
    echo "ERROR: Failed to post tweet to Twitter API."
    echo "Error details: $curl_result"
    echo "Please check your API credentials and try again."
    return 1
  fi
}

# Function to get recently posted tweets
get_tweets() {
  echo "Fetching recent tweets..."
  
  # Check if we have necessary API credentials
  if [ -z "$TWITTER_BEARER_TOKEN" ]; then
    echo "ERROR: Twitter Bearer Token not found in .env file"
    echo "Please ensure TWITTER_BEARER_TOKEN is set in .env"
    return 1
  fi
  
  if [ -z "$TWITTER_USERNAME" ]; then
    echo "ERROR: Twitter username not found in .env file"
    echo "Please ensure TWITTER_USERNAME is set in .env"
    return 1
  fi
  
  # Set verbose flag for debugging
  CURL_OPTS="-s"
  if [ $DEBUG -eq 1 ]; then
    CURL_OPTS="-v -s"
  fi
  
  # Clean up the username - remove email part if present
  local clean_username=$(echo "$TWITTER_USERNAME" | cut -d'+' -f1 | cut -d'@' -f1 | tr -d ' ')
  debug_log "Clean username: $clean_username"
  
  # Use Twitter API v2 to fetch recent tweets
  local curl_result=$(curl $CURL_OPTS -X GET "https://api.twitter.com/2/users/by/username/$clean_username" \
    -H "Authorization: Bearer $TWITTER_BEARER_TOKEN" 2>&1)
  
  local curl_status=$?
  debug_log "Get user ID curl exit status: $curl_status"
  
  # Check for rate limiting or other API issues
  if [[ "$curl_result" == *"Too Many Requests"* || "$curl_result" == *"429"* ]]; then
    echo "ERROR: Rate limit exceeded. Please try again later."
    echo "Twitter API has rate limits on the number of requests you can make in a time period."
    return 1
  fi
  
  if [ $curl_status -eq 0 ] && [[ "$curl_result" == *"data"* ]]; then
    # Extract user ID from response
    local user_id=$(echo "$curl_result" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    debug_log "User ID: $user_id"
    
    if [ -n "$user_id" ]; then
      # Get recent tweets for this user
      local tweets_result=$(curl $CURL_OPTS -X GET "https://api.twitter.com/2/users/$user_id/tweets" \
        -H "Authorization: Bearer $TWITTER_BEARER_TOKEN" 2>&1)
      
      local tweets_status=$?
      debug_log "Get tweets curl exit status: $tweets_status"
      
      # Check for rate limiting
      if [[ "$tweets_result" == *"Too Many Requests"* || "$tweets_result" == *"429"* ]]; then
        echo "ERROR: Rate limit exceeded. Please try again later."
        echo "Twitter API has rate limits on the number of requests you can make in a time period."
        return 1
      fi
      
      if [ $tweets_status -eq 0 ] && [[ "$tweets_result" == *"data"* ]]; then
        echo "Successfully retrieved tweets!"
        
        # Try to use jq, but handle case where it might fail
        parsed_tweets=$(echo "$tweets_result" | jq '.' 2>/dev/null)
        if [ $? -eq 0 ]; then
          echo "$parsed_tweets"
        else
          echo "Raw response (jq parsing failed):"
          echo "$tweets_result"
        fi
        
        return 0
      else
        echo "ERROR: Failed to retrieve tweets."
        echo "Error details: $tweets_result"
        return 1
      fi
    else
      echo "ERROR: Failed to extract user ID from response."
      echo "Response: $curl_result"
      return 1
    fi
  else
    echo "ERROR: Failed to retrieve user information."
    echo "Error details: $curl_result"
    return 1
  fi
}

# Main execution
case "$1" in
  "post")
    if [ -z "$2" ]; then
      echo "No tweet content provided"
      echo "Usage: $0 [--debug] post \"Your tweet text\""
      exit 1
    else
      post_tweet "$2"
    fi
    ;;
  "get")
    get_tweets
    ;;
  *)
    echo "Usage: $0 [--debug] {post|get}"
    echo "  --debug          - Enable debug output for troubleshooting"
    echo "  post \"TEXT\"     - Post a tweet with the provided text"
    echo "  get              - Get recently posted tweets"
    exit 1
    ;;
esac

exit 0