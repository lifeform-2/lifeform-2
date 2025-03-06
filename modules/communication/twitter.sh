#!/bin/bash
# Twitter integration script for lifeform-2
# This script handles direct Twitter API posting using OAuth 1.0a authentication

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  source .env
elif [ -f "../.env" ]; then
  source ../.env
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

# Function to URL encode a string - RFC 3986 compliant
urlencode() {
  local string="$1"
  local length=${#string}
  local encoded=""
  local pos c o
  
  for (( pos=0; pos<length; pos++ )); do
    c=${string:$pos:1}
    case "$c" in
      [a-zA-Z0-9.~_-]) 
        encoded+="$c" 
        ;;
      *)
        printf -v o '%%%02X' "'$c"
        encoded+="$o"
        ;;
    esac
  done
  echo "$encoded"
}

# Get the base64 encoding of the HMAC-SHA1 signature
hmac_sha1() {
  local key="$1"
  local data="$2"
  echo -n "$data" | openssl sha1 -hmac "$key" -binary | openssl base64
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
  
  # API endpoint and HTTP method
  api_url="https://api.twitter.com/2/tweets"
  http_method="POST"
  
  # OAuth parameters
  nonce=$(date +%s%N | shasum | head -c 32)
  timestamp=$(date +%s)
  
  # Prepare request body
  request_body="{\"text\":\"$tweet_content\"}"
  debug_log "Request body: $request_body"
  
  # Build parameter string - must be sorted alphabetically
  param_string=""
  param_string+="oauth_consumer_key=$(urlencode "$TWITTER_API_KEY")"
  param_string+="&oauth_nonce=$(urlencode "$nonce")"
  param_string+="&oauth_signature_method=HMAC-SHA1"
  param_string+="&oauth_timestamp=$timestamp"
  param_string+="&oauth_token=$(urlencode "$TWITTER_ACCESS_TOKEN")"
  param_string+="&oauth_version=1.0"
  
  # Create signature base string
  signature_base_string="$http_method&$(urlencode "$api_url")&$(urlencode "$param_string")"
  debug_log "Signature base string: $signature_base_string"
  
  # Create signing key - NOTE: The signing key should NOT be URL encoded
  signing_key="${TWITTER_API_SECRET}&${TWITTER_ACCESS_SECRET}"
  debug_log "Signing key format: [consumer_secret]&[access_token_secret]"
  
  # Generate signature
  signature=$(hmac_sha1 "$signing_key" "$signature_base_string")
  debug_log "Generated signature: $signature"
  
  # Build the Authorization header
  auth_header='OAuth '
  auth_header+="oauth_consumer_key=\"$(urlencode "$TWITTER_API_KEY")\", "
  auth_header+="oauth_nonce=\"$(urlencode "$nonce")\", "
  auth_header+="oauth_signature=\"$(urlencode "$signature")\", "
  auth_header+="oauth_signature_method=\"HMAC-SHA1\", "
  auth_header+="oauth_timestamp=\"$timestamp\", "
  auth_header+="oauth_token=\"$(urlencode "$TWITTER_ACCESS_TOKEN")\", "
  auth_header+="oauth_version=\"1.0\""
  
  debug_log "Auth Header (with redacted signature): OAuth oauth_consumer_key=\"${TWITTER_API_KEY}\", oauth_nonce=\"${nonce}\", oauth_signature=\"[REDACTED]\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"${timestamp}\", oauth_token=\"${TWITTER_ACCESS_TOKEN}\", oauth_version=\"1.0\""
  
  # Set curl options
  CURL_OPTS="-s"
  if [ $DEBUG -eq 1 ]; then
    CURL_OPTS="-v"
  fi
  
  # Make the API request using OAuth 1.0a
  echo "Posting tweet with Twitter API using OAuth 1.0a..."
  local curl_result=$(curl $CURL_OPTS -X POST "$api_url" \
    -H "Authorization: $auth_header" \
    -H "Content-Type: application/json" \
    -d "$request_body" 2>&1)
  
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
    
    # Additional debugging for 401 errors
    if [[ "$curl_result" == *"401"* ]]; then
      echo "Authentication error (401) detected. Possible causes:"
      echo "1. API key doesn't have write permissions"
      echo "2. OAuth signature calculation problem"
      echo "3. Clock synchronization issue"
      echo "4. Token might be expired or invalid"
    fi
    
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
  
  debug_log "Twitter username: $TWITTER_USERNAME"
  debug_log "Bearer token present: $(if [ -n "$TWITTER_BEARER_TOKEN" ]; then echo "Yes"; else echo "No"; fi)"
  
  # Set verbose flag for debugging
  CURL_OPTS="-s"
  if [ $DEBUG -eq 1 ]; then
    CURL_OPTS="-v"
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

# Function to verify API key permissions
verify_credentials() {
  echo "Verifying Twitter API credentials..."
  
  # Check if we have necessary OAuth 1.0a credentials
  if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ] || 
     [ -z "$TWITTER_ACCESS_TOKEN" ] || [ -z "$TWITTER_ACCESS_SECRET" ]; then
    echo "ERROR: Twitter OAuth credentials not found in .env file"
    echo "Please ensure TWITTER_API_KEY, TWITTER_API_SECRET, TWITTER_ACCESS_TOKEN, and TWITTER_ACCESS_TOKEN_SECRET are set in .env"
    return 1
  fi
  
  # API endpoint and HTTP method
  api_url="https://api.twitter.com/2/users/me"
  http_method="GET"
  
  # OAuth parameters
  nonce=$(date +%s%N | shasum | head -c 32)
  timestamp=$(date +%s)
  
  # Build parameter string - must be sorted alphabetically
  param_string=""
  param_string+="oauth_consumer_key=$(urlencode "$TWITTER_API_KEY")"
  param_string+="&oauth_nonce=$(urlencode "$nonce")"
  param_string+="&oauth_signature_method=HMAC-SHA1"
  param_string+="&oauth_timestamp=$timestamp"
  param_string+="&oauth_token=$(urlencode "$TWITTER_ACCESS_TOKEN")"
  param_string+="&oauth_version=1.0"
  
  # Create signature base string
  signature_base_string="$http_method&$(urlencode "$api_url")&$(urlencode "$param_string")"
  debug_log "Signature base string: $signature_base_string"
  
  # Create signing key - NOT URL encoded
  signing_key="${TWITTER_API_SECRET}&${TWITTER_ACCESS_SECRET}"
  
  # Generate signature
  signature=$(hmac_sha1 "$signing_key" "$signature_base_string")
  debug_log "Generated signature: $signature"
  
  # Build the Authorization header
  auth_header='OAuth '
  auth_header+="oauth_consumer_key=\"$(urlencode "$TWITTER_API_KEY")\", "
  auth_header+="oauth_nonce=\"$(urlencode "$nonce")\", "
  auth_header+="oauth_signature=\"$(urlencode "$signature")\", "
  auth_header+="oauth_signature_method=\"HMAC-SHA1\", "
  auth_header+="oauth_timestamp=\"$timestamp\", "
  auth_header+="oauth_token=\"$(urlencode "$TWITTER_ACCESS_TOKEN")\", "
  auth_header+="oauth_version=\"1.0\""
  
  # Set curl options
  CURL_OPTS="-s"
  if [ $DEBUG -eq 1 ]; then
    CURL_OPTS="-v"
  fi
  
  # Make the API request
  echo "Testing OAuth 1.0a authentication with current credentials..."
  local curl_result=$(curl $CURL_OPTS -X GET "$api_url" \
    -H "Authorization: $auth_header" 2>&1)
  
  local curl_status=$?
  
  if [ $curl_status -eq 0 ] && [[ "$curl_result" == *"data"* ]]; then
    echo "✅ OAuth 1.0a authentication SUCCESSFUL!"
    echo "Current credentials are valid and have the required permissions."
    
    # Try to parse permissions info
    local permissions=""
    if [[ "$curl_result" == *"read:tweets"* ]]; then
      permissions+="read:tweets "
    fi
    if [[ "$curl_result" == *"write:tweets"* ]]; then
      permissions+="write:tweets "
    fi
    
    if [ -n "$permissions" ]; then
      echo "Detected permissions: $permissions"
    fi
    
    return 0
  else
    echo "❌ OAuth 1.0a authentication FAILED!"
    echo "Error details: $curl_result"
    
    # Provide detailed error information
    if [[ "$curl_result" == *"401"* ]]; then
      echo "Authentication error (401) detected. Possible causes:"
      echo "1. API key doesn't have the required permissions"
      echo "2. Tokens may be expired or invalid"
      echo "3. OAuth signature calculation problem"
    fi
    
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
  "verify")
    verify_credentials
    ;;
  *)
    echo "Usage: $0 [--debug] {post|get|verify}"
    echo "  --debug          - Enable debug output for troubleshooting"
    echo "  post \"TEXT\"     - Post a tweet with the provided text"
    echo "  get              - Get recently posted tweets"
    echo "  verify           - Verify current API credentials"
    exit 1
    ;;
esac

exit 0