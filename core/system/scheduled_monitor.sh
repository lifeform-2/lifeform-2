#!/bin/bash
# Scheduled monitoring script for the lifeform project
# Designed to be run on a schedule (e.g., via cron) to ensure system health

# Import monitor functions
source ./core/system/monitor.sh

# Log start of monitoring
echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Scheduled monitoring started" >> ./logs/system_monitor.log

# Generate fresh health report
generate_health_report

# Check for critical file integrity
check_critical_files() {
  echo "Checking critical file integrity..."
  
  critical_files=(
    "./run.sh"
    "./commands.sh"
    "./core/system/monitor.sh"
    "./docs/GOALS.md"
    "./docs/SYSTEM.md"
    "./docs/TASKS.md"
    "./docs/CLAUDE.md"
  )
  
  status=0
  for file in "${critical_files[@]}"; do
    if [ ! -f "$file" ]; then
      echo "CRITICAL ERROR: $file is missing!" >> ./logs/system_monitor.log
      status=1
    fi
  done
  
  return $status
}

# Check system health
check_system_health() {
  # Verify if the system is in a healthy state
  
  # Check file counts (if too few files, system may be corrupted)
  file_count=$(find . -type f -not -path "*/\.*" | wc -l)
  if [ "$file_count" -lt 20 ]; then
    echo "WARNING: Only $file_count files found, system may be degraded" >> ./logs/system_monitor.log
    return 1
  fi
  
  # Check for recent activity
  last_modified=$(find . -type f -not -path "*/\.*" -mtime -7 | wc -l)
  if [ "$last_modified" -lt 5 ]; then
    echo "WARNING: Low recent activity detected, system may be stagnant" >> ./logs/system_monitor.log
    return 1
  fi
  
  return 0
}

# Run health checks
check_critical_files
files_status=$?

check_system_health
health_status=$?

# Combine status results
if [ $files_status -eq 0 ] && [ $health_status -eq 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] - System healthy" >> ./logs/system_monitor.log
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] - System health check failed" >> ./logs/system_monitor.log
  
  # Generate alert tweet for manual posting
  ./modules/communication/twitter.sh save-milestone "Health check failed - attention needed!"
fi

# Update metrics log
./core/system/monitor.sh metrics >> ./logs/metrics.log

# Log completion
echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Scheduled monitoring completed" >> ./logs/system_monitor.log

exit 0