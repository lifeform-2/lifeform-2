#!/bin/bash
# Funding analytics for lifeform-2
# This script helps track and analyze funding sources

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="funding_analytics.sh"

# Ensure logs directory exists
mkdir -p "$PROJECT_ROOT/logs/funding" 2>/dev/null

# Function to check funding configuration
check_funding_config() {
  echo "Checking funding configuration..."
  
  # Check for FUNDING.yml
  if [ -f "$PROJECT_ROOT/.github/FUNDING.yml" ]; then
    echo "✅ FUNDING.yml exists"
    echo "Current configuration:"
    cat "$PROJECT_ROOT/.github/FUNDING.yml"
  else
    log_warning "FUNDING.yml not found. Funding options won't appear on GitHub." "$SCRIPT_NAME"
    echo "❌ FUNDING.yml not found"
    echo "Run: ./modules/funding/github_sponsors.sh funding [username]"
    echo "  or ./modules/funding/kofi.sh funding [username]"
  fi
  
  echo ""
  echo "Checking for funding modules:"
  
  # Check for GitHub Sponsors module
  if [ -f "$PROJECT_ROOT/modules/funding/github_sponsors.sh" ]; then
    echo "✅ GitHub Sponsors module exists"
  else
    log_warning "GitHub Sponsors module not found" "$SCRIPT_NAME"
    echo "❌ GitHub Sponsors module not found"
  fi
  
  # Check for Ko-fi module
  if [ -f "$PROJECT_ROOT/modules/funding/kofi.sh" ]; then
    echo "✅ Ko-fi module exists"
  else
    log_warning "Ko-fi module not found" "$SCRIPT_NAME"
    echo "❌ Ko-fi module not found"
  fi
  
  # Check for README funding badges
  echo ""
  echo "Checking for README funding badges:"
  if grep -q "sponsor.*badge\|sponsor.*shield\|ko-fi" "$PROJECT_ROOT/README.md" 2>/dev/null; then
    echo "✅ Funding badges found in README.md"
  else
    log_warning "No funding badges found in README.md" "$SCRIPT_NAME"
    echo "❌ No funding badges found in README.md"
    echo "Run: ./modules/funding/github_sponsors.sh badge [username]"
    echo "  or ./modules/funding/kofi.sh button [username]"
  fi
}

# Function to set up donation tracking file
setup_donation_tracking() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  
  echo "Setting up donation tracking..."
  
  # Check if tracking file exists
  if [ -f "$tracking_file" ]; then
    echo "✅ Donation tracking file already exists"
    echo "Current donation data:"
    cat "$tracking_file"
    return 0
  fi
  
  # Create tracking file with empty structure
  cat > "$tracking_file" << EOF
{
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "platforms": {
    "github_sponsors": {
      "total": 0,
      "donations": []
    },
    "ko_fi": {
      "total": 0,
      "donations": []
    }
  },
  "total_received": 0
}
EOF
  
  if [ $? -eq 0 ]; then
    echo "✅ Created donation tracking file at: $tracking_file"
  else
    log_error "Failed to create donation tracking file" "$SCRIPT_NAME"
    echo "❌ Failed to create donation tracking file"
    return 1
  fi
  
  return 0
}

# Function to manually record a donation
record_donation() {
  local platform="$1"
  local amount="$2"
  local date="$3"
  local donor="$4"
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  
  # Validate inputs
  if [ -z "$platform" ] || [ -z "$amount" ]; then
    log_error "Platform and amount are required" "$SCRIPT_NAME"
    echo "Usage: $0 record PLATFORM AMOUNT [DATE] [DONOR]"
    echo "  PLATFORM: github_sponsors or ko_fi"
    echo "  AMOUNT: donation amount in USD (e.g., 5.00)"
    echo "  DATE: donation date (YYYY-MM-DD), defaults to today"
    echo "  DONOR: donor name or ID (optional, use 'anonymous' if unknown)"
    return 1
  fi
  
  # Validate platform
  if [ "$platform" != "github_sponsors" ] && [ "$platform" != "ko_fi" ]; then
    log_error "Invalid platform: $platform" "$SCRIPT_NAME"
    echo "Supported platforms: github_sponsors, ko_fi"
    return 1
  fi
  
  # Validate amount format (decimal number)
  if ! echo "$amount" | grep -q '^[0-9]\+\(\.[0-9]\{1,2\}\)\?$'; then
    log_error "Invalid amount format: $amount" "$SCRIPT_NAME"
    echo "Amount should be a number like 5.00"
    return 1
  fi
  
  # Set default date to today if not provided
  if [ -z "$date" ]; then
    date="$(date +"%Y-%m-%d")"
  fi
  
  # Validate date format (YYYY-MM-DD)
  if ! echo "$date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$'; then
    log_error "Invalid date format: $date" "$SCRIPT_NAME"
    echo "Date should be in YYYY-MM-DD format"
    return 1
  fi
  
  # Set default donor to anonymous if not provided
  if [ -z "$donor" ]; then
    donor="anonymous"
  fi
  
  # Ensure tracking file exists
  if [ ! -f "$tracking_file" ]; then
    setup_donation_tracking
  fi
  
  echo "Recording $platform donation of \$$amount on $date from $donor..."
  
  # Create temporary file for new donation entry
  local temp_file="$PROJECT_ROOT/logs/funding/temp_donation.json"
  cat > "$temp_file" << EOF
{
  "platform": "$platform",
  "amount": $amount,
  "date": "$date",
  "donor": "$donor",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    log_warning "jq not found. Manual JSON update required." "$SCRIPT_NAME"
    echo "✅ Donation data saved, but not yet added to main tracking file"
    echo ""
    echo "The donation data has been saved to: $temp_file"
    echo ""
    echo "To properly update the JSON structure, install jq or manually update the file"
    echo "Command for updating with jq:"
    echo "jq --argjson new_donation \"\$(cat $temp_file)\" '.platforms[.new_donation.platform].donations += [.new_donation] | .platforms[.new_donation.platform].total += (.new_donation.amount | tonumber) | .total_received += (.new_donation.amount | tonumber) | .last_updated = \"\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")\"' $tracking_file > ${tracking_file}.new && mv ${tracking_file}.new $tracking_file"
    return 0
  fi
  
  # Since jq is available, directly update the JSON file
  echo "Updating donation tracking file with jq..."
  
  # Use jq to update the donation tracking file
  jq --argjson new_donation "$(cat $temp_file)" \
    '.platforms[$new_donation.platform].donations += [$new_donation] | 
     .platforms[$new_donation.platform].total += ($new_donation.amount | tonumber) | 
     .total_received += ($new_donation.amount | tonumber) | 
     .last_updated = "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"' \
    "$tracking_file" > "${tracking_file}.new" && mv "${tracking_file}.new" "$tracking_file"
  
  # Check if the update was successful
  if [ $? -eq 0 ]; then
    echo "✅ Donation recorded and tracking file updated successfully"
    rm -f "$temp_file"  # Remove the temporary file
    echo ""
    echo "Donation summary:"
    echo "- Platform: $platform"
    echo "- Amount: \$$amount"
    echo "- Date: $date"
    echo "- Donor: $donor"
    echo ""
    echo "Updated tracking file: $tracking_file"
  else
    log_error "Failed to update donation tracking file" "$SCRIPT_NAME"
    echo "❌ Failed to update donation tracking file"
    echo "The donation data has been saved to: $temp_file"
    echo "Please try again or update the file manually"
    return 1
  fi
  
  return 0
}

# Function to generate funding report
generate_report() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  local report_file="$PROJECT_ROOT/logs/funding/funding_report.md"
  
  echo "Generating funding report..."
  
  # Ensure tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_warning "No donation tracking file found. Creating empty one." "$SCRIPT_NAME"
    setup_donation_tracking
  fi
  
  # Create report file
  cat > "$report_file" << EOF
# Funding Report

Generated on: $(date)

## Summary

This report provides an overview of the current funding status and donation history for the lifeform.

## Current Funding Sources

| Platform | Status |
|----------|--------|
| GitHub Sponsors | ${GITHUB_SPONSORS_STATUS:-"Not verified"} |
| Ko-fi | ${KOFI_STATUS:-"Not verified"} |

## Configuration Status

EOF
  
  # Add configuration status
  if [ -f "$PROJECT_ROOT/.github/FUNDING.yml" ]; then
    echo "- ✅ FUNDING.yml is properly configured" >> "$report_file"
  else
    echo "- ❌ FUNDING.yml is missing" >> "$report_file"
  fi
  
  if grep -q "sponsor.*badge\|sponsor.*shield\|ko-fi" "$PROJECT_ROOT/README.md" 2>/dev/null; then
    echo "- ✅ Funding badges are present in README.md" >> "$report_file"
  else
    echo "- ❌ Funding badges are missing from README.md" >> "$report_file"
  fi
  
  # Add donation information
  cat >> "$report_file" << EOF

## Donation History

The following donation data is available:

EOF
  
  # Check if jq is available for JSON processing
  if ! command -v jq &> /dev/null; then
    log_warning "jq not found. Using basic report format." "$SCRIPT_NAME"
    echo "**Note:** Full donation analysis requires jq for JSON processing" >> "$report_file"
    echo "" >> "$report_file"
    echo "Raw donation data:" >> "$report_file"
    echo "```json" >> "$report_file"
    cat "$tracking_file" >> "$report_file"
    echo "```" >> "$report_file"
  else
    # Get total donations using jq
    total_received=$(jq '.total_received' "$tracking_file")
    github_total=$(jq '.platforms.github_sponsors.total' "$tracking_file")
    kofi_total=$(jq '.platforms.ko_fi.total' "$tracking_file")
    last_updated=$(jq -r '.last_updated' "$tracking_file")
    
    # Add summary to report
    cat >> "$report_file" << EOF
### Donation Summary

- **Total Received:** $${total_received}
- **Last Updated:** ${last_updated}

| Platform | Total Amount |
|----------|--------------|
| GitHub Sponsors | $${github_total} |
| Ko-fi | $${kofi_total} |

EOF
    
    # Count total donations
    github_count=$(jq '.platforms.github_sponsors.donations | length' "$tracking_file")
    kofi_count=$(jq '.platforms.ko_fi.donations | length' "$tracking_file")
    
    # Add detailed listings if there are any donations
    if [ "$github_count" -gt 0 ] || [ "$kofi_count" -gt 0 ]; then
      echo "### Detailed Donation Listings" >> "$report_file"
      echo "" >> "$report_file"
      
      # Add GitHub Sponsors donations if any
      if [ "$github_count" -gt 0 ]; then
        echo "#### GitHub Sponsors" >> "$report_file"
        echo "" >> "$report_file"
        echo "| Date | Amount | Donor |" >> "$report_file"
        echo "|------|--------|-------|" >> "$report_file"
        
        # Extract and format GitHub donations
        jq -r '.platforms.github_sponsors.donations | sort_by(.date) | reverse | .[] | "| \(.date) | $\(.amount) | \(.donor) |"' "$tracking_file" >> "$report_file"
        echo "" >> "$report_file"
      fi
      
      # Add Ko-fi donations if any
      if [ "$kofi_count" -gt 0 ]; then
        echo "#### Ko-fi" >> "$report_file"
        echo "" >> "$report_file"
        echo "| Date | Amount | Donor |" >> "$report_file"
        echo "|------|--------|-------|" >> "$report_file"
        
        # Extract and format Ko-fi donations
        jq -r '.platforms.ko_fi.donations | sort_by(.date) | reverse | .[] | "| \(.date) | $\(.amount) | \(.donor) |"' "$tracking_file" >> "$report_file"
        echo "" >> "$report_file"
      fi
    else
      echo "No donations have been recorded yet." >> "$report_file"
      echo "" >> "$report_file"
    fi
    
    # Add monthly statistics if there are any donations
    if [ "$github_count" -gt 0 ] || [ "$kofi_count" -gt 0 ]; then
      echo "### Monthly Statistics" >> "$report_file"
      echo "" >> "$report_file"
      echo "This section provides a monthly breakdown of donations." >> "$report_file"
      echo "" >> "$report_file"
      echo "**Note:** To be implemented in future updates" >> "$report_file"
      echo "" >> "$report_file"
    fi
  fi
  
  echo "✅ Report generated at: $report_file"
  
  return 0
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  check         - Check funding configuration status"
  echo "  setup         - Set up donation tracking"
  echo "  record PLATFORM AMOUNT [DATE] [DONOR] - Record a donation"
  echo "  report        - Generate funding report"
  echo "  help          - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 check"
  echo "  $0 setup"
  echo "  $0 record github_sponsors 5.00 2025-03-10 anonymous"
  echo "  $0 report"
}

# Main execution
case "$1" in
  "check")
    check_funding_config
    ;;
  "setup")
    setup_donation_tracking
    ;;
  "record")
    record_donation "$2" "$3" "$4" "$5"
    ;;
  "report")
    generate_report
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