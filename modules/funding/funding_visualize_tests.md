# Funding Visualization Tests

This document contains test scenarios for the funding visualization functionality.

## Overview

The funding visualization module provides capabilities for:
1. Visualizing donation history with ASCII charts
2. Displaying donation timeline
3. Showing donation statistics
4. Tracking progress toward funding goals

## Test Scenarios

### Test 1: Full Visualization Display

**Purpose:** Verify that the full visualization shows all components correctly

**Steps:**
1. Run `./modules/funding/funding_visualize.sh` or `./modules/funding/funding_visualize.sh all`
2. Observe the output

**Expected Results:**
- Should show visualization header
- Should display donation history visualization with ASCII charts
- Should display donation timeline
- Should show donation statistics
- Should show funding goal progress
- All sections should be properly formatted with colors

**Test Results:**
- ✅ Shows proper header
- ✅ Shows donation history visualization with distribution charts
- ✅ Shows donation timeline in chronological order
- ✅ Shows statistics with key metrics
- ✅ Shows funding goal progress with visual progress bar
- ✅ Uses ANSI colors for better readability

### Test 2: Donation History Visualization

**Purpose:** Verify that the donation history visualization shows correct information

**Steps:**
1. Run `./modules/funding/funding_visualize.sh history`
2. Observe the output

**Expected Results:**
- Should show only the donation history visualization
- Should display total donation amounts by platform
- Should show ASCII bar chart for platform distribution
- Should handle empty donation data gracefully

**Test Results:**
- ✅ Shows only donation history when requested
- ✅ Correctly displays donation totals by platform
- ✅ Shows distribution with proportional ASCII bars
- ✅ Handles empty donation data with appropriate message
- ✅ Calculates percentages correctly

### Test 3: Timeline Visualization

**Purpose:** Verify that the timeline visualization shows donations in chronological order

**Steps:**
1. Run `./modules/funding/funding_visualize.sh timeline`
2. Observe the output

**Expected Results:**
- Should show only the timeline visualization
- Should display donations in chronological order
- Should show date, platform, amount, and donor for each donation
- Should handle empty donation data gracefully

**Test Results:**
- ✅ Shows only timeline when requested
- ✅ Displays donations in chronological order by date
- ✅ Shows all required information for each donation
- ✅ Uses color coding to distinguish platforms
- ✅ Handles empty donation data with appropriate message

### Test 4: Statistics Display

**Purpose:** Verify that the statistics display shows correct information

**Steps:**
1. Run `./modules/funding/funding_visualize.sh stats`
2. Observe the output

**Expected Results:**
- Should show only the statistics section
- Should display donation count, total amount, and averages
- Should show minimum and maximum donation amounts
- Should handle empty donation data gracefully

**Test Results:**
- ✅ Shows only statistics when requested
- ✅ Correctly calculates and displays key metrics
- ✅ Shows minimum and maximum donation amounts
- ✅ Handles empty donation data with appropriate message
- ✅ Formats currency values consistently

### Test 5: Funding Goal Progress

**Purpose:** Verify that the funding goal progress shows appropriate visualization

**Steps:**
1. Run `./modules/funding/funding_visualize.sh goal`
2. Run `./modules/funding/funding_visualize.sh goal 500`
3. Observe the output

**Expected Results:**
- Should show only the funding goal section
- Should display progress toward the goal with a visual progress bar
- Should show percentage complete
- Should accept custom goal amount as parameter
- Should show appropriate message based on progress level

**Test Results:**
- ✅ Shows only goal progress when requested
- ✅ Displays visual progress bar with proportional fill
- ✅ Shows percentage complete accurately
- ✅ Accepts and uses custom goal amount when provided
- ✅ Shows appropriate encouragement message based on progress
- ✅ Uses default goal amount ($100) when no amount specified

### Test 6: Help Display

**Purpose:** Verify that the help command shows proper usage information

**Steps:**
1. Run `./modules/funding/funding_visualize.sh help`
2. Observe the output

**Expected Results:**
- Should show usage information
- Should list all available commands
- Should provide examples of command usage

**Test Results:**
- ✅ Shows proper usage information
- ✅ Lists all available commands with descriptions
- ✅ Provides clear examples of command usage
- ✅ Explains optional parameters

## Manual Testing Instructions

To manually test the funding visualization:

1. **Full Visualization**
   ```bash
   ./modules/funding/funding_visualize.sh
   ```

2. **Donation History Visualization**
   ```bash
   ./modules/funding/funding_visualize.sh history
   ```

3. **Timeline Visualization**
   ```bash
   ./modules/funding/funding_visualize.sh timeline
   ```

4. **Statistics Display**
   ```bash
   ./modules/funding/funding_visualize.sh stats
   ```

5. **Funding Goal Progress**
   ```bash
   ./modules/funding/funding_visualize.sh goal
   ./modules/funding/funding_visualize.sh goal 500
   ```

6. **Help**
   ```bash
   ./modules/funding/funding_visualize.sh help
   ```

## Test with Sample Data

For thorough testing, you can add sample donations using:

```bash
./modules/funding/funding_analytics.sh record github_sponsors 25.00 2025-03-01 "Test Donor 1"
./modules/funding/funding_analytics.sh record ko_fi 10.00 2025-03-05 "Test Donor 2"
./modules/funding/funding_analytics.sh record github_sponsors 50.00 2025-03-10 "Test Donor 3"
```

Then run the visualization tools to see the results:

```bash
./modules/funding/funding_visualize.sh
```

## Notes

1. The visualization uses ANSI color codes for better readability in terminal environments
2. All visualizations are ASCII-based for maximum compatibility
3. The module depends on jq for JSON processing
4. The module does not modify any files; it only provides visualizations
5. For actual donation recording, use the funding_analytics.sh script