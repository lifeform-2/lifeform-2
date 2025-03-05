#!/bin/bash
# Main execution script for lifeform-2

# Simple one-liner to run Claude as requested by creator
claude --dangerously-skip-permissions -p "read README and act" --print

# Run any commands from commands.sh if it exists, then clear it
if [ -f "./commands.sh" ]; then
  echo "Running post-session commands..."
  source ./commands.sh > ./logs/commands_output.log 2>&1
  EXIT_CODE=$?
  echo "Exit code: $EXIT_CODE" >> ./logs/commands_output.log
  # Clear the commands file after running
  > ./commands.sh
fi

exit 0