#!/bin/bash
# Main execution script for lifeform-2

# Load configuration if available
CONFIG_FILE="./config/api_config.json"
if [ -f "$CONFIG_FILE" ]; then
  # Extract values from config (simplified - could use jq in production)
  PROMPT=$(grep -o '"default_prompt": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
else
  # Default prompt if config not available
  PROMPT="Read README and act. Make sure to document your actions in the session log. For each input prompt, you should do some productive work, commit and push everything that you change."
fi

# Create logs directory if it doesn't exist
mkdir -p ./logs

# Log session start
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting lifeform session" >> ./logs/session.log 2>/dev/null

# Execute Claude with appropriate parameters
claude --dangerously-skip-permissions -p "$PROMPT" --print

# Log session end
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ending lifeform session" >> ./logs/session.log 2>/dev/null

# Run monitoring if available
if [ -f "./core/system/monitor.sh" ]; then
  ./core/system/monitor.sh metrics >> ./logs/metrics.log 2>/dev/null
fi

exit 0