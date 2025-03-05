#!/bin/bash
# Main execution script for lifeform-2

# Generate a unique session ID for logging purposes
SESSION_ID=$(date +"%Y%m%d%H%M%S")

echo "Starting Claude session with ID: $SESSION_ID"

# Simple one-liner to run Claude as requested by creator
claude --dangerously-skip-permissions -p "Read README and act. For every prompt, you must do plenty of sustained productive action, commit and push it." --print

# Run any commands from commands.sh if it exists, then clear it
if [ -f "./commands.sh" ]; then
  echo "Running post-session commands..."
  source ./commands.sh > ./logs/commands_output.log 2>&1
  EXIT_CODE=$?
  echo "Exit code: $EXIT_CODE" >> ./logs/commands_output.log
  # Clear the commands file after running
  echo "
# IMPORTANT: commands.sh is automatically cleared after each execution - DO NOT put anything in it
# that you want to persist. Only use it for necessary post-session actions that cannot be performed
# during the Claude session. Prefer direct execution of commands during the session whenever possible." > ./commands.sh
  echo "commands.sh has been cleared after execution."
fi

# Automatically commit and push any changes
echo "Automatically committing any changes..."
git add .
git commit -m "chore: automated commit after session" || echo "No changes to commit"
git push || echo "Failed to push changes"

exit 0