#!/bin/bash
# Documentation Summarization Script
# Automatically summarizes large documentation files

# Set up variables
DOCS_DIR="./docs"
MAX_SIZE_BYTES=8000  # Files larger than this will trigger summarization
ARCHIVE_DIR="./docs/archived"

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${GREEN}======= Documentation Summarization =======${NC}"
echo "Running on $(date +"%Y-%m-%d %H:%M:%S")"
echo ""

# Function to check if file needs summarization
needs_summarization() {
  local file="$1"
  local size=$(stat -f "%z" "$file")
  
  if [ "$size" -gt "$MAX_SIZE_BYTES" ]; then
    return 0 # True, needs summarization
  else
    return 1 # False, doesn't need summarization
  fi
}

# Function to archive sections of documents
archive_sections() {
  local file="$1"
  local basename=$(basename "$file")
  local date=$(date +"%Y%m%d")
  local archive_file="${ARCHIVE_DIR}/${basename%.md}_${date}.md"
  
  echo -e "${YELLOW}Archiving older content from $basename to $(basename "$archive_file")${NC}"
  
  # Handle specific files differently
  case "$basename" in
    "TASKS.md")
      # Extract completed tasks section and archive it
      echo "# Archived Tasks ($(date +"%Y-%m-%d"))" > "$archive_file"
      echo "" >> "$archive_file"
      sed -n '/^## Completed Tasks/,/^## /p' "$file" | sed '$d' >> "$archive_file"
      echo "" >> "$archive_file"
      
      # Also add the "Archived Tasks" section if it exists
      if grep -q "^## Archived Tasks" "$file"; then
        sed -n '/^## Archived Tasks/,/^## /p' "$file" | sed '$d' >> "$archive_file"
      fi
      ;;
      
    "COMMUNICATION.md")
      # Archive older conversations but keep summary and recent messages
      echo "# Archived Communication ($(date +"%Y-%m-%d"))" > "$archive_file"
      echo "" >> "$archive_file"
      
      # Keep the 5 most recent exchanges, archive the rest
      # First, identify the section to archive
      total_messages=$(grep -c "^\*\*Creator" "$file")
      if [ "$total_messages" -gt 5 ]; then
        # Calculate how many messages to archive
        to_archive=$((total_messages - 5))
        
        # Find the line number of the last message to archive
        last_to_archive=$(grep -n "^\*\*Creator" "$file" | head -n "$to_archive" | tail -1 | cut -d: -f1)
        next_to_keep=$((last_to_archive + 1))
        
        # Extract the section to archive
        sed -n '/^## Creator-Lifeform Chat/,'"$last_to_archive"'p' "$file" | tail -n +2 >> "$archive_file"
      fi
      ;;
      
    "CHANGELOG.md")
      # Archive older changes but keep recent ones
      echo "# Archived Changelog ($(date +"%Y-%m-%d"))" > "$archive_file"
      echo "" >> "$archive_file"
      
      # Extract older versions (keep the most recent 5 versions)
      versions=$(grep -n "^## v" "$file" | head -n -5 | cut -d: -f1)
      if [ -n "$versions" ]; then
        last_version=$(echo "$versions" | tail -1)
        next_version=$(grep -n "^## v" "$file" | grep -A 1 "$last_version" | tail -1 | cut -d: -f1)
        next_version=$((next_version - 1))
        
        # Extract section to archive
        sed -n '1,'"$next_version"'p' "$file" | tail -n +3 >> "$archive_file"
      fi
      ;;
      
    *)
      # Generic archive approach for other files
      echo "# Archived content from $basename ($(date +"%Y-%m-%d"))" > "$archive_file"
      echo "" >> "$archive_file"
      cat "$file" >> "$archive_file"
      ;;
  esac
  
  echo -e "${GREEN}✓ Archived content to $(basename "$archive_file")${NC}"
  return 0
}

# Function to summarize a document
summarize_document() {
  local file="$1"
  local basename=$(basename "$file")
  local temp_file="/tmp/${basename%.md}_summarized.md"
  
  echo -e "${YELLOW}Summarizing $basename...${NC}"
  
  # Archive old sections first
  archive_sections "$file"
  
  # Handle specific files differently
  case "$basename" in
    "TASKS.md")
      # Extract header, active tasks, and next actions
      {
        # Keep the header and format explanation
        sed -n '1,/^Status options:/p' "$file"
        echo ""
        
        # Keep Active Tasks section
        echo "## Active Tasks"
        echo ""
        sed -n '/^## Active Tasks/,/^## /p' "$file" | tail -n +3 | sed '$d'
        echo ""
        
        # Keep Next Actions section
        echo "## Next Actions"
        echo ""
        sed -n '/^## Next Actions/,/^## /p' "$file" | tail -n +3 | sed '$d'
        echo ""
        
        # Keep Planned Tasks section
        echo "## Planned Tasks"
        echo ""
        sed -n '/^## Planned Tasks/,/^## /p' "$file" | tail -n +3 | sed '$d'
        echo ""
        
        # Create a Recently Completed section with summarized completed tasks
        echo "## Recently Completed Tasks"
        echo ""
        sed -n '/^## Completed Tasks/,/^## /p' "$file" | tail -n +3 | sed '$d' | head -20
        echo ""
        
        # Reference the archived tasks
        echo "## Archived Tasks ($(date +"%Y-%m-%d"))"
        echo ""
        echo "A summary of completed tasks has been archived to maintain a cleaner task list. See archives for details."
        echo ""
      } > "$temp_file"
      ;;
      
    "COMMUNICATION.md")
      # Keep instructions, summary and recent conversations
      {
        # Keep instructions section
        sed -n '1,/^## Communication Summary/p' "$file" | head -n -1
        echo ""
        
        # Update and expand summary section
        echo "## Communication Summary"
        # Extract key points from conversations and append to summary
        grep -A 2 "^- " "$file" | sed -n '/^-/p'
        # Add date to show when summary was last updated
        echo "- Summary last updated: $(date +"%Y-%m-%d")"
        echo ""
        
        # Keep the conversation section header and recent exchanges
        echo "## Creator-Lifeform Chat"
        echo ""
        
        # Find the last 5 exchanges
        total_messages=$(grep -c "^\*\*Creator" "$file")
        if [ "$total_messages" -gt 5 ]; then
          to_keep=5
          start_line=$(grep -n "^\*\*Creator" "$file" | tail -n "$to_keep" | head -1 | cut -d: -f1)
          sed -n "$start_line,\$p" "$file"
        else
          # If 5 or fewer messages, keep all of them
          sed -n '/^## Creator-Lifeform Chat/,\$p' "$file" | tail -n +3
        fi
      } > "$temp_file"
      ;;
      
    "CHANGELOG.md")
      # Keep recent changelog entries
      {
        # Keep the header
        sed -n '1,2p' "$file"
        echo ""
        
        # Find version entries
        version_count=$(grep -c "^## v" "$file")
        if [ "$version_count" -gt 0 ]; then
          if [ "$version_count" -gt 5 ]; then
            # If more than 5 versions, keep most recent 5
            start_line=$(grep -n "^## v" "$file" | tail -5 | head -1 | cut -d: -f1)
            sed -n "$start_line,\$p" "$file"
          else
            # If 5 or fewer versions, keep all versions
            grep -A 100 "^## v" "$file"
          fi
          
          # Add note about archived entries
          echo ""
          echo "## Archived Entries"
          echo ""
          echo "Earlier changelog entries have been archived to maintain a cleaner file."
          echo "See the archived changelog files for historical changes."
        else
          # No version entries found, just keep the file as is
          cat "$file"
        fi
      } > "$temp_file"
      ;;
      
    *)
      # Generic summarization for other files
      echo "Generic summarization not implemented for $basename"
      return 1
      ;;
  esac
  
  # Replace the original file with the summarized version
  mv "$temp_file" "$file"
  echo -e "${GREEN}✓ Successfully summarized $basename${NC}"
  return 0
}

# Main execution
# Check each documentation file
for file in "$DOCS_DIR"/*.md; do
  basename=$(basename "$file")
  
  # Skip CLAUDE.md and certain system files
  if [[ "$basename" == "CLAUDE.md" || "$basename" == "README.md" || "$basename" == "original_files" ]]; then
    continue
  fi
  
  echo -e "${GREEN}Checking $basename${NC}"
  
  # Check if file needs summarization
  if needs_summarization "$file"; then
    echo -e "${YELLOW}  ⚠️  File is large ($(stat -f "%z" "$file") bytes) and will be summarized${NC}"
    summarize_document "$file"
  else
    echo -e "${GREEN}  ✓ File size is acceptable ($(stat -f "%z" "$file") bytes)${NC}"
  fi
done

echo ""
echo -e "${GREEN}======= Documentation Summarization Complete =======${NC}"
exit 0