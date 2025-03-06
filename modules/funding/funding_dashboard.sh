#!/bin/bash
# Funding dashboard for lifeform-2
# This script provides a visual dashboard for funding status

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="funding_dashboard.sh"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show ASCII art dashboard header
show_header() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                   FUNDING DASHBOARD                        ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# Function to display configuration status
show_config_status() {
  echo -e "${BLUE}═══ Configuration Status ═══${NC}"
  
  # Check for FUNDING.yml
  if [ -f "$PROJECT_ROOT/.github/FUNDING.yml" ]; then
    echo -e "  ${GREEN}✓${NC} FUNDING.yml: ${GREEN}Configured${NC}"
  else
    echo -e "  ${RED}✗${NC} FUNDING.yml: ${RED}Missing${NC}"
  fi
  
  # Check for GitHub Sponsors in FUNDING.yml
  if [ -f "$PROJECT_ROOT/.github/FUNDING.yml" ] && grep -q "github:" "$PROJECT_ROOT/.github/FUNDING.yml"; then
    echo -e "  ${GREEN}✓${NC} GitHub Sponsors: ${GREEN}Configured in FUNDING.yml${NC}"
  else
    echo -e "  ${RED}✗${NC} GitHub Sponsors: ${RED}Not configured in FUNDING.yml${NC}"
  fi
  
  # Check for Ko-fi in FUNDING.yml
  if [ -f "$PROJECT_ROOT/.github/FUNDING.yml" ] && grep -q "ko_fi:" "$PROJECT_ROOT/.github/FUNDING.yml"; then
    echo -e "  ${GREEN}✓${NC} Ko-fi: ${GREEN}Configured in FUNDING.yml${NC}"
  else
    echo -e "  ${RED}✗${NC} Ko-fi: ${RED}Not configured in FUNDING.yml${NC}"
  fi
  
  # Check for README badges
  if grep -q "sponsor.*badge\|sponsor.*shield" "$PROJECT_ROOT/README.md" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} GitHub Sponsors: ${GREEN}Badge in README${NC}"
  else
    echo -e "  ${RED}✗${NC} GitHub Sponsors: ${RED}No badge in README${NC}"
  fi
  
  if grep -q "ko-fi" "$PROJECT_ROOT/README.md" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Ko-fi: ${GREEN}Badge in README${NC}"
  else
    echo -e "  ${RED}✗${NC} Ko-fi: ${RED}No badge in README${NC}"
  fi
  
  echo ""
}

# Function to show donation status
show_donation_status() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  
  echo -e "${BLUE}═══ Donation Status ═══${NC}"
  
  if [ ! -f "$tracking_file" ]; then
    echo -e "  ${YELLOW}!${NC} Donation tracking: ${YELLOW}Not set up${NC}"
    echo "  Run: ./modules/funding/funding_analytics.sh setup"
    echo ""
    return
  fi
  
  echo -e "  ${GREEN}✓${NC} Donation tracking: ${GREEN}Active${NC}"
  echo ""
  echo -e "  ${YELLOW}Donation data can be viewed in:${NC}"
  echo "  $tracking_file"
  echo ""
  echo -e "  ${YELLOW}For detailed donation reporting, run:${NC}"
  echo "  ./modules/funding/funding_analytics.sh report"
  echo ""
}

# Function to show funding suggestions
show_funding_suggestions() {
  echo -e "${BLUE}═══ Funding Improvement Suggestions ═══${NC}"
  
  local suggestions=0
  
  # Check FUNDING.yml
  if [ ! -f "$PROJECT_ROOT/.github/FUNDING.yml" ]; then
    echo -e "  ${YELLOW}→${NC} Create FUNDING.yml with GitHub Sponsors and Ko-fi"
    echo "    Run: ./modules/funding/github_sponsors.sh funding golergka"
    suggestions=$((suggestions + 1))
  fi
  
  # Check README badges
  if ! grep -q "sponsor.*badge\|sponsor.*shield" "$PROJECT_ROOT/README.md" 2>/dev/null; then
    echo -e "  ${YELLOW}→${NC} Add GitHub Sponsors badge to README"
    echo "    Run: ./modules/funding/github_sponsors.sh badge golergka"
    suggestions=$((suggestions + 1))
  fi
  
  if ! grep -q "ko-fi" "$PROJECT_ROOT/README.md" 2>/dev/null; then
    echo -e "  ${YELLOW}→${NC} Add Ko-fi badge to README"
    echo "    Run: ./modules/funding/kofi.sh button golergka"
    suggestions=$((suggestions + 1))
  fi
  
  # Check donation tracking
  if [ ! -f "$PROJECT_ROOT/logs/funding/donations.json" ]; then
    echo -e "  ${YELLOW}→${NC} Set up donation tracking"
    echo "    Run: ./modules/funding/funding_analytics.sh setup"
    suggestions=$((suggestions + 1))
  fi
  
  if [ $suggestions -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} All funding components are properly set up!"
    echo "  To further improve funding capabilities, consider:"
    echo "  - Regularly generating funding reports"
    echo "  - Adding funding information to the project documentation"
    echo "  - Creating a dedicated funding page"
  fi
  
  echo ""
}

# Function to show the full dashboard
show_dashboard() {
  show_header
  show_config_status
  show_donation_status
  show_funding_suggestions
  
  echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}                   End of Dashboard                             ${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
  echo ""
}

# Show help message
show_help() {
  echo "Usage: $0 [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  dashboard     - Show the full funding dashboard (default)"
  echo "  config        - Show only configuration status"
  echo "  donations     - Show only donation status"
  echo "  suggestions   - Show only funding improvement suggestions"
  echo "  help          - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0"
  echo "  $0 dashboard"
  echo "  $0 config"
}

# Main execution
case "$1" in
  "dashboard"|"")
    show_dashboard
    ;;
  "config")
    show_header
    show_config_status
    ;;
  "donations")
    show_header
    show_donation_status
    ;;
  "suggestions")
    show_header
    show_funding_suggestions
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