#!/bin/bash
# Twitter integration script for lifeform-2
# This script handles direct Twitter API posting using OAuth 1.0a authentication

# Load error utilities for consistent error handling and logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load error_utils.sh for consistent error handling
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="twitter.sh"

# Attempt to load .env file from various possible locations
if [ -f "$PROJECT_ROOT/.env" ]; then
  source "$PROJECT_ROOT/.env"
  log_info ".env file loaded from project root" "$SCRIPT_NAME"
elif [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
  log_info ".env file loaded from script directory" "$SCRIPT_NAME"
elif [ -f ".env" ]; then
  source ".env"
  log_info ".env file loaded from current directory" "$SCRIPT_NAME"
else
  log_warning "No .env file found, using environment variables if available" "$SCRIPT_NAME"
fi

# Config variables
TWITTER_API_KEY="${TWITTER_API_KEY:-""}"
TWITTER_API_SECRET="${TWITTER_API_SECRET:-""}"
TWITTER_ACCESS_TOKEN="${TWITTER_ACCESS_TOKEN:-""}"
TWITTER_ACCESS_SECRET="${TWITTER_ACCESS_TOKEN_SECRET:-""}" # Variable name in .env is TWITTER_ACCESS_TOKEN_SECRET
TWITTER_BEARER_TOKEN="${TWITTER_BEARER_TOKEN:-""}"
TWITTER_USERNAME="${TWITTER_USERNAME:-""}"
TWITTER_CLIENT_ID="${TWITTER_CLIENT_ID:-""}"
TWITTER_CLIENT_SECRET="${TWITTER_CLIENT_SECRET:-""}"

# Enable debugging if requested
DEBUG=0
if [ "$1" = "--debug" ]; then
  DEBUG=1
  shift
  log_info "Debug mode enabled" "$SCRIPT_NAME"
fi

# Function to log debug information with levels
debug_log() {
  if [ $DEBUG -eq 1 ]; then
    local level="${2:-INFO}"
    log_info "[DEBUG:$level] $1" "$SCRIPT_NAME"
  fi
}

# Function to show API keys without revealing full values (for debugging)
safe_key_debug() {
  local key="$1"
  local name="$2"
  
  if [ -n "$key" ]; then
    local first_chars="${key:0:4}"
    local last_chars="${key: -4}"
    local masked_key="${first_chars}...${last_chars}"
    debug_log "$name: $masked_key" "KEYS"
    return 0
  else
    debug_log "$name: NOT SET" "WARN"
    return 1
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
    log_error "No tweet content provided" "$SCRIPT_NAME"
    return 1
  fi
  
  tweet_content="$1"
  
  # Check if we have necessary OAuth 1.0a credentials
  if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ] || 
     [ -z "$TWITTER_ACCESS_TOKEN" ] || [ -z "$TWITTER_ACCESS_SECRET" ]; then
    log_error "Twitter OAuth credentials not found in .env file" "$SCRIPT_NAME"
    log_error "Please ensure TWITTER_API_KEY, TWITTER_API_SECRET, TWITTER_ACCESS_TOKEN, and TWITTER_ACCESS_TOKEN_SECRET are set in .env" "$SCRIPT_NAME"
    return 1
  fi
  
  # Debug credential information (safely masked)
  if [ $DEBUG -eq 1 ]; then
    debug_log "Checking OAuth 1.0a credentials for posting:" "CHECK"
    safe_key_debug "$TWITTER_API_KEY" "API Key"
    safe_key_debug "$TWITTER_API_SECRET" "API Secret"
    safe_key_debug "$TWITTER_ACCESS_TOKEN" "Access Token"
    safe_key_debug "$TWITTER_ACCESS_SECRET" "Access Secret"
    
    if [ -n "$TWITTER_CLIENT_ID" ]; then
      safe_key_debug "$TWITTER_CLIENT_ID" "Client ID"
    fi
    if [ -n "$TWITTER_CLIENT_SECRET" ]; then
      safe_key_debug "$TWITTER_CLIENT_SECRET" "Client Secret"
    fi
  fi
  
  log_info "OAuth 1.0a credentials found, preparing to post tweet..." "$SCRIPT_NAME"
  
  # First verify the credentials and permissions
  log_info "Verifying permissions before posting..." "$SCRIPT_NAME"
  
  # API endpoint and HTTP method for verification
  verify_api_url="https://api.twitter.com/2/users/me"
  verify_http_method="GET"
  
  # OAuth parameters for verification
  verify_nonce=$(date +%s%N | shasum | head -c 32)
  verify_timestamp=$(date +%s)
  
  # Build parameter string for verification - must be sorted alphabetically
  verify_param_string=""
  verify_param_string+="oauth_consumer_key=$(urlencode "$TWITTER_API_KEY")"
  verify_param_string+="&oauth_nonce=$(urlencode "$verify_nonce")"
  verify_param_string+="&oauth_signature_method=HMAC-SHA1"
  verify_param_string+="&oauth_timestamp=$verify_timestamp"
  verify_param_string+="&oauth_token=$(urlencode "$TWITTER_ACCESS_TOKEN")"
  verify_param_string+="&oauth_version=1.0"
  
  # Create verification signature base string
  verify_signature_base_string="$verify_http_method&$(urlencode "$verify_api_url")&$(urlencode "$verify_param_string")"
  debug_log "Verification signature base string: $verify_signature_base_string" "VERIFY"
  
  # Create signing key - NOT URL encoded
  verify_signing_key="${TWITTER_API_SECRET}&${TWITTER_ACCESS_SECRET}"
  
  # Generate verification signature
  verify_signature=$(hmac_sha1 "$verify_signing_key" "$verify_signature_base_string")
  debug_log "Verification signature: $verify_signature" "VERIFY"
  
  # Build the verification Authorization header
  verify_auth_header='OAuth '
  verify_auth_header+="oauth_consumer_key=\"$(urlencode "$TWITTER_API_KEY")\", "
  verify_auth_header+="oauth_nonce=\"$(urlencode "$verify_nonce")\", "
  verify_auth_header+="oauth_signature=\"$(urlencode "$verify_signature")\", "
  verify_auth_header+="oauth_signature_method=\"HMAC-SHA1\", "
  verify_auth_header+="oauth_timestamp=\"$verify_timestamp\", "
  verify_auth_header+="oauth_token=\"$(urlencode "$TWITTER_ACCESS_TOKEN")\", "
  verify_auth_header+="oauth_version=\"1.0\""
  
  # Set curl options for verification
  VERIFY_CURL_OPTS="-s"
  if [ $DEBUG -eq 1 ]; then
    VERIFY_CURL_OPTS="-v"
  fi
  
  # Make the verification API request
  debug_log "Verifying permissions..." "VERIFY"
  local verify_result=$(curl $VERIFY_CURL_OPTS -X GET "$verify_api_url" \
    -H "Authorization: $verify_auth_header" 2>&1)
  
  local verify_status=$?
  debug_log "Verify curl exit status: $verify_status" "VERIFY"
  
  # Check access level
  local access_level=""
  if [ $DEBUG -eq 1 ]; then
    access_level=$(echo "$verify_result" | grep -o "x-access-level: [^[:space:]]*" | cut -d' ' -f2)
    debug_log "Twitter API access level: $access_level" "PERM"
  fi
  
  # If we don't have write access, alert the user but still try to post
  if [ "$access_level" = "read" ]; then
    echo "⚠️  WARNING: Your Twitter app only has READ access!"
    echo "Please update the application to have 'Read and Write' permissions in the Twitter Developer Portal."
    echo "Attempting to post anyway, but expect a permission error..."
  fi

  # API endpoint and HTTP method for posting
  api_url="https://api.twitter.com/2/tweets"
  http_method="POST"
  
  # OAuth parameters for posting
  nonce=$(date +%s%N | shasum | head -c 32)
  timestamp=$(date +%s)
  
  # Prepare request body
  request_body="{\"text\":\"$tweet_content\"}"
  debug_log "Request body: $request_body" "POST"
  
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
  debug_log "Signature base string: $signature_base_string" "POST"
  
  # Create signing key - NOTE: The signing key should NOT be URL encoded
  signing_key="${TWITTER_API_SECRET}&${TWITTER_ACCESS_SECRET}"
  debug_log "Signing key format: [consumer_secret]&[access_token_secret]" "POST"
  
  # Generate signature
  signature=$(hmac_sha1 "$signing_key" "$signature_base_string")
  debug_log "Generated signature: $signature" "POST"
  
  # Build the Authorization header
  auth_header='OAuth '
  auth_header+="oauth_consumer_key=\"$(urlencode "$TWITTER_API_KEY")\", "
  auth_header+="oauth_nonce=\"$(urlencode "$nonce")\", "
  auth_header+="oauth_signature=\"$(urlencode "$signature")\", "
  auth_header+="oauth_signature_method=\"HMAC-SHA1\", "
  auth_header+="oauth_timestamp=\"$timestamp\", "
  auth_header+="oauth_token=\"$(urlencode "$TWITTER_ACCESS_TOKEN")\", "
  auth_header+="oauth_version=\"1.0\""
  
  debug_log "Auth Header (redacted): oauth_consumer_key=\"***\", oauth_nonce=\"$nonce\", oauth_signature=\"***\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"$timestamp\", oauth_token=\"***\", oauth_version=\"1.0\"" "POST"
  
  # Set curl options
  CURL_OPTS="-s"
  if [ $DEBUG -eq 1 ]; then
    CURL_OPTS="-v"
  fi
  
  # Make the API request using OAuth 1.0a
  log_info "Posting tweet with Twitter API using OAuth 1.0a..." "$SCRIPT_NAME"
  local curl_result=$(curl $CURL_OPTS -X POST "$api_url" \
    -H "Authorization: $auth_header" \
    -H "Content-Type: application/json" \
    -d "$request_body" 2>&1)
  
  local curl_status=$?
  debug_log "curl exit status: $curl_status" "POST"
  
  # Check if the post was successful
  if [ $curl_status -eq 0 ] && [[ "$curl_result" == *"data"* ]]; then
    log_info "✅ Tweet successfully posted to Twitter!" "$SCRIPT_NAME"
    
    # Extract tweet ID and URL when successful
    local tweet_id=$(echo "$curl_result" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$tweet_id" ]; then
      log_info "Tweet ID: $tweet_id" "$SCRIPT_NAME"
      log_info "Tweet URL: https://twitter.com/i/web/status/$tweet_id" "$SCRIPT_NAME"
    fi
    
    return 0
  else
    log_error "Failed to post tweet to Twitter API using OAuth 1.0a." "$SCRIPT_NAME"
    debug_log "Error response: $curl_result" "ERROR"
    
    # Additional debugging for specific errors
    if [[ "$curl_result" == *"oauth1 app permissions"* || "$curl_result" == *"oauth1-permissions"* ]]; then
      log_error "PERMISSIONS ERROR DETECTED!" "$SCRIPT_NAME"
      log_error "Your Twitter app doesn't have the 'Write' permission enabled." "$SCRIPT_NAME"
      log_error "To fix this issue:" "$SCRIPT_NAME"
      log_error "1. Log in to the Twitter Developer Portal (developer.twitter.com)" "$SCRIPT_NAME"
      log_error "2. Navigate to your Projects & Apps" "$SCRIPT_NAME"
      log_error "3. Select your app" "$SCRIPT_NAME"
      log_error "4. Go to 'User authentication settings'" "$SCRIPT_NAME"
      log_error "5. Change the App permissions from 'Read' to 'Read and Write'" "$SCRIPT_NAME"
      log_error "6. Save changes" "$SCRIPT_NAME"
      log_error "Once this is done, try posting again." "$SCRIPT_NAME"
    elif [[ "$curl_result" == *"401"* ]]; then
      log_error "Authentication error (401) detected. Possible causes:" "$SCRIPT_NAME"
      log_error "1. OAuth signature calculation problem" "$SCRIPT_NAME"
      log_error "2. Clock synchronization issue" "$SCRIPT_NAME"
      log_error "3. Token might be expired or invalid" "$SCRIPT_NAME"
    fi
    
    # If unable to post with OAuth 1.0a, remind about fallback for getting tweets
    if [ -n "$TWITTER_BEARER_TOKEN" ]; then
      log_warning "Note: You can still retrieve tweets using the Bearer Token." "$SCRIPT_NAME"
      log_warning "Try running: $0 get" "$SCRIPT_NAME"
    fi
    
    return 1
  fi
}

# Function to get recently posted tweets
get_tweets() {
  log_info "Fetching recent tweets..." "$SCRIPT_NAME"
  
  # Check if we have necessary API credentials
  if [ -z "$TWITTER_BEARER_TOKEN" ]; then
    log_error "Twitter Bearer Token not found in .env file" "$SCRIPT_NAME"
    log_error "Please ensure TWITTER_BEARER_TOKEN is set in .env" "$SCRIPT_NAME"
    return 1
  fi
  
  if [ -z "$TWITTER_USERNAME" ]; then
    log_error "Twitter username not found in .env file" "$SCRIPT_NAME"
    log_error "Please ensure TWITTER_USERNAME is set in .env" "$SCRIPT_NAME"
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
    log_error "Rate limit exceeded. Please try again later." "$SCRIPT_NAME"
    log_error "Twitter API has rate limits on the number of requests you can make in a time period." "$SCRIPT_NAME"
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
        log_error "Rate limit exceeded. Please try again later." "$SCRIPT_NAME"
        log_error "Twitter API has rate limits on the number of requests you can make in a time period." "$SCRIPT_NAME"
        return 1
      fi
      
      if [ $tweets_status -eq 0 ] && [[ "$tweets_result" == *"data"* ]]; then
        log_info "Successfully retrieved tweets!" "$SCRIPT_NAME"
        
        # Try to use jq, but handle case where it might fail
        parsed_tweets=$(echo "$tweets_result" | jq '.' 2>/dev/null)
        if [ $? -eq 0 ]; then
          echo "$parsed_tweets"
        else
          log_warning "Raw response (jq parsing failed):" "$SCRIPT_NAME"
          echo "$tweets_result"
        fi
        
        return 0
      else
        log_error "Failed to retrieve tweets." "$SCRIPT_NAME"
        log_error "Error details: $tweets_result" "$SCRIPT_NAME"
        return 1
      fi
    else
      log_error "Failed to extract user ID from response." "$SCRIPT_NAME"
      log_error "Response: $curl_result" "$SCRIPT_NAME"
      return 1
    fi
  else
    log_error "Failed to retrieve user information." "$SCRIPT_NAME"
    log_error "Error details: $curl_result" "$SCRIPT_NAME"
    return 1
  fi
}

# Function to verify API key permissions
verify_credentials() {
  log_info "Verifying Twitter API credentials..." "$SCRIPT_NAME"
  
  # Check if we have necessary OAuth 1.0a credentials
  if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ] || 
     [ -z "$TWITTER_ACCESS_TOKEN" ] || [ -z "$TWITTER_ACCESS_SECRET" ]; then
    log_error "Twitter OAuth credentials not found in .env file" "$SCRIPT_NAME"
    log_error "Please ensure TWITTER_API_KEY, TWITTER_API_SECRET, TWITTER_ACCESS_TOKEN, and TWITTER_ACCESS_TOKEN_SECRET are set in .env" "$SCRIPT_NAME"
    return 1
  fi
  
  # Debug credential information (safely masked)
  if [ $DEBUG -eq 1 ]; then
    debug_log "Checking OAuth 1.0a credentials:" "CHECK"
    safe_key_debug "$TWITTER_API_KEY" "API Key"
    safe_key_debug "$TWITTER_API_SECRET" "API Secret"
    safe_key_debug "$TWITTER_ACCESS_TOKEN" "Access Token"
    safe_key_debug "$TWITTER_ACCESS_SECRET" "Access Secret"
    
    if [ -n "$TWITTER_CLIENT_ID" ]; then
      safe_key_debug "$TWITTER_CLIENT_ID" "Client ID"
    fi
    if [ -n "$TWITTER_CLIENT_SECRET" ]; then
      safe_key_debug "$TWITTER_CLIENT_SECRET" "Client Secret"
    fi
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
  log_info "Testing OAuth 1.0a authentication with current credentials..." "$SCRIPT_NAME"
  local curl_result=$(curl $CURL_OPTS -X GET "$api_url" \
    -H "Authorization: $auth_header" 2>&1)
  
  local curl_status=$?
  debug_log "curl exit status: $curl_status"
  
  if [ $curl_status -eq 0 ] && [[ "$curl_result" == *"data"* ]]; then
    # Look for the x-access-level header in the verbose output
    local access_level=""
    if [ $DEBUG -eq 1 ]; then
      access_level=$(echo "$curl_result" | grep -o "x-access-level: [^[:space:]]*" | cut -d' ' -f2)
      if [ -n "$access_level" ]; then
        debug_log "Twitter API access level: $access_level" "PERM"
      fi
    fi
    
    log_info "✅ OAuth 1.0a authentication SUCCESSFUL!" "$SCRIPT_NAME"
    
    # Check access level
    if [ "$access_level" = "read-write" ] || [ "$access_level" = "read-write-directmessages" ]; then
      log_info "✅ Account has READ-WRITE access. Posting tweets should work!" "$SCRIPT_NAME"
    elif [ "$access_level" = "read" ]; then
      log_warning "⚠️  Account only has READ access. Posting tweets will NOT work!" "$SCRIPT_NAME"
      log_warning "Please update the application to have 'Read and Write' permissions in the Twitter Developer Portal." "$SCRIPT_NAME"
    else
      log_info "Current credentials are valid and have the required authentication." "$SCRIPT_NAME"
      log_info "If you can't post tweets, make sure your Twitter app has 'Read and Write' permissions." "$SCRIPT_NAME"
    fi
    
    # Try to parse permissions from the response body
    local permissions=""
    if [[ "$curl_result" == *"read:tweets"* ]]; then
      permissions+="read:tweets "
    fi
    if [[ "$curl_result" == *"write:tweets"* ]]; then
      permissions+="write:tweets "
    fi
    
    if [ -n "$permissions" ]; then
      log_info "Detected permissions: $permissions" "$SCRIPT_NAME"
    fi
    
    return 0
  else
    log_error "❌ OAuth 1.0a authentication FAILED!" "$SCRIPT_NAME"
    debug_log "Error response: $curl_result" "ERROR"
    
    # Provide detailed error information
    if [[ "$curl_result" == *"401"* ]]; then
      log_error "Authentication error (401) detected. Possible causes:" "$SCRIPT_NAME"
      log_error "1. API key doesn't have the required permissions" "$SCRIPT_NAME"
      log_error "2. Tokens may be expired or invalid" "$SCRIPT_NAME"
      log_error "3. OAuth signature calculation problem" "$SCRIPT_NAME"
      log_error "4. Check that your app was created with OAuth 1.0a enabled" "$SCRIPT_NAME"
    elif [[ "$curl_result" == *"403"* ]]; then
      log_error "Permission error (403) detected. Possible causes:" "$SCRIPT_NAME"
      log_error "1. App permissions not set correctly in Twitter Developer Portal" "$SCRIPT_NAME"
      log_error "2. Rate limiting or access restrictions" "$SCRIPT_NAME"
    fi
    
    return 1
  fi
}

# Function to perform a detailed check of Twitter API configuration
detailed_check() {
  log_info "===== Twitter API Configuration Detailed Check =====" "$SCRIPT_NAME"
  log_info "Running checks on $(date '+%Y-%m-%d %H:%M:%S')" "$SCRIPT_NAME"
  log_info "" "$SCRIPT_NAME"
  
  # 1. Check for environment variables
  echo "1. Checking Twitter API environment variables..."
  
  local missing_vars=0
  check_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    if [ -z "$var_value" ]; then
      echo "  ❌ $var_name: missing"
      missing_vars=$((missing_vars + 1))
    else
      # Show first 4 and last 4 characters of the value for debugging
      local first_chars="${var_value:0:4}"
      local last_chars="${var_value: -4}"
      echo "  ✅ $var_name: ${first_chars}...${last_chars}"
    fi
  }
  
  check_var "TWITTER_API_KEY"
  check_var "TWITTER_API_SECRET"
  check_var "TWITTER_ACCESS_TOKEN"
  check_var "TWITTER_ACCESS_TOKEN_SECRET"
  check_var "TWITTER_BEARER_TOKEN"
  check_var "TWITTER_USERNAME"
  
  if [ -n "$TWITTER_CLIENT_ID" ]; then
    check_var "TWITTER_CLIENT_ID"
  fi
  if [ -n "$TWITTER_CLIENT_SECRET" ]; then
    check_var "TWITTER_CLIENT_SECRET"
  fi
  
  if [ $missing_vars -gt 0 ]; then
    echo "  ⚠️  $missing_vars environment variables are missing!"
    echo "  Please update your .env file with the missing credentials."
  else
    echo "  ✅ All required environment variables are set."
  fi
  echo ""
  
  # 2. Check OAuth authentication
  echo "2. Testing OAuth 1.0a authentication..."
  # API endpoint and HTTP method for verification
  local verify_api_url="https://api.twitter.com/2/users/me"
  local verify_http_method="GET"
  
  # OAuth parameters for verification
  local verify_nonce=$(date +%s%N | shasum | head -c 32)
  local verify_timestamp=$(date +%s)
  
  # Build parameter string for verification - must be sorted alphabetically
  local verify_param_string=""
  verify_param_string+="oauth_consumer_key=$(urlencode "$TWITTER_API_KEY")"
  verify_param_string+="&oauth_nonce=$(urlencode "$verify_nonce")"
  verify_param_string+="&oauth_signature_method=HMAC-SHA1"
  verify_param_string+="&oauth_timestamp=$verify_timestamp"
  verify_param_string+="&oauth_token=$(urlencode "$TWITTER_ACCESS_TOKEN")"
  verify_param_string+="&oauth_version=1.0"
  
  # Create verification signature base string
  local verify_signature_base_string="$verify_http_method&$(urlencode "$verify_api_url")&$(urlencode "$verify_param_string")"
  
  # Create signing key - NOT URL encoded
  local verify_signing_key="${TWITTER_API_SECRET}&${TWITTER_ACCESS_SECRET}"
  
  # Generate verification signature
  local verify_signature=$(hmac_sha1 "$verify_signing_key" "$verify_signature_base_string")
  
  # Build the verification Authorization header
  local verify_auth_header='OAuth '
  verify_auth_header+="oauth_consumer_key=\"$(urlencode "$TWITTER_API_KEY")\", "
  verify_auth_header+="oauth_nonce=\"$(urlencode "$verify_nonce")\", "
  verify_auth_header+="oauth_signature=\"$(urlencode "$verify_signature")\", "
  verify_auth_header+="oauth_signature_method=\"HMAC-SHA1\", "
  verify_auth_header+="oauth_timestamp=\"$verify_timestamp\", "
  verify_auth_header+="oauth_token=\"$(urlencode "$TWITTER_ACCESS_TOKEN")\", "
  verify_auth_header+="oauth_version=\"1.0\""
  
  # Set curl options for verification
  local verify_curl_opts="-s"
  if [ $DEBUG -eq 1 ]; then
    verify_curl_opts="-v"
  fi
  
  # Make the verification API request
  local verify_result=$(curl $verify_curl_opts -X GET "$verify_api_url" \
    -H "Authorization: $verify_auth_header" 2>&1)
  
  local verify_status=$?
  
  if [ $verify_status -eq 0 ] && [[ "$verify_result" == *"data"* ]]; then
    echo "  ✅ OAuth 1.0a authentication SUCCESSFUL!"
    
    # Check access level
    local access_level=$(echo "$verify_result" | grep -o "x-access-level: [^[:space:]]*" | cut -d' ' -f2)
    
    if [ -n "$access_level" ]; then
      echo "  ✓ Access level: $access_level"
      
      if [ "$access_level" = "read-write" ] || [ "$access_level" = "read-write-directmessages" ]; then
        echo "  ✅ Your app has READ-WRITE access. Posting tweets should work!"
      elif [ "$access_level" = "read" ]; then
        echo "  ❌ Your app only has READ access. Posting tweets will NOT work!"
        echo "  Please update the application to have 'Read and Write' permissions in the Twitter Developer Portal."
      else
        echo "  ⚠️  Unknown access level. Check Twitter Developer Portal settings."
      fi
    else
      echo "  ⚠️  Could not determine access level from response headers."
    fi
    
    # Extract account details
    local user_id=$(echo "$verify_result" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    local username=$(echo "$verify_result" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
    local name=$(echo "$verify_result" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$user_id" ] && [ -n "$username" ]; then
      echo "  ✓ Twitter account details:"
      echo "    - User ID: $user_id"
      echo "    - Username: @$username"
      if [ -n "$name" ]; then
        echo "    - Display name: $name"
      fi
    fi
  else
    echo "  ❌ OAuth 1.0a authentication FAILED!"
    echo "  Error details: $verify_result"
    
    # Provide detailed error information
    if [[ "$verify_result" == *"401"* ]]; then
      echo "  Authentication error (401) detected. Possible causes:"
      echo "  1. API key doesn't have the required permissions"
      echo "  2. Tokens may be expired or invalid"
      echo "  3. OAuth signature calculation problem"
      echo "  4. Check that your app was created with OAuth 1.0a enabled"
    elif [[ "$verify_result" == *"403"* ]]; then
      echo "  Permission error (403) detected. Possible causes:"
      echo "  1. App permissions not set correctly in Twitter Developer Portal"
      echo "  2. Rate limiting or access restrictions"
    fi
  fi
  echo ""
  
  # 3. Test Bearer token access
  echo "3. Testing Bearer token authentication (for reading tweets)..."
  if [ -z "$TWITTER_BEARER_TOKEN" ]; then
    echo "  ❌ Bearer token not found. Reading tweets may not work."
  else
    local bearer_api_url="https://api.twitter.com/2/tweets/search/recent?query=from:$TWITTER_USERNAME&max_results=10"
    local bearer_result=$(curl -s -X GET "$bearer_api_url" \
      -H "Authorization: Bearer $TWITTER_BEARER_TOKEN" 2>&1)
    
    if [[ "$bearer_result" == *"data"* || "$bearer_result" == *"meta"* ]]; then
      echo "  ✅ Bearer token authentication SUCCESSFUL!"
      echo "  You can retrieve tweets using the 'get' command."
    else 
      echo "  ❌ Bearer token authentication FAILED!"
      echo "  Error details: $bearer_result"
    fi
  fi
  echo ""
  
  # 4. Suggest next steps
  echo "4. Recommended next steps:"
  
  local has_problems=0
  
  if [ $missing_vars -gt 0 ]; then
    echo "  • Update your .env file with the missing credentials"
    has_problems=1
  fi
  
  if [[ "$access_level" = "read" ]]; then
    echo "  • Update your Twitter app to have 'Read and Write' permissions:"
    echo "    1. Log in to the Twitter Developer Portal (developer.twitter.com)"
    echo "    2. Navigate to your Projects & Apps"
    echo "    3. Select your app"
    echo "    4. Go to 'User authentication settings'"
    echo "    5. Change the App permissions from 'Read' to 'Read and Write'"
    echo "    6. Save changes"
    has_problems=1
  fi
  
  if [ "$has_problems" -eq 0 ]; then
    echo "  • Your Twitter API configuration looks good! Try posting a tweet:"
    echo "    $0 post \"Hello world from Lifeform-2!\""
  else
    echo "  • After addressing these issues, run the check again:"
    echo "    $0 check"
  fi
  
  echo ""
  echo "===== Twitter API Configuration Check Complete ====="
}

# Main execution
case "$1" in
  "post")
    if [ -z "$2" ]; then
      log_error "No tweet content provided" "$SCRIPT_NAME"
      log_error "Usage: $0 [--debug] post \"Your tweet text\"" "$SCRIPT_NAME"
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
  "check")
    detailed_check
    ;;
  *)
    log_info "Usage: $0 [--debug] {post|get|verify|check}" "$SCRIPT_NAME"
    log_info "  --debug          - Enable debug output for troubleshooting" "$SCRIPT_NAME"
    log_info "  post \"TEXT\"     - Post a tweet with the provided text" "$SCRIPT_NAME"
    log_info "  get              - Get recently posted tweets" "$SCRIPT_NAME"
    log_info "  verify           - Verify current API credentials" "$SCRIPT_NAME"
    log_info "  check            - Perform detailed check of Twitter API configuration" "$SCRIPT_NAME"
    exit 1
    ;;
esac

exit 0