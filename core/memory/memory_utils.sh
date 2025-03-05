#!/bin/bash
# Memory utility functions for the lifeform project
# Handles reading and writing to memory storage

# Memory file location
MEMORY_FILE="memory.json"

# Function to initialize memory file if it doesn't exist
initialize_memory() {
  if [[ ! -f "$MEMORY_FILE" ]]; then
    echo "Initializing memory file..."
    cat > "$MEMORY_FILE" << EOF
{
  "metadata": {
    "version": "0.2",
    "created": "$(date +"%Y-%m-%d")",
    "last_updated": "$(date +"%Y-%m-%d")"
  },
  "sessions": [],
  "knowledge": {},
  "tasks": {},
  "health": {
    "last_check": "$(date +"%Y-%m-%d")",
    "status": "OPERATIONAL",
    "metrics": {
      "file_count": 0,
      "directory_count": 0,
      "total_size_kb": 0,
      "doc_files": 0,
      "script_files": 0,
      "config_files": 0
    },
    "checks": {
      "critical_files": true,
      "recent_changes": 0
    }
  }
}
EOF
    echo "Memory file initialized."
  fi
}

# Function to store a key-value pair in memory
set_memory() {
  if [[ $# -lt 3 ]]; then
    echo "Usage: $0 set [SECTION] [KEY] [VALUE]"
    return 1
  fi
  
  section=$1
  key=$2
  value=$3
  
  initialize_memory
  
  # Update the memory file
  # Note: This is a simple implementation that doesn't handle complex JSON operations
  # For a production system, consider using jq or another JSON processor
  
  # For now, we'll just append to the knowledge section as a basic demonstration
  if [[ "$section" == "knowledge" ]]; then
    # Create a temporary file with the updated content
    tmp_file=$(mktemp)
    
    # Read the file line by line and update the knowledge section
    inside_knowledge=0
    while IFS= read -r line; do
      if [[ "$line" =~ "\"knowledge\":" ]]; then
        inside_knowledge=1
        echo "$line" >> "$tmp_file"
        echo "    \"$key\": \"$value\"," >> "$tmp_file"
        continue
      fi
      
      if [[ $inside_knowledge -eq 1 && "$line" =~ "}" ]]; then
        inside_knowledge=0
      fi
      
      echo "$line" >> "$tmp_file"
    done < "$MEMORY_FILE"
    
    # Replace the original file with the updated one
    mv "$tmp_file" "$MEMORY_FILE"
    
    echo "Memory updated: $key = $value in section $section"
  else
    echo "Section $section not implemented yet"
  fi
}

# Function to retrieve a value from memory
get_memory() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 get [SECTION] [KEY]"
    return 1
  fi
  
  section=$1
  key=$2
  
  if [[ ! -f "$MEMORY_FILE" ]]; then
    echo "Memory file not found!"
    return 1
  fi
  
  # This is a very basic implementation
  # For a production system, use jq or a proper JSON parser
  if [[ "$section" == "knowledge" ]]; then
    value=$(grep -o "\"$key\": \"[^\"]*\"" "$MEMORY_FILE" | cut -d'"' -f4)
    if [[ -n "$value" ]]; then
      echo "$value"
    else
      echo "Key '$key' not found in section '$section'"
    fi
  else
    echo "Section $section not implemented yet"
  fi
}

# Function to log a session
log_session() {
  initialize_memory
  
  # Update last_updated in metadata
  sed -i '' "s/\"last_updated\": \"[^\"]*\"/\"last_updated\": \"$(date +"%Y-%m-%d")\"/" "$MEMORY_FILE"
  
  # Add session entry
  # This is a simplified implementation - a proper solution would use jq
  echo "Session logged: $(date +"%Y-%m-%d %H:%M:%S")"
}

# Function to update health status in memory
update_health() {
  initialize_memory
  
  # Get current metrics
  file_count=$(find . -type f -not -path "*/\.*" | wc -l)
  dir_count=$(find . -type d -not -path "*/\.*" | wc -l)
  total_size=$(find . -type f -not -path "*/\.*" -exec wc -c {} \; | awk '{total += $1} END {print total}')
  total_size_kb=$(echo "scale=1; $total_size/1024" | bc)
  doc_count=$(find . -type f -name "*.md" | wc -l)
  script_count=$(find . -type f -name "*.sh" | wc -l)
  config_count=$(find . -type f -name "*.json" | wc -l)
  recent_files=$(find . -type f -not -path "*/\.*" -mtime -1 | wc -l)
  
  # Check critical files
  critical_files=("./run.sh" "./core/system/monitor.sh" "./docs/GOALS.md" "./docs/SYSTEM.md" "./docs/TASKS.md")
  critical_files_status="true"
  for file in "${critical_files[@]}"; do
    if [ ! -f "$file" ]; then
      critical_files_status="false"
      break
    fi
  done
  
  # Create a temporary file to store the updated JSON
  # In a production system, use jq for more robust JSON manipulation
  tmp_file=$(mktemp)
  
  # This is a very basic way to update the JSON structure
  # A real implementation would use jq or similar tools
  cat > "$tmp_file" << EOF
{
  "metadata": {
    "version": "0.2",
    "created": "$(grep -o '"created": "[^"]*"' "$MEMORY_FILE" | cut -d'"' -f4)",
    "last_updated": "$(date +"%Y-%m-%d")"
  },
  "sessions": [],
  "knowledge": {},
  "tasks": {},
  "health": {
    "last_check": "$(date +"%Y-%m-%d")",
    "status": "OPERATIONAL",
    "metrics": {
      "file_count": $file_count,
      "directory_count": $dir_count,
      "total_size_kb": $total_size_kb,
      "doc_files": $doc_count,
      "script_files": $script_count,
      "config_files": $config_count
    },
    "checks": {
      "critical_files": $critical_files_status,
      "recent_changes": $recent_files
    }
  }
}
EOF
  
  # Replace the original file with the updated one
  mv "$tmp_file" "$MEMORY_FILE"
  
  echo "Health status updated in memory."
}

# Main execution
case "$1" in
  "init")
    initialize_memory
    ;;
  "set")
    set_memory "$2" "$3" "$4"
    ;;
  "get")
    get_memory "$2" "$3"
    ;;
  "log")
    log_session
    ;;
  "health")
    update_health
    ;;
  *)
    echo "Usage: $0 {init|set|get|log|health}"
    echo "  init              - Initialize memory file"
    echo "  set [S] [K] [V]   - Set key K to value V in section S"
    echo "  get [S] [K]       - Get value of key K from section S"
    echo "  log               - Log a new session"
    echo "  health            - Update health metrics in memory"
    exit 1
    ;;
esac

exit 0