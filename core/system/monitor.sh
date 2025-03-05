#!/bin/bash
# System monitoring script for the lifeform project
# Monitors system health, file sizes, and resource usage

# Function to monitor file sizes
monitor_file_sizes() {
  echo "Monitoring file sizes..."
  find . -type f -not -path "*/\.*" | while read file; do
    size=$(wc -c < "$file")
    echo "$(basename $file): $size bytes"
  done
}

# Function to check for changes since last run
check_changes() {
  echo "Checking for changes since last run..."
  
  # Store current state in temporary file
  find . -type f -not -path "*/\.*" -exec md5 {} \; > /tmp/lifeform_current.md5
  
  # Compare with previous state if it exists
  if [ -f "./logs/previous_state.md5" ]; then
    echo "Changes since last run:"
    diff -u "./logs/previous_state.md5" "/tmp/lifeform_current.md5" | grep -E "^\+|^\-" | grep -v "^\+\+\+|^\-\-\-"
  else
    echo "No previous state to compare with."
  fi
  
  # Save current state for next time
  mkdir -p ./logs
  cp /tmp/lifeform_current.md5 ./logs/previous_state.md5
}

# Function to update system metrics in SYSTEM.md
update_metrics() {
  echo "Updating system metrics..."
  
  # Get file count
  file_count=$(find . -type f -not -path "*/\.*" | wc -l)
  
  # Get directory count
  dir_count=$(find . -type d -not -path "*/\.*" | wc -l)
  
  # Get total size
  total_size=$(find . -type f -not -path "*/\.*" -exec wc -c {} \; | awk '{total += $1} END {print total}')
  
  # Format size to KB
  total_size_kb=$(echo "scale=1; $total_size/1024" | bc)
  
  # Get current date
  current_date=$(date +"%Y-%m-%d")
  
  # Get file counts by type
  doc_count=$(find . -type f -name "*.md" | wc -l)
  script_count=$(find . -type f -name "*.sh" | wc -l)
  config_count=$(find . -type f -name "*.json" | wc -l)
  
  # Get most recently modified files
  recent_files=$(find . -type f -not -path "*/\.*" -mtime -1 | wc -l)
  
  echo "Files: $file_count"
  echo "Directories: $dir_count"
  echo "Documentation files: $doc_count"
  echo "Script files: $script_count"
  echo "Configuration files: $config_count"
  echo "Files modified in last 24 hours: $recent_files"
  echo "Total size: ${total_size_kb}KB"
  echo "Last update: $current_date"
}

# Function to generate a health report
generate_health_report() {
  echo "Generating health report..."
  
  # Create report file
  report_file="./logs/health_report_$(date +"%Y%m%d").txt"
  
  {
    echo "========================================"
    echo "LIFEFORM-2 HEALTH REPORT"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""
    
    echo "SYSTEM METRICS:"
    update_metrics
    echo ""
    
    echo "RECENT CHANGES:"
    check_changes
    echo ""
    
    echo "FILE INTEGRITY CHECK:"
    # Check if critical files exist
    critical_files=("./run.sh" "./core/system/monitor.sh" "./docs/GOALS.md" "./docs/SYSTEM.md" "./docs/TASKS.md")
    for file in "${critical_files[@]}"; do
      if [ -f "$file" ]; then
        echo "✓ $file exists"
      else
        echo "✗ $file MISSING!"
      fi
    done
    echo ""
    
    echo "SYSTEM STATUS: OPERATIONAL"
    echo "========================================"
  } > "$report_file"
  
  echo "Health report generated at $report_file"
}

# Main execution
case "$1" in
  "sizes")
    monitor_file_sizes
    ;;
  "metrics")
    update_metrics
    ;;
  "changes")
    check_changes
    ;;
  "health")
    generate_health_report
    ;;
  *)
    echo "Usage: $0 {sizes|metrics|changes|health}"
    echo "  sizes   - Display sizes of all files"
    echo "  metrics - Update system metrics"
    echo "  changes - Check for file changes since last run"
    echo "  health  - Generate comprehensive health report"
    exit 1
    ;;
esac

exit 0