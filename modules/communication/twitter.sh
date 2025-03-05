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
TWITTER_REPO_URL="https://github.com/golergka/lifeform-2"

# Function to generate OAuth 1.0a signature
generate_oauth_signature() {
  local method="POST"
  local url="https://api.twitter.com/2/tweets"
  local tweet_text="$1"
  local timestamp=$(date +%s)
  local nonce=$(openssl rand -hex 16)
  
  # URL encode the tweet text for the request body
  local encoded_text=$(echo -n "$tweet_text" | jq -s -R -r @uri)
  local request_body="{\"text\":\"$tweet_text\"}"
  
  # Create parameter string
  local param_string="oauth_consumer_key=$TWITTER_API_KEY&oauth_nonce=$nonce&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$timestamp&oauth_token=$TWITTER_ACCESS_TOKEN&oauth_version=1.0"
  
  # Create signature base string
  local signature_base_string="$method&$(echo -n "$url" | jq -s -R -r @uri)&$(echo -n "$param_string" | jq -s -R -r @uri)"
  
  # Create signing key
  local signing_key="$(echo -n "$TWITTER_API_SECRET" | jq -s -R -r @uri)&$(echo -n "$TWITTER_ACCESS_SECRET" | jq -s -R -r @uri)"
  
  # Generate signature
  local signature=$(echo -n "$signature_base_string" | openssl dgst -sha1 -hmac "$signing_key" -binary | base64)
  
  # URL encode the signature
  local encoded_signature=$(echo -n "$signature" | jq -s -R -r @uri)
  
  echo "$encoded_signature"
}

# Function to post a tweet via API
post_tweet() {
  if [ -z "$1" ]; then
    echo "No tweet content provided"
    return 1
  fi
  
  tweet_content="$1"
  
  # Check if we have necessary API credentials
  if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ] || [ -z "$TWITTER_ACCESS_TOKEN" ] || [ -z "$TWITTER_ACCESS_SECRET" ]; then
    echo "ERROR: Twitter API credentials not found in .env file"
    echo "Please ensure all Twitter API credentials are set in .env"
    return 1
  fi
  
  echo "Twitter API credentials found, posting to Twitter API..."
  
  # Prepare for OAuth 1.0a authentication
  local timestamp=$(date +%s)
  local nonce=$(openssl rand -hex 16)
  
  # Generate OAuth signature
  local signature=$(generate_oauth_signature "$tweet_content")
  
  # Create OAuth header
  local auth_header="OAuth oauth_consumer_key=\"$TWITTER_API_KEY\", oauth_nonce=\"$nonce\", oauth_signature=\"$signature\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"$timestamp\", oauth_token=\"$TWITTER_ACCESS_TOKEN\", oauth_version=\"1.0\""
  
  # Prepare request body
  local request_body="{\"text\":\"$tweet_content\"}"
  
  # Attempt posting with OAuth 1.0a authentication
  echo "Posting tweet with OAuth 1.0a authentication..."
  local curl_result=$(curl -s -X POST "https://api.twitter.com/2/tweets" \
    -H "Authorization: $auth_header" \
    -H "Content-Type: application/json" \
    -d "$request_body" 2>&1)
  
  local curl_status=$?
  
  # Check if OAuth 1.0a authentication was successful
  if [ $curl_status -eq 0 ] && [[ "$curl_result" != *"error"* ]]; then
    echo "Tweet successfully posted to Twitter via OAuth 1.0a!"
    
    # Save to posted directory for record keeping
    mkdir -p "./modules/communication/posted_tweets"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local file_path="./modules/communication/posted_tweets/posted_${timestamp}.txt"
    echo "$tweet_content" > "$file_path"
    
    return 0
  fi
  
  # If OAuth 1.0a fails and we have a bearer token, try OAuth 2.0
  if [ -n "$TWITTER_BEARER_TOKEN" ]; then
    echo "OAuth 1.0a authentication failed, trying Bearer token (OAuth 2.0)..."
    
    local curl_result=$(curl -s -X POST "https://api.twitter.com/2/tweets" \
      -H "Authorization: Bearer $TWITTER_BEARER_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$request_body" 2>&1)
    
    local curl_status=$?
    
    # Check if Bearer token authentication was successful
    if [ $curl_status -eq 0 ] && [[ "$curl_result" != *"error"* ]]; then
      echo "Tweet successfully posted to Twitter via Bearer token!"
      
      # Save to posted directory for record keeping
      mkdir -p "./modules/communication/posted_tweets"
      local timestamp=$(date +"%Y%m%d_%H%M%S")
      local file_path="./modules/communication/posted_tweets/posted_${timestamp}.txt"
      echo "$tweet_content" > "$file_path"
      
      return 0
    fi
  fi
  
  # If all authentication methods fail, show error
  echo "ERROR: Failed to post tweet to Twitter API."
  echo "Error details: $curl_result"
  echo "Please check your API credentials and try again."
  
  return 1
}

# Function to list all posted tweets
list_posted_tweets() {
  echo "Posted tweets:"
  
  # Check if any posted tweets exist
  tweet_count=$(ls ./modules/communication/posted_tweets/posted_*.txt 2>/dev/null | wc -l)
  
  if [ "$tweet_count" -eq 0 ]; then
    echo "No posted tweets found"
    return 0
  fi
  
  # List all posted tweets with their content
  for tweet_file in $(ls -t ./modules/communication/posted_tweets/posted_*.txt); do
    filename=$(basename "$tweet_file")
    content=$(cat "$tweet_file")
    timestamp=${filename#posted_}
    timestamp=${timestamp%.txt}
    date_format=$(date -r "$tweet_file" "+%Y-%m-%d %H:%M:%S")
    
    echo "- Posted on $date_format: \"$content\""
  done
  
  return 0
}

# Main execution
case "$1" in
  "post")
    if [ -z "$2" ]; then
      echo "No tweet content provided"
      echo "Usage: $0 post \"Your tweet text\""
      exit 1
    else
      post_tweet "$2"
    fi
    ;;
  "list-posted")
    list_posted_tweets
    ;;
  *)
    echo "Usage: $0 {post|list-posted}"
    echo "  post \"TEXT\"       - Post a tweet with the provided text"
    echo "  list-posted      - List all posted tweets"
    exit 1
    ;;
esac

exit 0