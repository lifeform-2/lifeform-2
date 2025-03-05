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
    "version": "0.1",
    "created": "$(date +"%Y-%m-%d")",
    "last_updated": "$(date +"%Y-%m-%d")"
  },
  "sessions": [],
  "knowledge": {},
  "tasks": {}
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
  *)
    echo "Usage: $0 {init|set|get|log}"
    echo "  init              - Initialize memory file"
    echo "  set [S] [K] [V]   - Set key K to value V in section S"
    echo "  get [S] [K]       - Get value of key K from section S"
    echo "  log               - Log a new session"
    exit 1
    ;;
esac

exit 0