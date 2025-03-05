#!/bin/bash
# Task queue implementation for the lifeform project
# Manages task creation, listing, and status updates

# Task file location
TASKS_FILE="../docs/TASKS.md"

# Function to list all tasks
list_tasks() {
  echo "Listing tasks..."
  if [[ -f "$TASKS_FILE" ]]; then
    grep -E "^T[0-9]+" "$TASKS_FILE"
  else
    echo "Tasks file not found!"
  fi
}

# Function to add a new task
add_task() {
  if [[ $# -lt 3 ]]; then
    echo "Usage: $0 add [PRIORITY] [DESCRIPTION]"
    echo "  PRIORITY can be: CRITICAL, HIGH, MEDIUM, LOW"
    return 1
  fi
  
  priority=$1
  description=$2
  
  # Validate priority
  if [[ ! "$priority" =~ ^(CRITICAL|HIGH|MEDIUM|LOW)$ ]]; then
    echo "Invalid priority. Must be one of: CRITICAL, HIGH, MEDIUM, LOW"
    return 1
  fi
  
  # Generate new task ID
  if [[ -f "$TASKS_FILE" ]]; then
    last_id=$(grep -E "^T[0-9]+" "$TASKS_FILE" | tail -n 1 | cut -d'-' -f1 | tr -d '[:space:]' | sed 's/^T//')
    if [[ -z "$last_id" ]]; then
      new_id=1
    else
      new_id=$((last_id + 1))
    fi
  else
    new_id=1
  fi
  
  # Format task ID with leading zeros
  task_id=$(printf "T%03d" $new_id)
  
  # Create task entry
  task_entry="$task_id - $priority - PENDING - $description"
  
  # Add to tasks file
  if [[ -f "$TASKS_FILE" ]]; then
    # Find the Active Tasks section and append
    sed -i '' "/^## Active Tasks/a\\
$task_entry\\
- Added on $(date +"%Y-%m-%d")\\
- Acceptance: TBD\\
" "$TASKS_FILE"
    echo "Task $task_id added."
  else
    echo "Tasks file not found!"
  fi
}

# Function to update task status
update_task() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 update [TASK_ID] [STATUS]"
    echo "  STATUS can be: PENDING, IN_PROGRESS, COMPLETED, BLOCKED"
    return 1
  fi
  
  task_id=$1
  status=$2
  
  # Validate status
  if [[ ! "$status" =~ ^(PENDING|IN_PROGRESS|COMPLETED|BLOCKED)$ ]]; then
    echo "Invalid status. Must be one of: PENDING, IN_PROGRESS, COMPLETED, BLOCKED"
    return 1
  fi
  
  # Update task in file
  if [[ -f "$TASKS_FILE" ]]; then
    # Find the task and update its status
    task_line=$(grep -n "^$task_id" "$TASKS_FILE" | cut -d':' -f1)
    if [[ -n "$task_line" ]]; then
      current_line=$(sed -n "${task_line}p" "$TASKS_FILE")
      updated_line=$(echo "$current_line" | sed -E "s/- [A-Z_]+ -/- $status -/")
      sed -i '' "${task_line}s/.*/$updated_line/" "$TASKS_FILE"
      echo "Task $task_id updated to $status."
    else
      echo "Task $task_id not found!"
    fi
  else
    echo "Tasks file not found!"
  fi
}

# Main execution
case "$1" in
  "list")
    list_tasks
    ;;
  "add")
    add_task "$2" "$3"
    ;;
  "update")
    update_task "$2" "$3"
    ;;
  *)
    echo "Usage: $0 {list|add|update}"
    echo "  list            - List all tasks"
    echo "  add [P] [DESC]  - Add a new task with priority P and description DESC"
    echo "  update [ID] [S] - Update task ID to status S"
    exit 1
    ;;
esac

exit 0