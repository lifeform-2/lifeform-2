# Funding Analytics Tests

This document contains test scenarios for the funding analytics functionality.

## Overview

The funding analytics module provides capabilities for:
1. Checking funding configuration status
2. Setting up donation tracking
3. Recording donations manually
4. Generating funding reports

## Test Scenarios

### Test 1: Configuration Check

**Purpose:** Verify that funding configuration check correctly identifies the status of funding components

**Steps:**
1. Run `./modules/funding/funding_analytics.sh check`
2. Observe the output

**Expected Results:**
- Script should detect the presence of FUNDING.yml
- Script should detect the presence of funding modules
- Script should check for funding badges in README
- Output should clearly indicate which components exist and which are missing

**Test Results:**
- ✅ Correctly identifies presence of FUNDING.yml
- ✅ Correctly identifies funding modules
- ✅ Correctly checks README for badges
- ✅ Provides clear output for each component

### Test 2: Donation Tracking Setup

**Purpose:** Verify that donation tracking setup creates the necessary JSON structure

**Steps:**
1. Remove existing tracking file if present: `rm -f ./logs/funding/donations.json`
2. Run `./modules/funding/funding_analytics.sh setup`
3. Verify the created JSON file

**Expected Results:**
- Script should create donations.json with the correct structure
- JSON should have empty arrays for each platform
- JSON should have proper timestamp and total values

**Test Results:**
- ✅ Creates donations.json with proper structure
- ✅ Initializes empty donation arrays
- ✅ Sets proper initial values for totals
- ✅ Includes proper timestamp

### Test 3: Donation Recording

**Purpose:** Verify that donation recording works correctly with valid inputs

**Steps:**
1. Run `./modules/funding/funding_analytics.sh record github_sponsors 10.00 2025-03-10 "Test Donor"`
2. Check temporary JSON file for correct data

**Expected Results:**
- Script should validate inputs correctly
- Script should create temporary donation JSON
- Script should provide instructions for using jq to update the main JSON

**Test Results:**
- ✅ Validates platform input (rejects invalid platforms)
- ✅ Validates amount format
- ✅ Validates date format
- ✅ Creates properly formatted temporary JSON
- ✅ Provides clear instructions for completing the update

### Test 4: Report Generation

**Purpose:** Verify that funding report generation creates a proper Markdown report

**Steps:**
1. Run `./modules/funding/funding_analytics.sh report`
2. Check generated report file

**Expected Results:**
- Script should create a report in Markdown format
- Report should include configuration status
- Report should include donation history (placeholder)
- Report should show proper formatting

**Test Results:**
- ✅ Creates properly formatted Markdown report
- ✅ Includes configuration status section
- ✅ Includes placeholder for donation history
- ✅ Shows JSON data for Claude to process
- ✅ Uses proper headings and table formats

### Test 5: Error Handling

**Purpose:** Verify that the script properly handles errors and invalid inputs

**Steps:**
1. Run with invalid command: `./modules/funding/funding_analytics.sh invalid_command`
2. Run record with invalid platform: `./modules/funding/funding_analytics.sh record invalid_platform 5.00`
3. Run record with invalid amount: `./modules/funding/funding_analytics.sh record github_sponsors invalid_amount`
4. Run record with invalid date: `./modules/funding/funding_analytics.sh record github_sponsors 5.00 invalid_date`

**Expected Results:**
- Script should show helpful error messages for all invalid inputs
- Script should not crash or produce unexpected output
- Script should return non-zero exit code for errors

**Test Results:**
- ✅ Shows error message for invalid commands
- ✅ Shows error message for invalid platform
- ✅ Shows error message for invalid amount format
- ✅ Shows error message for invalid date format
- ✅ Does not crash with any invalid input

## Manual Testing Instructions

To manually test the funding analytics module:

1. **Configuration Check**
   ```bash
   ./modules/funding/funding_analytics.sh check
   ```

2. **Donation Tracking Setup**
   ```bash
   ./modules/funding/funding_analytics.sh setup
   ```

3. **Record Donation**
   ```bash
   # Format: record PLATFORM AMOUNT [DATE] [DONOR]
   ./modules/funding/funding_analytics.sh record github_sponsors 5.00 2025-03-10 "John Doe"
   ./modules/funding/funding_analytics.sh record ko_fi 3.50
   ```

4. **Generate Report**
   ```bash
   ./modules/funding/funding_analytics.sh report
   ```

5. **View Help**
   ```bash
   ./modules/funding/funding_analytics.sh help
   ```

## Known Limitations

1. The module requires manual recording of donations (no API integration yet)
2. Proper JSON manipulation requires the `jq` tool and Claude's assistance
3. Report generation requires Claude to process the JSON data for complete information
4. No automatic verification of account status (requires manual checks)