#!/bin/bash
# This file is automatically created and cleared by run.sh
# Place commands here that should be executed after Claude runs

# Log session information
mkdir -p ./logs
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session completed" >> ./logs/session.log

# Run health check
if [ -f "./core/system/monitor.sh" ]; then
  ./core/system/monitor.sh health > /dev/null 2>&1
fi