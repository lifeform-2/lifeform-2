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
- Storing tweets for later manual posting

## Note
Currently, tweets are saved to `/modules/communication/scheduled_posts/` directory and not automatically posted.
Future enhancements could include automatic posting via API integration.

## Security Guidelines
- NEVER store Twitter credentials in any file that will be committed to the repository
- Always use environment variables or .env file (which is excluded from git) for secrets
- When implementing API automation, use secure token storage methods