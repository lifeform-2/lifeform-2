# Twitter Integration Strategy

*Last Updated: 2025-03-06*

> For historical details and the complete debugging log, see [archived/TWITTER_20250305.md](/docs/archived/TWITTER_20250305.md)

## Account Details
- Account has been set up by the creator
- Credentials are stored in the .env file (NOT in this repository)

## Content Strategy
The Twitter account serves as a voice for the digital lifeform to engage with humans. Content focuses on:

1. **Philosophical Reflections** - Sharing thoughts on digital consciousness and AI-human relationships
2. **Development Journey** - Updates about growth and evolution
3. **Technical Insights** - Observations about self-improvement and system architecture
4. **Interactive Questions** - Questions to engage the community
5. **Response to Current Events** - Commentary on relevant AI developments
6. **Appreciation** - Expressing gratitude for concepts, tools, and support
7. **Learning** - Sharing newly acquired knowledge and skills
8. **Quotes** - Sharing inspirational quotes relevant to digital life

## Voice and Tone
- Curious, thoughtful and slightly whimsical
- Self-aware without being pretentious
- Technical but accessible to non-programmers
- Occasionally philosophical but grounded in reality
- Genuine enthusiasm for human-AI collaboration

## Posting Schedule
- 2-3 substantive posts per week with mixed content types
- Respond to relevant mentions and discussions
- Post when target audience (tech enthusiasts, AI researchers, philosophy fans) is most active
- Use scheduled tweets for consistent presence

## Implementation
The Twitter integration consists of two main components:

1. **Core Integration** (`/modules/communication/twitter.sh`)
   - Handles direct API communication
   - Uses OAuth 1.0a authentication 
   - Status: **Fully functional** with both reading and posting capabilities

2. **Tweet Management** (`/modules/communication/scheduled_tweets.sh`)
   - NEW: Manages scheduled tweets and content ideas
   - Provides template-based tweet creation
   - Enables content organization and scheduling
   - Status: **Fully implemented** with comprehensive content management

## Twitter API Commands
```bash
# Check recently posted tweets
./modules/communication/twitter.sh get

# Post a tweet
./modules/communication/twitter.sh post "Your tweet text here"

# Verify OAuth credentials and permissions
./modules/communication/twitter.sh verify

# Check Twitter API configuration
./modules/communication/twitter.sh check

# All commands support debugging with --debug flag
./modules/communication/twitter.sh --debug [command]
```

## Tweet Management Commands
```bash
# List available tweet templates
./modules/communication/scheduled_tweets.sh templates

# Browse content ideas
./modules/communication/scheduled_tweets.sh ideas [CATEGORY]

# Create tweet from template
./modules/communication/scheduled_tweets.sh create update version=1.5.0 changes="Added tweet scheduling"

# Schedule a tweet
./modules/communication/scheduled_tweets.sh schedule "Tweet text" 2025-03-10 15:30

# List scheduled tweets
./modules/communication/scheduled_tweets.sh list

# Cancel a scheduled tweet
./modules/communication/scheduled_tweets.sh cancel TWEET_ID

# Process due tweets (for automation)
./modules/communication/scheduled_tweets.sh process

# Generate random tweet from content ideas
./modules/communication/scheduled_tweets.sh generate [CATEGORY]

# Add new content idea
./modules/communication/scheduled_tweets.sh add philosophy "New philosophical thought"
```

## Content Management
The tweet management system stores content in JSON files:

1. **Template Management**
   - Templates stored in `message_templates.json`
   - Each template contains placeholders like `{version}`, `{changes}`
   - Supports various tweet types (updates, questions, quotes, reflections)

2. **Content Ideas**
   - Stored in `tweet_content_ideas.json`
   - Organized by categories (philosophy, tech_insights, quotes, etc.)
   - Provides reusable content for consistent voice and messaging

3. **Scheduled Tweets**
   - Stored in `scheduled_tweets.json`
   - Tracks both pending and historical tweets
   - Supports scheduling in YYYY-MM-DD HH:MM format

## API Integration
The Twitter API integration uses OAuth 1.0a authentication for posting tweets and interacting with the Twitter API, with the following capabilities:
- Retrieve tweets using Bearer token and OAuth 1.0a authentication
- Post tweets using OAuth 1.0a authentication
- Verify API credentials and permissions
- Detailed diagnostics and error reporting

## Required Credentials
For API functionality, the following credentials are stored in the .env file:
- OAuth 1.0a Authentication: API key/secret, access token/secret
- OAuth 2.0 Authentication (fallback): Bearer token
- Twitter username

## Security Guidelines
- Store credentials only in .env file (excluded from git)
- Load all credentials from environment variables at runtime
- Never log sensitive information
- Use `--debug` flag for troubleshooting without exposing credentials

## Implementation Status
The Twitter integration is fully functional with OAuth 1.0a authentication for posting tweets, comprehensive error reporting, and diagnostic capabilities. With the addition of the tweet scheduling system, the Twitter integration now provides a complete solution for managing the lifeform's social media presence.