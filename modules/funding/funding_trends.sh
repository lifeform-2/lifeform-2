#!/bin/bash
# Funding trends analysis for lifeform-2
# This script analyzes donation patterns over time

# Load error utilities for consistent error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/core/system/error_utils.sh"

# Script name for logging
SCRIPT_NAME="funding_trends.sh"

# Ensure logs directory exists
mkdir -p "$PROJECT_ROOT/logs/funding" 2>/dev/null

# Function to analyze monthly trends
analyze_monthly_trends() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  
  echo "Analyzing monthly donation trends..."
  
  # Check if tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_warning "No donation tracking file found." "$SCRIPT_NAME"
    echo "❌ No donation data found"
    echo "Run: ./modules/funding/funding_analytics.sh setup"
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    log_error "jq not found. Required for JSON processing." "$SCRIPT_NAME"
    echo "❌ jq not found"
    echo "Please install jq to analyze funding trends"
    return 1
  fi
  
  # Count total donations
  local total_count=$(jq '.platforms.github_sponsors.donations + .platforms.ko_fi.donations | length' "$tracking_file")
  
  if [ "$total_count" -eq 0 ]; then
    echo "No donations found in the tracking file."
    return 0
  fi
  
  echo "Generating monthly trend analysis..."
  
  # Create temporary file for monthly aggregation
  local temp_file="$PROJECT_ROOT/logs/funding/monthly_trends.json"
  
  # Use jq to aggregate donations by month
  jq -r '.platforms | to_entries | 
    map(.value.donations) | 
    flatten | 
    map({month: .date[0:7], amount: .amount}) | 
    group_by(.month) | 
    map({month: .[0].month, total: (map(.amount) | add)}) | 
    sort_by(.month)' "$tracking_file" > "$temp_file"
  
  echo "Monthly donation trends:"
  echo "------------------------"
  
  # Print the monthly trends
  jq -r 'map("| \(.month) | $\(.total) |") | ["| Month | Amount |", "|-------|--------|"] + .' "$temp_file" | while read line; do
    echo "$line"
  done
  
  echo ""
  echo "Trend visualization:"
  echo "-------------------"
  
  # Generate a simple ASCII chart of the trends
  local max_amount=$(jq -r 'map(.total) | max' "$temp_file")
  local scale_factor=40
  
  jq -r 'map("| \(.month) | \(.total | tostring) | \(.total * '"$scale_factor"' / '"$max_amount"' | floor)") | .[]' "$temp_file" | while read month amount chars; do
    # Remove leading/trailing |
    month=${month:1}
    amount=${amount:1}
    chars=${chars:1}
    
    # Print the month and a bar representing the amount
    printf "%-10s $%-8s " "$month" "$amount"
    for ((i=0; i<chars; i++)); do
      printf "#"
    done
    echo ""
  done
  
  # Clean up
  rm -f "$temp_file"
  
  return 0
}

# Function to predict future funding
predict_future_funding() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  local months_ahead=${1:-3}
  
  echo "Predicting funding for the next $months_ahead months..."
  
  # Check if tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_warning "No donation tracking file found." "$SCRIPT_NAME"
    echo "❌ No donation data found"
    echo "Run: ./modules/funding/funding_analytics.sh setup"
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    log_error "jq not found. Required for JSON processing." "$SCRIPT_NAME"
    echo "❌ jq not found"
    echo "Please install jq to predict future funding"
    return 1
  fi
  
  # Count total donations
  local total_count=$(jq '.platforms.github_sponsors.donations + .platforms.ko_fi.donations | length' "$tracking_file")
  
  if [ "$total_count" -lt 2 ]; then
    echo "Insufficient donation data for prediction (need at least 2 donations)."
    return 0
  fi
  
  # Get the total amount and calculate monthly average
  local total_amount=$(jq '.total_received' "$tracking_file")
  
  # Get the date range (earliest to latest donation)
  local earliest_date=$(jq -r '.platforms | to_entries | map(.value.donations[]) | sort_by(.date) | .[0].date // "N/A"' "$tracking_file")
  local latest_date=$(jq -r '.platforms | to_entries | map(.value.donations[]) | sort_by(.date) | reverse | .[0].date // "N/A"' "$tracking_file")
  
  if [ "$earliest_date" = "N/A" ] || [ "$latest_date" = "N/A" ]; then
    echo "Unable to determine date range from donation data."
    return 1
  fi
  
  # Calculate months between earliest and latest donation
  # This is a simplified calculation - a more accurate one would use date manipulation
  local earliest_year=$(echo "$earliest_date" | cut -d'-' -f1)
  local earliest_month=$(echo "$earliest_date" | cut -d'-' -f2)
  local latest_year=$(echo "$latest_date" | cut -d'-' -f1)
  local latest_month=$(echo "$latest_date" | cut -d'-' -f2)
  
  # Calculate months difference
  local months_diff=$(( (latest_year - earliest_year) * 12 + (latest_month - earliest_month) + 1 ))
  
  # Calculate monthly average
  if [ "$months_diff" -gt 0 ]; then
    local monthly_average=$(awk "BEGIN {printf \"%.2f\", $total_amount / $months_diff}")
  else
    local monthly_average=$total_amount
  fi
  
  echo "Analysis based on date range: $earliest_date to $latest_date ($months_diff months)"
  echo "Current total received: $${total_amount}"
  echo "Estimated monthly average: $${monthly_average}"
  echo ""
  
  echo "Funding prediction for next $months_ahead months:"
  echo "------------------------------------------------"
  
  # Print a table with predictions
  echo "| Month | Estimated Amount | Cumulative Total |"
  echo "|-------|-----------------|------------------|"
  
  local current_total=$total_amount
  for ((i=1; i<=months_ahead; i++)); do
    # Calculate new date
    # Again, this is simplified - better date manipulation would be ideal
    local prediction_month=$(( (latest_month + i - 1) % 12 + 1 ))
    local prediction_year=$(( latest_year + (latest_month + i - 1) / 12 ))
    local prediction_date=$(printf "%04d-%02d" "$prediction_year" "$prediction_month")
    
    local new_total=$(awk "BEGIN {printf \"%.2f\", $current_total + $monthly_average}")
    printf "| %s | $%.2f | $%.2f |\n" "$prediction_date" "$monthly_average" "$new_total"
    current_total=$new_total
  done
  
  echo ""
  echo "Note: This is a simple linear projection based on historical average."
  echo "Actual funding may vary based on many factors."
  
  return 0
}

# Function to analyze donation sources
analyze_sources() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  
  echo "Analyzing donation sources..."
  
  # Check if tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_warning "No donation tracking file found." "$SCRIPT_NAME"
    echo "❌ No donation data found"
    echo "Run: ./modules/funding/funding_analytics.sh setup"
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    log_error "jq not found. Required for JSON processing." "$SCRIPT_NAME"
    echo "❌ jq not found"
    echo "Please install jq to analyze donation sources"
    return 1
  fi
  
  # Get platform totals
  local github_total=$(jq '.platforms.github_sponsors.total' "$tracking_file")
  local kofi_total=$(jq '.platforms.ko_fi.total' "$tracking_file")
  local total_received=$(jq '.total_received' "$tracking_file")
  
  # Get donation counts
  local github_count=$(jq '.platforms.github_sponsors.donations | length' "$tracking_file")
  local kofi_count=$(jq '.platforms.ko_fi.donations | length' "$tracking_file")
  local total_count=$((github_count + kofi_count))
  
  if [ "$total_count" -eq 0 ]; then
    echo "No donations found in the tracking file."
    return 0
  fi
  
  # Calculate averages
  local github_avg=0
  local kofi_avg=0
  if [ "$github_count" -gt 0 ]; then
    github_avg=$(awk "BEGIN {printf \"%.2f\", $github_total / $github_count}")
  fi
  if [ "$kofi_count" -gt 0 ]; then
    kofi_avg=$(awk "BEGIN {printf \"%.2f\", $kofi_total / $kofi_count}")
  fi
  
  # Calculate percentages
  local github_percent=0
  local kofi_percent=0
  if [ "$total_received" != "0" ]; then
    github_percent=$(awk "BEGIN {printf \"%.1f\", $github_total / $total_received * 100}")
    kofi_percent=$(awk "BEGIN {printf \"%.1f\", $kofi_total / $total_received * 100}")
  fi
  
  echo "Donation source analysis:"
  echo "------------------------"
  echo "Total donations received: $${total_received} ($total_count donations)"
  echo ""
  
  echo "| Platform | Amount | % of Total | Count | Avg Donation |"
  echo "|----------|--------|------------|-------|--------------|"
  printf "| GitHub Sponsors | $%.2f | %.1f%% | %d | $%.2f |\n" "$github_total" "$github_percent" "$github_count" "$github_avg"
  printf "| Ko-fi | $%.2f | %.1f%% | %d | $%.2f |\n" "$kofi_total" "$kofi_percent" "$kofi_count" "$kofi_avg"
  
  echo ""
  echo "Source distribution visualization:"
  echo "---------------------------------"
  
  # Generate a simple ASCII chart for source distribution
  local scale_factor=50
  
  # GitHub bar
  local github_chars=0
  if [ "$total_received" != "0" ]; then
    github_chars=$(awk "BEGIN {printf \"%.0f\", $github_total / $total_received * $scale_factor}")
  fi
  printf "GitHub Sponsors ($%.2f): " "$github_total"
  for ((i=0; i<github_chars; i++)); do
    printf "#"
  done
  printf " %.1f%%\n" "$github_percent"
  
  # Ko-fi bar
  local kofi_chars=0
  if [ "$total_received" != "0" ]; then
    kofi_chars=$(awk "BEGIN {printf \"%.0f\", $kofi_total / $total_received * $scale_factor}")
  fi
  printf "Ko-fi ($%.2f): " "$kofi_total"
  for ((i=0; i<kofi_chars; i++)); do
    printf "#"
  done
  printf " %.1f%%\n" "$kofi_percent"
  
  return 0
}

# Function to generate a comprehensive funding trends report
generate_trends_report() {
  local tracking_file="$PROJECT_ROOT/logs/funding/donations.json"
  local report_file="$PROJECT_ROOT/logs/funding/funding_trends_report.md"
  
  echo "Generating comprehensive funding trends report..."
  
  # Check if tracking file exists
  if [ ! -f "$tracking_file" ]; then
    log_warning "No donation tracking file found." "$SCRIPT_NAME"
    echo "❌ No donation data found"
    echo "Run: ./modules/funding/funding_analytics.sh setup"
    return 1
  fi
  
  # Create the report file
  cat > "$report_file" << EOF
# Funding Trends Analysis Report

Generated on: $(date)

This report provides detailed analysis of funding trends, patterns, and predictions.

## Overview

EOF
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    log_error "jq not found. Required for JSON processing." "$SCRIPT_NAME"
    echo "❌ jq not found"
    echo "Please install jq to generate trends report"
    echo "Simple report created with limited information" >> "$report_file"
    return 1
  fi
  
  # Add summary information
  local total_received=$(jq '.total_received' "$tracking_file")
  local last_updated=$(jq -r '.last_updated' "$tracking_file")
  local total_count=$(jq '.platforms.github_sponsors.donations + .platforms.ko_fi.donations | length' "$tracking_file")
  
  cat >> "$report_file" << EOF
- **Total Funding Received:** $${total_received}
- **Total Number of Donations:** ${total_count}
- **Last Updated:** ${last_updated}

EOF
  
  # If there are no donations, add a note
  if [ "$total_count" -eq 0 ]; then
    cat >> "$report_file" << EOF
No donations have been recorded yet. This report will be more useful once donations start coming in.

EOF
    echo "✅ Report generated at: $report_file"
    return 0
  fi
  
  # Get the date range
  local earliest_date=$(jq -r '.platforms | to_entries | map(.value.donations[]) | sort_by(.date) | .[0].date // "N/A"' "$tracking_file")
  local latest_date=$(jq -r '.platforms | to_entries | map(.value.donations[]) | sort_by(.date) | reverse | .[0].date // "N/A"' "$tracking_file")
  
  # Add source analysis section
  cat >> "$report_file" << EOF
## Donation Source Analysis

This section analyzes the distribution of donations across different funding platforms.

EOF
  
  # Get platform totals
  local github_total=$(jq '.platforms.github_sponsors.total' "$tracking_file")
  local kofi_total=$(jq '.platforms.ko_fi.total' "$tracking_file")
  
  # Get donation counts
  local github_count=$(jq '.platforms.github_sponsors.donations | length' "$tracking_file")
  local kofi_count=$(jq '.platforms.ko_fi.donations | length' "$tracking_file")
  
  # Calculate averages
  local github_avg=0
  local kofi_avg=0
  if [ "$github_count" -gt 0 ]; then
    github_avg=$(awk "BEGIN {printf \"%.2f\", $github_total / $github_count}")
  fi
  if [ "$kofi_count" -gt 0 ]; then
    kofi_avg=$(awk "BEGIN {printf \"%.2f\", $kofi_total / $kofi_count}")
  fi
  
  # Calculate percentages
  local github_percent=0
  local kofi_percent=0
  if [ "$total_received" != "0" ]; then
    github_percent=$(awk "BEGIN {printf \"%.1f\", $github_total / $total_received * 100}")
    kofi_percent=$(awk "BEGIN {printf \"%.1f\", $kofi_total / $total_received * 100}")
  fi
  
  cat >> "$report_file" << EOF
| Platform | Amount | % of Total | Count | Avg Donation |
|----------|--------|------------|-------|--------------|
| GitHub Sponsors | $${github_total} | ${github_percent}% | ${github_count} | $${github_avg} |
| Ko-fi | $${kofi_total} | ${kofi_percent}% | ${kofi_count} | $${kofi_avg} |

EOF
  
  # Add monthly trend analysis section
  cat >> "$report_file" << EOF
## Monthly Trends

This section shows donation trends over time, from ${earliest_date} to ${latest_date}.

EOF
  
  # Create temporary file for monthly aggregation
  local temp_file="$PROJECT_ROOT/logs/funding/monthly_trends.json"
  
  # Use jq to aggregate donations by month
  jq -r '.platforms | to_entries | 
    map(.value.donations) | 
    flatten | 
    map({month: .date[0:7], amount: .amount}) | 
    group_by(.month) | 
    map({month: .[0].month, total: (map(.amount) | add)}) | 
    sort_by(.month)' "$tracking_file" > "$temp_file"
  
  # Add monthly trend table
  cat >> "$report_file" << EOF
### Monthly Donation Data

| Month | Amount |
|-------|--------|
EOF
  
  jq -r 'map("| \(.month) | $\(.total) |") | .' "$temp_file" >> "$report_file"
  
  echo "" >> "$report_file"
  
  # Calculate monthly average and total months
  local earliest_year=$(echo "$earliest_date" | cut -d'-' -f1)
  local earliest_month=$(echo "$earliest_date" | cut -d'-' -f2)
  local latest_year=$(echo "$latest_date" | cut -d'-' -f1)
  local latest_month=$(echo "$latest_date" | cut -d'-' -f2)
  
  # Calculate months difference
  local months_diff=$(( (latest_year - earliest_year) * 12 + (latest_month - earliest_month) + 1 ))
  
  # Calculate monthly average
  if [ "$months_diff" -gt 0 ]; then
    local monthly_average=$(awk "BEGIN {printf \"%.2f\", $total_received / $months_diff}")
  else
    local monthly_average=$total_received
  fi
  
  # Add trend analysis summary
  cat >> "$report_file" << EOF
### Trend Summary

- **Date Range:** ${earliest_date} to ${latest_date} (${months_diff} months)
- **Monthly Average:** $${monthly_average}

EOF
  
  # Add future predictions section (next 3 months)
  cat >> "$report_file" << EOF
## Future Funding Predictions

Based on historical donation patterns, here are projections for the next 3 months:

| Month | Estimated Amount | Cumulative Total |
|-------|-----------------|------------------|
EOF
  
  local current_total=$total_received
  for ((i=1; i<=3; i++)); do
    # Calculate new date
    local prediction_month=$(( (latest_month + i - 1) % 12 + 1 ))
    local prediction_year=$(( latest_year + (latest_month + i - 1) / 12 ))
    local prediction_date=$(printf "%04d-%02d" "$prediction_year" "$prediction_month")
    
    local new_total=$(awk "BEGIN {printf \"%.2f\", $current_total + $monthly_average}")
    printf "| %s | $%.2f | $%.2f |\n" "$prediction_date" "$monthly_average" "$new_total" >> "$report_file"
    current_total=$new_total
  done
  
  cat >> "$report_file" << EOF

**Note:** These projections are based on a simple linear model using historical averages. Actual funding may vary.

## Recommendations

Based on the funding trend analysis, here are some recommendations:

EOF
  
  # Add recommendations based on data
  if [ "$total_count" -lt 5 ]; then
    cat >> "$report_file" << EOF
1. **Increase Visibility:** The donation count is still low. Consider more active promotion of funding options.
2. **Diversify Platforms:** Look into expanding to additional funding platforms to reach more potential supporters.
3. **Create Funding Goals:** Establish specific funding goals to motivate donations.
EOF
  else
    cat >> "$report_file" << EOF
1. **Continue Regular Updates:** Maintain consistent communication with donors about progress and achievements.
2. **Focus on High-Performing Platforms:** Allocate more promotion efforts to the platforms showing better results.
3. **Consider Subscription Options:** Explore recurring donation options for more stable funding.
EOF
  fi
  
  # Clean up
  rm -f "$temp_file"
  
  echo "✅ Report generated at: $report_file"
  
  return 0
}

# Show help message
show_help() {
  echo "Usage: $0 COMMAND [OPTIONS]"
  echo ""
  echo "Commands:"
  echo "  monthly      - Analyze monthly donation trends"
  echo "  predict [N]  - Predict funding for the next N months (default: 3)"
  echo "  sources      - Analyze donation sources distribution"
  echo "  report       - Generate comprehensive funding trends report"
  echo "  help         - Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 monthly"
  echo "  $0 predict 6"
  echo "  $0 sources"
  echo "  $0 report"
}

# Main execution
case "$1" in
  "monthly")
    analyze_monthly_trends
    ;;
  "predict")
    predict_future_funding "$2"
    ;;
  "sources")
    analyze_sources
    ;;
  "report")
    generate_trends_report
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