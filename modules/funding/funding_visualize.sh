#!/bin/bash
# Funding visualization script for lifeform-2
# This script provides visual reports and charts for donation data

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="funding_visualize.sh"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show script header
show_header() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║               FUNDING VISUALIZATION TOOLS                  ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# Function to check dependencies
check_dependencies() {
  echo -e "${BLUE}Checking dependencies...${NC}"
  
  # Check for jq
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for visualization but not found" "$SCRIPT_NAME"
    echo -e "${RED}Error: jq is required for JSON processing but not found${NC}"
    echo "Please install jq to use this tool"
    return 1
  else
    echo -e "${GREEN}✓${NC} jq found"
  fi
  
  return 0
}

# Function to visualize donation history in ASCII art
visualize_history() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  
  echo -e "${BLUE}═══ Donation History Visualization ═══${NC}"
  
  # Check if tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_error "Donation tracking file not found: $tracking_file" "$SCRIPT_NAME"
    echo -e "${RED}Error: Donation tracking file not found${NC}"
    echo "Run: ./modules/funding/funding_analytics.sh setup"
    return 1
  fi
  
  # Get total donations
  local total_received=$(jq '.total_received' "$tracking_file")
  local github_total=$(jq '.platforms.github_sponsors.total' "$tracking_file")
  local kofi_total=$(jq '.platforms.ko_fi.total' "$tracking_file")
  
  # Print totals
  echo -e "${YELLOW}Donation Totals:${NC}"
  echo -e "  Total Received: ${GREEN}\$$total_received${NC}"
  echo -e "  GitHub Sponsors: ${GREEN}\$$github_total${NC}"
  echo -e "  Ko-fi: ${GREEN}\$$kofi_total${NC}"
  echo ""
  
  # Check if there are any donations
  if [ "$total_received" = "0" ]; then
    echo -e "${YELLOW}No donations recorded yet.${NC}"
    return 0
  fi
  
  # Generate ASCII bar chart showing platform distribution
  echo -e "${YELLOW}Platform Distribution:${NC}"
  
  # Calculate percentages and bar lengths
  local github_percent=0
  local kofi_percent=0
  
  if [ "$total_received" != "0" ]; then
    github_percent=$(awk "BEGIN {printf \"%.1f\", 100 * $github_total / $total_received}")
    kofi_percent=$(awk "BEGIN {printf \"%.1f\", 100 * $kofi_total / $total_received}")
  fi
  
  # Calculate bar lengths (max 40 chars)
  local github_bar_length=$(awk "BEGIN {printf \"%d\", 40 * $github_total / $total_received}")
  local kofi_bar_length=$(awk "BEGIN {printf \"%d\", 40 * $kofi_total / $total_received}")
  
  # Create bars
  local github_bar=$(printf '█%.0s' $(seq 1 $github_bar_length))
  local kofi_bar=$(printf '█%.0s' $(seq 1 $kofi_bar_length))
  
  # Print bars
  echo -e "  GitHub: ${BLUE}$github_bar${NC} ${github_percent}% (\$$github_total)"
  echo -e "  Ko-fi:  ${MAGENTA}$kofi_bar${NC} ${kofi_percent}% (\$$kofi_total)"
  echo ""
  
  # Get donation counts
  local github_count=$(jq '.platforms.github_sponsors.donations | length' "$tracking_file")
  local kofi_count=$(jq '.platforms.ko_fi.donations | length' "$tracking_file")
  local total_count=$((github_count + kofi_count))
  
  echo -e "${YELLOW}Donation Counts:${NC}"
  echo -e "  Total Donations: ${total_count}"
  echo -e "  GitHub Sponsors: ${github_count}"
  echo -e "  Ko-fi: ${kofi_count}"
  echo ""
  
  return 0
}

# Function to generate a timeline visualization
visualize_timeline() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  
  echo -e "${BLUE}═══ Donation Timeline Visualization ═══${NC}"
  
  # Check if tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_error "Donation tracking file not found: $tracking_file" "$SCRIPT_NAME"
    echo -e "${RED}Error: Donation tracking file not found${NC}"
    echo "Run: ./modules/funding/funding_analytics.sh setup"
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    log_error "jq is required for timeline visualization" "$SCRIPT_NAME"
    echo -e "${RED}Error: jq is required for JSON processing but not found${NC}"
    return 1
  fi
  
  # Create a temporary file with all donations from all platforms
  local temp_file="$PROJECT_ROOT/logs/funding/temp_all_donations.json"
  jq -r '.platforms.github_sponsors.donations[] as $d | $d + {platform: "github_sponsors"} | ., .platforms.ko_fi.donations[] as $d | $d + {platform: "ko_fi"}' "$tracking_file" > "$temp_file" 2>/dev/null
  
  # Check if there are any donations
  if [ ! -s "$temp_file" ]; then
    echo -e "${YELLOW}No donations recorded yet.${NC}"
    rm -f "$temp_file"
    return 0
  fi
  
  # Sort donations by date
  jq -s 'sort_by(.date)' "$temp_file" > "${temp_file}.sorted" && mv "${temp_file}.sorted" "$temp_file"
  
  echo -e "${YELLOW}Donation Timeline:${NC}"
  echo ""
  
  # Print a simple timeline
  jq -r '.[] | "\(.date) | \(.platform) | $\(.amount) | \(.donor)"' "$temp_file" | while IFS='|' read -r date platform amount donor; do
    # Trim whitespace
    date=$(echo "$date" | xargs)
    platform=$(echo "$platform" | xargs)
    amount=$(echo "$amount" | xargs)
    donor=$(echo "$donor" | xargs)
    
    # Format platform with color
    if [ "$platform" = "github_sponsors" ]; then
      platform_colored="${BLUE}GitHub${NC}"
    else
      platform_colored="${MAGENTA}Ko-fi${NC}"
    fi
    
    # Print timeline entry
    echo -e "  ${YELLOW}$date${NC} - $platform_colored - ${GREEN}$amount${NC} - $donor"
  done
  
  echo ""
  rm -f "$temp_file"
  
  return 0
}

# Function to create a statistics overview
show_statistics() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  
  echo -e "${BLUE}═══ Donation Statistics ═══${NC}"
  
  # Check if tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_error "Donation tracking file not found: $tracking_file" "$SCRIPT_NAME"
    echo -e "${RED}Error: Donation tracking file not found${NC}"
    echo "Run: ./modules/funding/funding_analytics.sh setup"
    return 1
  fi
  
  # Get basic stats
  local total_received=$(jq '.total_received' "$tracking_file")
  
  # Check if there are any donations
  if [ "$total_received" = "0" ]; then
    echo -e "${YELLOW}No donations recorded yet.${NC}"
    return 0
  fi
  
  # Create a temporary file with all donations
  local temp_file="$PROJECT_ROOT/logs/funding/temp_stats.json"
  jq -r '.platforms.github_sponsors.donations[] as $d | $d + {platform: "github_sponsors"}, .platforms.ko_fi.donations[] as $d | $d + {platform: "ko_fi"}' "$tracking_file" | jq -s '.' > "$temp_file" 2>/dev/null
  
  # Calculate statistics
  local donation_count=$(jq '. | length' "$temp_file")
  local avg_donation=$(jq '. | map(.amount) | add / length' "$temp_file" 2>/dev/null)
  local max_donation=$(jq '. | max_by(.amount) | .amount' "$temp_file" 2>/dev/null)
  local min_donation=$(jq '. | min_by(.amount) | .amount' "$temp_file" 2>/dev/null)
  
  # Format as currency with 2 decimal places
  if [ -n "$avg_donation" ]; then
    avg_donation=$(printf "%.2f" "$avg_donation")
  else
    avg_donation="0.00"
  fi
  
  # Print statistics
  echo -e "${YELLOW}Basic Statistics:${NC}"
  echo -e "  Total Donations: $donation_count"
  echo -e "  Total Amount: \$$total_received"
  echo -e "  Average Donation: \$$avg_donation"
  echo -e "  Largest Donation: \$$max_donation"
  echo -e "  Smallest Donation: \$$min_donation"
  echo ""
  
  # Clean up
  rm -f "$temp_file"
  
  return 0
}

# Function to show funding goal progress
show_goal_progress() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  local goal_amount=100 # Default goal amount
  
  # Check if a custom goal amount was provided
  if [ -n "$1" ]; then
    goal_amount="$1"
  fi
  
  echo -e "${BLUE}═══ Funding Goal Progress ═══${NC}"
  
  # Check if tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_error "Donation tracking file not found: $tracking_file" "$SCRIPT_NAME"
    echo -e "${RED}Error: Donation tracking file not found${NC}"
    echo "Run: ./modules/funding/funding_analytics.sh setup"
    return 1
  fi
  
  # Get total received
  local total_received=$(jq '.total_received' "$tracking_file")
  
  # Calculate percentage of goal
  local percent_complete=$(awk "BEGIN {printf \"%.1f\", 100 * $total_received / $goal_amount}")
  
  # Calculate progress bar length (max 50 chars)
  local bar_length=$(awk "BEGIN {printf \"%d\", 50 * $total_received / $goal_amount}")
  if [ "$bar_length" -gt 50 ]; then
    bar_length=50
  fi
  
  # Create progress bar
  local progress_bar=""
  local remaining_bar=""
  
  if [ "$bar_length" -gt 0 ]; then
    progress_bar=$(printf '█%.0s' $(seq 1 $bar_length))
  fi
  
  remaining_length=$((50 - bar_length))
  if [ "$remaining_length" -gt 0 ]; then
    remaining_bar=$(printf '░%.0s' $(seq 1 $remaining_length))
  fi
  
  # Print progress information
  echo -e "${YELLOW}Goal: \$$goal_amount${NC}"
  echo -e "${YELLOW}Current: \$$total_received${NC} (${percent_complete}% complete)"
  echo -e "[${GREEN}${progress_bar}${NC}${remaining_bar}]"
  echo ""
  
  # Show message based on progress
  if (( $(echo "$percent_complete >= 100" | bc -l) )); then
    echo -e "${GREEN}Goal achieved! Congratulations!${NC}"
  elif (( $(echo "$percent_complete >= 75" | bc -l) )); then
    echo -e "${BLUE}Almost there! Getting very close to the goal.${NC}"
  elif (( $(echo "$percent_complete >= 50" | bc -l) )); then
    echo -e "${BLUE}Great progress! Halfway to the goal.${NC}"
  elif (( $(echo "$percent_complete >= 25" | bc -l) )); then
    echo -e "${YELLOW}Good start! Making progress toward the goal.${NC}"
  else
    echo -e "${YELLOW}Starting the journey toward the funding goal.${NC}"
  fi
  echo ""
  
  return 0
}

# Function to show all visualizations
show_all() {
  show_header
  
  if ! check_dependencies; then
    return 1
  fi
  
  echo ""
  visualize_history
  echo ""
  visualize_timeline
  echo ""
  show_statistics
  echo ""
  show_goal_progress
  
  echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}                   End of Visualizations                        ${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
  echo ""
  
  return 0
}

# Show help message
show_help() {
  echo "Usage: $0 [COMMAND] [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  all           - Show all visualizations (default)"
  echo "  history       - Show donation history visualization"
  echo "  timeline      - Show donation timeline"
  echo "  stats         - Show donation statistics"
  echo "  goal [AMOUNT] - Show progress toward funding goal"
  echo "                  AMOUNT defaults to $100 if not specified"
  echo "  help          - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0"
  echo "  $0 history"
  echo "  $0 goal 500"
}

# Main execution
case "$1" in
  "all"|"")
    show_all
    ;;
  "history")
    show_header
    check_dependencies && visualize_history
    ;;
  "timeline")
    show_header
    check_dependencies && visualize_timeline
    ;;
  "stats")
    show_header
    check_dependencies && show_statistics
    ;;
  "goal")
    show_header
    check_dependencies && show_goal_progress "$2"
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