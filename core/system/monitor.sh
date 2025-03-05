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

# Function to update system metrics in SYSTEM.md
update_metrics() {
  echo "Updating system metrics..."
  
  # Get file count
  file_count=$(find . -type f -not -path "*/\.*" | wc -l)
  
  # Get total size
  total_size=$(find . -type f -not -path "*/\.*" -exec wc -c {} \; | awk '{total += $1} END {print total}')
  
  # Format size to KB
  total_size_kb=$(echo "scale=1; $total_size/1024" | bc)
  
  # Get current date
  current_date=$(date +"%Y-%m-%d")
  
  echo "Files: $file_count"
  echo "Total size: ${total_size_kb}KB"
  echo "Last update: $current_date"
}

# Main execution
case "$1" in
  "sizes")
    monitor_file_sizes
    ;;
  "metrics")
    update_metrics
    ;;
  *)
    echo "Usage: $0 {sizes|metrics}"
    echo "  sizes   - Display sizes of all files"
    echo "  metrics - Update system metrics"
    exit 1
    ;;
esac

exit 0