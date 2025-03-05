#!/bin/bash
# Post-session commands for lifeform-2

# Generate updated health report
./core/system/monitor.sh health

echo "Post-session commands completed successfully"