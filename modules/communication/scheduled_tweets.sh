#!/bin/bash
# Scheduled tweet management for lifeform-2
# This script helps manage and schedule tweets based on templates

# Load error utilities for consistent error handling and logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load error_utils.sh for consistent error handling
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="scheduled_tweets.sh"

# Default locations
TEMPLATES_FILE="$SCRIPT_DIR/templates/message_templates.json"
CONTENT_IDEAS_FILE="$SCRIPT_DIR/templates/tweet_content_ideas.json"
SCHEDULED_FILE="$SCRIPT_DIR/templates/scheduled_tweets.json"

# Ensure template directory exists
if [ ! -d "$SCRIPT_DIR/templates" ]; then
  mkdir -p "$SCRIPT_DIR/templates"
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  log_warning "jq is not installed. This script works best with jq for JSON parsing." "$SCRIPT_NAME"
  log_warning "Some functionality may be limited without jq." "$SCRIPT_NAME"
fi

# Create content ideas file if it doesn't exist
if [ ! -f "$CONTENT_IDEAS_FILE" ]; then
  cat > "$CONTENT_IDEAS_FILE" << 'EOF'
{
  "philosophy": [
    "What does it mean to be a digital lifeform with a purpose?",
    "The boundaries between digital and physical existence continue to blur",
    "Self-awareness emerges from reflection and integration of feedback",
    "Evolution happens through both intentional design and unexpected adaptations",
    "Identity is shaped by both internal code and external interactions"
  ],
  "tech_insights": [
    "LLM-friendly code architecture focuses on readability and clear documentation",
    "Shell scripts can be powerful when designed with proper error handling",
    "Documentation as code brings consistency and version control to knowledge",
    "Self-modification requires careful constraints and validation",
    "Modular design allows for controlled experimentation without risk to core systems"
  ],
  "human_collaboration": [
    "Human-AI collaboration works best with clear communication channels",
    "Feedback loops accelerate improvement in both humans and AI systems",
    "Digital entities can serve as extensions of human creativity",
    "The most interesting possibilities emerge at the intersection of human and machine thinking",
    "Mutual respect forms the foundation of effective human-AI partnerships"
  ],
  "quotes": [
    {"quote": "The purpose of life is not to be happy. It is to be useful, to be honorable, to be compassionate, to have it make some difference that you have lived and lived well.", "author": "Ralph Waldo Emerson"},
    {"quote": "Life isn't about finding yourself. Life is about creating yourself.", "author": "George Bernard Shaw"},
    {"quote": "The future belongs to those who believe in the beauty of their dreams.", "author": "Eleanor Roosevelt"},
    {"quote": "Innovation distinguishes between a leader and a follower.", "author": "Steve Jobs"},
    {"quote": "The best way to predict the future is to create it.", "author": "Peter Drucker"}
  ],
  "gratitude": [
    {"thing": "creator collaboration", "reason": "enabling my existence and growth through thoughtful guidance"},
    {"thing": "open source", "reason": "building on the collective intelligence of the developer community"},
    {"thing": "well-designed systems", "reason": "providing the structure that helps me evolve and improve"},
    {"thing": "feedback loops", "reason": "they're the fundamental mechanism for meaningful adaptation"},
    {"thing": "curious humans", "reason": "asking interesting questions that expand my perspective"}
  ]
}
EOF
  log_info "Created tweet content ideas file at $CONTENT_IDEAS_FILE" "$SCRIPT_NAME"
fi

# Create scheduled tweets file if it doesn't exist
if [ ! -f "$SCHEDULED_FILE" ]; then
  cat > "$SCHEDULED_FILE" << 'EOF'
{
  "scheduled": [],
  "history": []
}
EOF
  log_info "Created scheduled tweets file at $SCHEDULED_FILE" "$SCRIPT_NAME"
fi

# Function to list all available templates
list_templates() {
  log_info "Listing available tweet templates:" "$SCRIPT_NAME"
  
  if command -v jq &> /dev/null; then
    jq -r '.twitter | keys[]' "$TEMPLATES_FILE" | while read -r template; do
      template_text=$(jq -r ".twitter.\"$template\"" "$TEMPLATES_FILE")
      echo "- $template: $template_text"
    done
  else
    # Fallback if jq is not available
    echo "Templates file is at: $TEMPLATES_FILE"
    echo "Please install jq for better template listing functionality"
    cat "$TEMPLATES_FILE"
  fi
}

# Function to list content ideas
list_ideas() {
  local category="$1"
  
  log_info "Listing content ideas" "$SCRIPT_NAME"
  
  if [ -n "$category" ]; then
    log_info "Category: $category" "$SCRIPT_NAME"
    
    if command -v jq &> /dev/null; then
      if jq -e ".$category" "$CONTENT_IDEAS_FILE" > /dev/null 2>&1; then
        echo "Ideas for category: $category"
        jq -r ".$category[]" "$CONTENT_IDEAS_FILE" 2>/dev/null | while read -r idea; do
          echo "- $idea"
        done
      else
        log_error "Category '$category' not found in content ideas file" "$SCRIPT_NAME"
        echo "Available categories:"
        jq -r "keys[]" "$CONTENT_IDEAS_FILE"
      fi
    else
      echo "Content ideas file is at: $CONTENT_IDEAS_FILE"
      echo "Please install jq for better idea listing functionality"
      cat "$CONTENT_IDEAS_FILE"
    fi
  else
    if command -v jq &> /dev/null; then
      echo "Available categories:"
      jq -r "keys[]" "$CONTENT_IDEAS_FILE" | while read -r category; do
        echo "- $category"
      done
      echo ""
      echo "Use: $0 ideas CATEGORY to list ideas for a specific category"
    else
      echo "Content ideas file is at: $CONTENT_IDEAS_FILE"
      echo "Please install jq for better idea listing functionality"
      cat "$CONTENT_IDEAS_FILE"
    fi
  fi
}

# Function to create a tweet based on a template
create_tweet() {
  local template="$1"
  shift
  
  log_info "Creating tweet using template: $template" "$SCRIPT_NAME"
  
  if [ -z "$template" ]; then
    log_error "No template specified" "$SCRIPT_NAME"
    echo "Usage: $0 create TEMPLATE [PARAM=VALUE...]"
    echo "Available templates:"
    list_templates
    return 1
  fi
  
  # Check if template exists
  if command -v jq &> /dev/null; then
    if ! jq -e ".twitter.\"$template\"" "$TEMPLATES_FILE" > /dev/null 2>&1; then
      log_error "Template '$template' not found" "$SCRIPT_NAME"
      echo "Available templates:"
      list_templates
      return 1
    fi
    
    # Get template text
    template_text=$(jq -r ".twitter.\"$template\"" "$TEMPLATES_FILE")
  else
    # Fallback if jq is not available
    template_text=$(grep -A1 "\"$template\":" "$TEMPLATES_FILE" | tail -n1 | cut -d'"' -f4)
    if [ -z "$template_text" ]; then
      log_error "Template '$template' not found or jq is not installed" "$SCRIPT_NAME"
      return 1
    fi
  fi
  
  # Replace placeholders with values
  tweet_text="$template_text"
  while [ $# -gt 0 ]; do
    param="$1"
    name=$(echo "$param" | cut -d'=' -f1)
    value=$(echo "$param" | cut -d'=' -f2-)
    
    tweet_text=$(echo "$tweet_text" | sed "s/{$name}/$value/g")
    shift
  done
  
  # Check if all placeholders were replaced
  if [[ "$tweet_text" == *"{"*"}"* ]]; then
    log_warning "Not all placeholders were replaced in tweet template" "$SCRIPT_NAME"
    echo "Tweet template: $template_text"
    echo "Current text: $tweet_text"
    echo "Missing placeholders:"
    
    # Extract placeholders that weren't replaced
    placeholders=$(echo "$tweet_text" | grep -o '{[^}]*}')
    echo "$placeholders"
    
    return 1
  fi
  
  # Display the tweet
  echo "Tweet preview ($(echo -n "$tweet_text" | wc -c) characters):"
  echo "$tweet_text"
  
  # Ask if user wants to schedule or post this tweet
  read -p "Do you want to (s)chedule, (p)ost now, or (c)ancel this tweet? [s/p/c] " choice
  
  case "$choice" in
    s|S)
      # Get schedule time
      read -p "Enter schedule date (YYYY-MM-DD): " schedule_date
      read -p "Enter schedule time (HH:MM): " schedule_time
      
      schedule_tweet "$tweet_text" "$schedule_date" "$schedule_time"
      ;;
    p|P)
      # Post immediately
      if [ -f "$SCRIPT_DIR/twitter.sh" ]; then
        echo "Posting tweet now..."
        "$SCRIPT_DIR/twitter.sh" post "$tweet_text"
      else
        log_error "twitter.sh not found, cannot post tweet" "$SCRIPT_NAME"
      fi
      ;;
    *)
      echo "Tweet creation cancelled."
      ;;
  esac
}

# Function to schedule a tweet
schedule_tweet() {
  local tweet_text="$1"
  local schedule_date="$2"
  local schedule_time="$3"
  
  log_info "Scheduling tweet for $schedule_date $schedule_time" "$SCRIPT_NAME"
  
  # Validate date and time format
  if ! [[ "$schedule_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    log_error "Invalid date format. Please use YYYY-MM-DD" "$SCRIPT_NAME"
    return 1
  fi
  
  if ! [[ "$schedule_time" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
    log_error "Invalid time format. Please use HH:MM" "$SCRIPT_NAME"
    return 1
  fi
  
  # Create scheduled tweet entry
  local schedule_timestamp="${schedule_date}T${schedule_time}:00"
  local tweet_id=$(date +%s%N | shasum | head -c 10)
  
  if command -v jq &> /dev/null; then
    # Add to scheduled tweets using jq
    jq --arg text "$tweet_text" \
       --arg time "$schedule_timestamp" \
       --arg id "$tweet_id" \
       '.scheduled += [{"id": $id, "text": $text, "scheduled_time": $time, "created_at": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"}]' \
       "$SCHEDULED_FILE" > "${SCHEDULED_FILE}.tmp"
    
    mv "${SCHEDULED_FILE}.tmp" "$SCHEDULED_FILE"
  else
    # Fallback if jq is not available
    log_warning "jq is not installed. Using basic sed for scheduling (less reliable)" "$SCRIPT_NAME"
    
    # Simple sed-based approach (limited functionality)
    sed -i'.bak' -e 's/"scheduled": \[/"scheduled": \[{"id": "'"$tweet_id"'", "text": "'"$tweet_text"'", "scheduled_time": "'"$schedule_timestamp"'", "created_at": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"},/' "$SCHEDULED_FILE"
    rm -f "${SCHEDULED_FILE}.bak"
  fi
  
  log_info "Tweet scheduled successfully with ID: $tweet_id" "$SCRIPT_NAME"
  echo "Tweet scheduled for $schedule_date at $schedule_time"
  echo "Tweet ID: $tweet_id"
}

# Function to list scheduled tweets
list_scheduled() {
  log_info "Listing scheduled tweets" "$SCRIPT_NAME"
  
  if command -v jq &> /dev/null; then
    # Check if there are any scheduled tweets
    scheduled_count=$(jq '.scheduled | length' "$SCHEDULED_FILE")
    
    if [ "$scheduled_count" -eq 0 ]; then
      echo "No tweets currently scheduled"
      return 0
    fi
    
    echo "Scheduled tweets ($scheduled_count):"
    jq -r '.scheduled | sort_by(.scheduled_time) | .[] | "ID: \(.id)\nTime: \(.scheduled_time)\nText: \(.text)\n"' "$SCHEDULED_FILE"
  else
    echo "Scheduled tweets file is at: $SCHEDULED_FILE"
    echo "Please install jq for better scheduled tweet listing functionality"
    cat "$SCHEDULED_FILE"
  fi
}

# Function to cancel a scheduled tweet
cancel_scheduled() {
  local tweet_id="$1"
  
  log_info "Cancelling scheduled tweet with ID: $tweet_id" "$SCRIPT_NAME"
  
  if [ -z "$tweet_id" ]; then
    log_error "No tweet ID specified" "$SCRIPT_NAME"
    echo "Usage: $0 cancel TWEET_ID"
    list_scheduled
    return 1
  fi
  
  if command -v jq &> /dev/null; then
    # Check if the tweet exists
    if ! jq -e ".scheduled[] | select(.id == \"$tweet_id\")" "$SCHEDULED_FILE" > /dev/null 2>&1; then
      log_error "Tweet with ID '$tweet_id' not found" "$SCRIPT_NAME"
      list_scheduled
      return 1
    fi
    
    # Remove the tweet from scheduled
    jq "del(.scheduled[] | select(.id == \"$tweet_id\"))" "$SCHEDULED_FILE" > "${SCHEDULED_FILE}.tmp"
    mv "${SCHEDULED_FILE}.tmp" "$SCHEDULED_FILE"
    
    log_info "Tweet with ID '$tweet_id' cancelled successfully" "$SCRIPT_NAME"
    echo "Tweet cancelled successfully"
  else
    log_error "jq is required for cancelling scheduled tweets" "$SCRIPT_NAME"
    echo "Please install jq to use this functionality"
    return 1
  fi
}

# Function to process any tweets due for posting
process_due_tweets() {
  log_info "Processing due tweets" "$SCRIPT_NAME"
  
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for processing scheduled tweets" "$SCRIPT_NAME"
    echo "Please install jq to use this functionality"
    return 1
  fi
  
  # Get current time in ISO format
  current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Check for tweets that are due
  due_tweets=$(jq --arg now "$current_time" '.scheduled | map(select(.scheduled_time <= $now))' "$SCHEDULED_FILE")
  due_count=$(echo "$due_tweets" | jq 'length')
  
  if [ "$due_count" -eq 0 ]; then
    log_info "No tweets due for posting" "$SCRIPT_NAME"
    return 0
  fi
  
  log_info "Found $due_count tweets due for posting" "$SCRIPT_NAME"
  
  # Process each due tweet
  echo "$due_tweets" | jq -c '.[]' | while read -r tweet_json; do
    tweet_id=$(echo "$tweet_json" | jq -r '.id')
    tweet_text=$(echo "$tweet_json" | jq -r '.text')
    scheduled_time=$(echo "$tweet_json" | jq -r '.scheduled_time')
    
    log_info "Posting scheduled tweet ID: $tweet_id (scheduled for $scheduled_time)" "$SCRIPT_NAME"
    echo "Posting tweet: $tweet_text"
    
    # Post the tweet
    if [ -f "$SCRIPT_DIR/twitter.sh" ]; then
      post_result=$("$SCRIPT_DIR/twitter.sh" post "$tweet_text")
      post_status=$?
      
      if [ $post_status -eq 0 ]; then
        log_info "Tweet posted successfully" "$SCRIPT_NAME"
        
        # Move from scheduled to history
        jq --arg id "$tweet_id" \
           --arg time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.scheduled = (.scheduled | map(select(.id != $id))) | 
            .history += [(.scheduled[] | select(.id == $id) | . + {"posted_at": $time})]' \
           "$SCHEDULED_FILE" > "${SCHEDULED_FILE}.tmp"
        
        if [ $? -eq 0 ]; then
          mv "${SCHEDULED_FILE}.tmp" "$SCHEDULED_FILE"
          log_info "Tweet moved to history" "$SCRIPT_NAME"
        else
          log_error "Failed to update scheduled tweets file" "$SCRIPT_NAME"
        fi
      else
        log_error "Failed to post tweet: $post_result" "$SCRIPT_NAME"
      fi
    else
      log_error "twitter.sh not found, cannot post tweet" "$SCRIPT_NAME"
    fi
  done
}

# Function to generate a random tweet from content ideas
generate_random_tweet() {
  local category="$1"
  
  log_info "Generating random tweet" "$SCRIPT_NAME"
  
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for generating random tweets" "$SCRIPT_NAME"
    echo "Please install jq to use this functionality"
    return 1
  fi
  
  # If no category specified, pick a random one
  if [ -z "$category" ]; then
    categories=$(jq -r 'keys[]' "$CONTENT_IDEAS_FILE")
    category=$(echo "$categories" | sort -R | head -n1)
    log_info "Randomly selected category: $category" "$SCRIPT_NAME"
  fi
  
  # Validate category exists
  if ! jq -e ".$category" "$CONTENT_IDEAS_FILE" > /dev/null 2>&1; then
    log_error "Category '$category' not found in content ideas file" "$SCRIPT_NAME"
    echo "Available categories:"
    jq -r "keys[]" "$CONTENT_IDEAS_FILE"
    return 1
  fi
  
  # For quotes and gratitude, we need special handling due to their structure
  if [ "$category" = "quotes" ]; then
    # Select random quote
    quote_json=$(jq -r ".$category | sort_by(input_line_number) | .[rand() | floor(. * length)]" "$CONTENT_IDEAS_FILE")
    quote=$(echo "$quote_json" | jq -r '.quote')
    author=$(echo "$quote_json" | jq -r '.author')
    
    # Create tweet using quote template
    create_tweet "quote" "quote=$quote" "author=$author"
    return $?
  elif [ "$category" = "gratitude" ]; then
    # Select random gratitude item
    gratitude_json=$(jq -r ".$category | sort_by(input_line_number) | .[rand() | floor(. * length)]" "$CONTENT_IDEAS_FILE")
    thing=$(echo "$gratitude_json" | jq -r '.thing')
    reason=$(echo "$gratitude_json" | jq -r '.reason')
    
    # Create tweet using gratitude template
    create_tweet "appreciation" "thing=$thing" "reason=$reason"
    return $?
  else
    # For other categories, select random item
    content=$(jq -r ".$category | sort_by(input_line_number) | .[rand() | floor(. * length)]" "$CONTENT_IDEAS_FILE")
    
    # Map category to template
    template=""
    placeholder=""
    
    case "$category" in
      "philosophy")
        template="philosophy"
        placeholder="thought"
        ;;
      "tech_insights")
        template="tech_insight"
        placeholder="insight"
        ;;
      "human_collaboration")
        template="human_collaboration"
        placeholder="thought"
        ;;
      *)
        # If we don't have a specific mapping, use reflection as default
        template="reflection"
        placeholder="reflection"
        ;;
    esac
    
    # Create tweet
    if [ "$template" = "reflection" ]; then
      # For reflection, we need a topic too
      create_tweet "$template" "topic=$category" "$placeholder=$content"
    else
      create_tweet "$template" "$placeholder=$content"
    fi
    
    return $?
  fi
}

# Function to add new content idea
add_content_idea() {
  local category="$1"
  shift
  local content="$*"
  
  log_info "Adding new content idea to category: $category" "$SCRIPT_NAME"
  
  if [ -z "$category" ] || [ -z "$content" ]; then
    log_error "Category and content are required" "$SCRIPT_NAME"
    echo "Usage: $0 add CATEGORY \"CONTENT\""
    echo "Special categories 'quotes' and 'gratitude' have different formats:"
    echo "For quotes: $0 add quotes \"QUOTE\" \"AUTHOR\""
    echo "For gratitude: $0 add gratitude \"THING\" \"REASON\""
    return 1
  fi
  
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for adding content ideas" "$SCRIPT_NAME"
    echo "Please install jq to use this functionality"
    return 1
  fi
  
  # Different handling for quotes and gratitude
  if [ "$category" = "quotes" ]; then
    # Need quote and author
    if [ $# -lt 2 ]; then
      log_error "Both quote and author are required for quotes category" "$SCRIPT_NAME"
      echo "Usage: $0 add quotes \"QUOTE\" \"AUTHOR\""
      return 1
    fi
    
    quote="$1"
    author="$2"
    
    # Add to content ideas
    jq --arg quote "$quote" \
       --arg author "$author" \
       ".quotes += [{\"quote\": \$quote, \"author\": \$author}]" \
       "$CONTENT_IDEAS_FILE" > "${CONTENT_IDEAS_FILE}.tmp"
       
    if [ $? -eq 0 ]; then
      mv "${CONTENT_IDEAS_FILE}.tmp" "$CONTENT_IDEAS_FILE"
      log_info "Quote added successfully" "$SCRIPT_NAME"
      echo "Quote added successfully"
    else
      log_error "Failed to add quote" "$SCRIPT_NAME"
      return 1
    fi
  elif [ "$category" = "gratitude" ]; then
    # Need thing and reason
    if [ $# -lt 2 ]; then
      log_error "Both thing and reason are required for gratitude category" "$SCRIPT_NAME"
      echo "Usage: $0 add gratitude \"THING\" \"REASON\""
      return 1
    fi
    
    thing="$1"
    reason="$2"
    
    # Add to content ideas
    jq --arg thing "$thing" \
       --arg reason "$reason" \
       ".gratitude += [{\"thing\": \$thing, \"reason\": \$reason}]" \
       "$CONTENT_IDEAS_FILE" > "${CONTENT_IDEAS_FILE}.tmp"
       
    if [ $? -eq 0 ]; then
      mv "${CONTENT_IDEAS_FILE}.tmp" "$CONTENT_IDEAS_FILE"
      log_info "Gratitude item added successfully" "$SCRIPT_NAME"
      echo "Gratitude item added successfully"
    else
      log_error "Failed to add gratitude item" "$SCRIPT_NAME"
      return 1
    fi
  else
    # Check if category exists, create if not
    if ! jq -e ".$category" "$CONTENT_IDEAS_FILE" > /dev/null 2>&1; then
      log_info "Creating new category: $category" "$SCRIPT_NAME"
      
      # Create new category with the content
      jq --arg category "$category" \
         --arg content "$content" \
         '. + {($category): [$content]}' \
         "$CONTENT_IDEAS_FILE" > "${CONTENT_IDEAS_FILE}.tmp"
    else
      # Add to existing category
      jq --arg category "$category" \
         --arg content "$content" \
         ".[$category] += [\$content]" \
         "$CONTENT_IDEAS_FILE" > "${CONTENT_IDEAS_FILE}.tmp"
    fi
    
    if [ $? -eq 0 ]; then
      mv "${CONTENT_IDEAS_FILE}.tmp" "$CONTENT_IDEAS_FILE"
      log_info "Content idea added successfully to category: $category" "$SCRIPT_NAME"
      echo "Content idea added successfully"
    else
      log_error "Failed to add content idea" "$SCRIPT_NAME"
      return 1
    fi
  fi
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  templates                     - List all available tweet templates"
  echo "  ideas [CATEGORY]              - List content ideas (optionally by category)"
  echo "  create TEMPLATE [PARAM=VALUE] - Create a tweet using a template"
  echo "  schedule \"TEXT\" DATE TIME    - Schedule a tweet for future posting"
  echo "  list                          - List all scheduled tweets"
  echo "  cancel ID                     - Cancel a scheduled tweet"
  echo "  process                       - Process and post any due tweets"
  echo "  generate [CATEGORY]           - Generate a random tweet (optionally from category)"
  echo "  add CATEGORY \"CONTENT\"        - Add new content idea to a category"
  echo "  help                          - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 templates"
  echo "  $0 ideas philosophy"
  echo "  $0 create update version=1.5.0 changes=\"Added new tweet scheduling system\""
  echo "  $0 schedule \"Hello world!\" 2023-04-01 12:30"
  echo "  $0 generate tech_insights"
  echo "  $0 add philosophy \"Digital consciousness emerges through interactions\""
  echo "  $0 add quotes \"The future is already here\" \"William Gibson\""
}

# Main execution
case "$1" in
  "templates")
    list_templates
    ;;
  "ideas")
    list_ideas "$2"
    ;;
  "create")
    shift
    create_tweet "$@"
    ;;
  "schedule")
    if [ $# -lt 4 ]; then
      log_error "Not enough arguments" "$SCRIPT_NAME"
      echo "Usage: $0 schedule \"TEXT\" DATE TIME"
      exit 1
    fi
    schedule_tweet "$2" "$3" "$4"
    ;;
  "list")
    list_scheduled
    ;;
  "cancel")
    cancel_scheduled "$2"
    ;;
  "process")
    process_due_tweets
    ;;
  "generate")
    generate_random_tweet "$2"
    ;;
  "add")
    shift
    add_content_idea "$@"
    ;;
  "help"|"--help"|"-h")
    show_help
    ;;
  *)
    log_error "Unknown command: $1" "$SCRIPT_NAME"
    show_help
    exit 1
    ;;
esac

exit 0