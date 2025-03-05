#!/bin/bash
# Main execution script for lifeform-2

# Generate a unique session ID
SESSION_ID=$(date +"%Y%m%d%H%M%S")

# Capture start time for token estimation
START_TIME=$(date +%s)

echo "Starting Claude session with ID: $SESSION_ID"

# Simple one-liner to run Claude as requested by creator
claude --dangerously-skip-permissions -p "Read README and act. For every prompt, you must do plenty of sustained productive action, commit and push it." --print

# Estimate token usage (this is a rough estimate based on typical usage)
# In a more advanced implementation, we'd parse Claude's output for actual token counts
END_TIME=$(date +%s)
SESSION_DURATION=$((END_TIME - START_TIME))

# Rough estimate: 1000 input tokens, and output tokens based on session duration
# This is a very rough approximation - improve this with actual token counts when possible
INPUT_TOKENS=1000
OUTPUT_TOKENS=$((SESSION_DURATION * 10))  # Rough estimate of 10 tokens per second

# Log token usage
echo "Logging token usage for session $SESSION_ID"
./core/system/token_tracker.sh log "$SESSION_ID" "$INPUT_TOKENS" "$OUTPUT_TOKENS"

# Run any commands from commands.sh if it exists, then clear it
if [ -f "./commands.sh" ]; then
  echo "Running post-session commands..."
  source ./commands.sh > ./logs/commands_output.log 2>&1
  EXIT_CODE=$?
  echo "Exit code: $EXIT_CODE" >> ./logs/commands_output.log
  # Clear the commands file after running
  > ./commands.sh
fi

# Automatically commit and push any changes
echo "Automatically committing any changes..."
git add .
git commit -m "chore: automated commit after session" || echo "No changes to commit"
git push || echo "Failed to push changes"

exit 0