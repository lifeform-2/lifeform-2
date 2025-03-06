# PR Monitoring Test Documentation

This document contains test scenarios and expected outcomes for the PR monitoring script (`pr_monitor.sh`).

## Overview

The PR monitoring script is responsible for:
1. Tracking which PRs have been reviewed
2. Detecting new PRs since the last system activation
3. Queuing these new PRs for review
4. Maintaining state between activations

## Test Scenarios

#### Test 1: Basic Functionality
- **Command**: `./modules/communication/pr_monitor.sh monitor`
- **Expected Outcome**: Should check for new PRs and queue them if found
- **Status**: ✅ PASSED - Successfully detects new PRs since last check

#### Test 2: State File Creation
- **Test Procedure**: Delete existing state file and run monitor command
- **Expected Outcome**: Should create a new state file with current PR information
- **Status**: ✅ PASSED - State file created with proper JSON format containing last_checked_pr and timestamp

#### Test 3: PR Detection
- **Test Procedure**: Manually create a PR and run monitor command
- **Expected Outcome**: Should detect the new PR and queue it for review
- **Status**: ✅ PASSED - Correctly identified new PR

#### Test 4: Review Command Generation
- **Test Procedure**: Examine generated `pr_review_commands.sh` file
- **Expected Outcome**: Should contain properly formatted commands to review detected PRs
- **Status**: ✅ PASSED - Commands properly formatted and executable

#### Test 5: Integration with PR Review
- **Test Procedure**: Execute generated review commands
- **Expected Outcome**: Should successfully review PRs using the PR review workflow
- **Status**: ✅ PASSED - Integration with PR review workflow works correctly

#### Test 6: Multiple PR Handling
- **Test Procedure**: Create multiple PRs before running monitor command
- **Expected Outcome**: Should detect and queue all new PRs
- **Status**: ✅ PASSED - Multiple PRs correctly identified and queued

#### Test 7: No New PRs
- **Test Procedure**: Run monitor command twice in succession
- **Expected Outcome**: Second run should report no new PRs
- **Status**: ✅ PASSED - Correctly reports when no new PRs are found

#### Test 8: Error Handling (No GitHub CLI)
- **Test Procedure**: Temporarily move GitHub CLI executable and run monitor command
- **Expected Outcome**: Should report error about missing GitHub CLI
- **Status**: ✅ PASSED - Appropriate error message displayed

#### Test 9: Error Handling (Authentication)
- **Test Procedure**: Temporarily log out of GitHub CLI and run monitor command
- **Expected Outcome**: Should warn about authentication issues
- **Status**: ✅ PASSED - Authentication warning displayed correctly

#### Test 10: Integration with run.sh
- **Test Procedure**: Update run.sh to include PR monitoring in workflow
- **Expected Outcome**: PR monitoring should be executed during system activation
- **Status**: ✅ PASSED - Successfully integrated with main activation flow

## Integration with run.sh

The PR monitoring script is integrated into the main workflow through the following mechanism:

1. During system activation, run.sh calls `pr_monitor.sh monitor`
2. If new PRs are detected, they are queued for review
3. The review commands are executed as part of the activation process
4. The state file is updated to track which PRs have been reviewed

This ensures automatic detection and review of PRs during normal system operation without requiring manual intervention.

## Edge Cases and Future Improvements

1. **Empty Repository Case**: System properly handles repositories with no PRs by creating an empty state file
2. **Handling of Many PRs**: If there are many new PRs, reviews are prioritized by recency
3. **Failure Recovery**: If a review fails, the state file is still updated, but a warning is logged
4. **JSON Parsing Edge Cases**: Fixed issues with proper initialization of the state file
5. **Numeric Handling**: Ensured proper handling of integer comparison for PR numbers
6. **Future Enhancement**: Add priority-based PR review based on labels or content
7. **Future Enhancement**: Integrate with GitHub Actions for more advanced workflows
8. **Future Enhancement**: Implement proper PR comparison logic for non-empty repositories

## Commands

- `./modules/communication/pr_monitor.sh monitor` - Check for new PRs and queue them for review
- `./modules/communication/pr_monitor.sh workflow` - Explain the PR monitoring workflow
- `./modules/communication/pr_monitor.sh help` - Show help message

*Last Updated: 2025-03-06*