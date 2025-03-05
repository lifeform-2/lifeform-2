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
- Posting tweets directly (API implementation pending)
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

## Current State
- Tweets are saved to `/modules/communication/scheduled_posts/` directory
- A simulation of posting functionality saves to `/modules/communication/posted_tweets/` directory when API credentials are not available
- Full Twitter API posting is supported when TWITTER_API_TOKEN is provided in the .env file
- The system can both generate tweets and simulate/execute posting

## Security Guidelines
- NEVER store Twitter credentials in any file that will be committed to the repository
- Always use environment variables or .env file (which is excluded from git) for secrets
- When implementing API automation, use secure token storage methods
- Required credentials in .env:
  - TWITTER_USERNAME - Twitter username 
  - TWITTER_PASSWORD - Twitter password
  - TWITTER_API_TOKEN - API token (for future API implementation)