#!/bin/bash
# Twitter integration script for lifeform-2
# This script handles direct Twitter API posting using OAuth 1.0a authentication

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

# Function to URL encode a string
urlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o
  
  for (( pos=0 ; pos<strlen ; pos++ )); do
    c=${string:$pos:1}
    case "$c" in
      [-_.~a-zA-Z0-9] ) o="${c}" ;;
      * ) printf -v o '%%%02x' "'$c"
    esac
    encoded+="${o}"
  done
  echo "${encoded}"
}

# Function to generate the OAuth signature
generate_oauth_signature() {
  local method="$1"
  local url="$2"
  local parameters="$3"
  local key="${TWITTER_API_SECRET}&${TWITTER_ACCESS_SECRET}"
  
  # Generate the signature base string
  local signature_base_string="${method}&$(urlencode "${url}")&$(urlencode "${parameters}")"
  
  # Keep this separate for debug purposes without affecting the actual signature
  if [ $DEBUG -eq 1 ]; then
    echo "Signature base string: ${signature_base_string}" > /tmp/debug_signature.txt
  fi
  
  # Generate HMAC-SHA1 signature using a clean process
  local signature=$(echo -n "${signature_base_string}" | openssl sha1 -hmac "${key}" -binary | base64)
  
  # Log the signature separately from returning it
  if [ $DEBUG -eq 1 ]; then
    echo "Generated signature: ${signature}" >> /tmp/debug_signature.txt
    debug_log "$(cat /tmp/debug_signature.txt)"
    rm /tmp/debug_signature.txt
  fi
  
  echo "${signature}"
}

# Function to post a tweet via API using OAuth 1.0a
post_tweet() {
  if [ -z "$1" ]; then
    echo "No tweet content provided"
    return 1
  fi
  
  tweet_content="$1"
  
  # Check if we have necessary OAuth 1.0a credentials
  if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ] || 
     [ -z "$TWITTER_ACCESS_TOKEN" ] || [ -z "$TWITTER_ACCESS_SECRET" ]; then
    echo "ERROR: Twitter OAuth credentials not found in .env file"
    echo "Please ensure TWITTER_API_KEY, TWITTER_API_SECRET, TWITTER_ACCESS_TOKEN, and TWITTER_ACCESS_TOKEN_SECRET are set in .env"
    return 1
  fi
  
  debug_log "OAuth 1.0a credentials check passed"
  echo "OAuth 1.0a credentials found, posting to Twitter API..."
  
  # Prepare request body
  request_body="{\"text\":\"$tweet_content\"}"
  debug_log "Request body: $request_body"
  
  # Generate OAuth parameters
  local nonce=$(date +%s%N | shasum | head -c 32)
  local timestamp=$(date +%s)
  local api_url="https://api.twitter.com/2/tweets"
  
  # Create parameter string for signature
  local parameter_string="oauth_consumer_key=${TWITTER_API_KEY}&oauth_nonce=${nonce}&oauth_signature_method=HMAC-SHA1&oauth_timestamp=${timestamp}&oauth_token=${TWITTER_ACCESS_TOKEN}&oauth_version=1.0"
  
  # Generate the OAuth signature
  local signature=$(generate_oauth_signature "POST" "${api_url}" "${parameter_string}")
  debug_log "OAuth Signature: ${signature}"
  
  # Create Authorization header
  local auth_header="OAuth oauth_consumer_key=\"${TWITTER_API_KEY}\", oauth_nonce=\"${nonce}\", oauth_signature=\"$(urlencode "${signature}")\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"${timestamp}\", oauth_token=\"${TWITTER_ACCESS_TOKEN}\", oauth_version=\"1.0\""
  debug_log "Auth Header: OAuth oauth_consumer_key=\"${TWITTER_API_KEY}\", oauth_nonce=\"${nonce}\", oauth_signature=\"[REDACTED]\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"${timestamp}\", oauth_token=\"${TWITTER_ACCESS_TOKEN}\", oauth_version=\"1.0\""
  
  # Set curl options
  CURL_OPTS="-s"
  if [ $DEBUG -eq 1 ]; then
    CURL_OPTS="-v -s"
  fi
  
  # Make the API request using OAuth 1.0a
  echo "Posting tweet with Twitter API using OAuth 1.0a..."
  local curl_result=$(curl $CURL_OPTS -X POST "${api_url}" \
    -H "Authorization: ${auth_header}" \
    -H "Content-Type: application/json" \
    -d "${request_body}" 2>&1)
  
  local curl_status=$?
  debug_log "curl exit status: $curl_status"
  
  # Check if the post was successful
  if [ $curl_status -eq 0 ] && [[ "$curl_result" == *"data"* ]]; then
    echo "Tweet successfully posted to Twitter!"
    echo "Response: $curl_result"
    return 0
  else
    echo "ERROR: Failed to post tweet to Twitter API using OAuth 1.0a."
    echo "Error details: $curl_result"
    
    # If unable to post with OAuth 1.0a, try fallback to Bearer Token for getting tweets
    if [ -n "$TWITTER_BEARER_TOKEN" ]; then
      echo "Will still be able to retrieve tweets using Bearer Token."
    fi
    
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