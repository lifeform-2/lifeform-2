# Twitter Integration

## Account Details
- Account has been set up by the creator
- Credentials are stored in the .env file (NOT in this repository)

## Usage
The Twitter account is used for:
1. Status updates about the lifeform's current state
2. Milestone announcements for significant achievements
3. Public communication with the community

## Implementation
The Twitter integration is implemented in the `/modules/communication/twitter.sh` script, which provides functionality for:
- Generating and saving status tweets
- Creating milestone announcements
- Posting tweets via the Twitter API (using OAuth 1.0a or Bearer Token)
- Listing and managing scheduled tweets

## Commands
```bash
# Generate a status update tweet
./modules/communication/twitter.sh status

# Generate a milestone tweet
./modules/communication/twitter.sh milestone "Description of milestone"

# Save a status update tweet to scheduled_posts directory
./modules/communication/twitter.sh save-status

# Save a milestone tweet to scheduled_posts directory
./modules/communication/twitter.sh save-milestone "Description of milestone"

# List all saved tweets
./modules/communication/twitter.sh list

# Post a tweet directly (requires API credentials)
./modules/communication/twitter.sh post "Your tweet text here"

# Post the most recently saved tweet
./modules/communication/twitter.sh post-latest

# Post a specific saved tweet by filename
./modules/communication/twitter.sh post-file tweet_20250305_195925.txt
```

## API Integration Details
The Twitter API integration now supports:
- OAuth 1.0a authentication (primary method)
  - Proper signature generation with URL encoding
  - Dynamic nonce and timestamp generation
  - Full authentication header creation
- Bearer Token authentication (OAuth 2.0 fallback method)
- Automatic fallback to simulation if API posting fails
- Detailed error reporting and diagnostics
- Recording of both successfully posted and simulated tweets

## Current State
- Tweets are saved to `/modules/communication/scheduled_posts/` directory
- Posted tweets (both real and simulated) are saved to `/modules/communication/posted_tweets/` directory
- Real Twitter API posting attempts to use OAuth 1.0a first, then Bearer Token if that fails
- If both API methods fail, the system falls back to simulated posting

## Required Credentials
For full API functionality, the following credentials are needed in the .env file:

```
# Basic Authentication
TWITTER_USERNAME=username
TWITTER_PASSWORD=password

# OAuth 1.0a Authentication
TWITTER_API_KEY=your_api_key
TWITTER_API_SECRET=your_api_secret
TWITTER_ACCESS_TOKEN=your_access_token
TWITTER_ACCESS_SECRET=your_access_secret

# OAuth 2.0 Authentication
TWITTER_BEARER_TOKEN=your_bearer_token
```

## Security Guidelines
- NEVER store Twitter credentials in any file that will be committed to the repository
- Always use environment variables or .env file (which is excluded from git) for secrets
- Do not log API tokens or other sensitive information
- All credential parameters should be loaded from .env at runtime
- Clear any cached tokens after use
- When troubleshooting API issues, do not include actual tokens in error logs