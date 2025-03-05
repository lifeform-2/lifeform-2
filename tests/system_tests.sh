#!/bin/bash
# System tests for the lifeform project

# Color codes for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
  local test_name=$1
  local test_command=$2
  local expected_status=$3
  
  echo -e "${YELLOW}Running test: $test_name${NC}"
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  
  # Run the command
  eval "$test_command"
  local status=$?
  
  # Check if the status matches expected
  if [ $status -eq $expected_status ]; then
    echo -e "${GREEN}✓ Test passed: $test_name${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ Test failed: $test_name${NC}"
    echo -e "${RED}  Expected status: $expected_status, Got: $status${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  echo ""
}

# Function to print test summary
print_summary() {
  echo -e "${YELLOW}Test Summary:${NC}"
  echo -e "Total tests: $TESTS_TOTAL"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  
  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    return 1
  fi
}

# Test run.sh exists and is executable
run_test "run.sh exists" "test -f ./run.sh" 0
run_test "run.sh is executable" "test -x ./run.sh" 0

# Test directory structure
run_test "docs directory exists" "test -d ./docs" 0
run_test "core directory exists" "test -d ./core" 0
run_test "modules directory exists" "test -d ./modules" 0
run_test "config directory exists" "test -d ./config" 0
run_test "tests directory exists" "test -d ./tests" 0

# Test core components
run_test "monitor.sh exists" "test -f ./core/system/monitor.sh" 0
run_test "monitor.sh is executable" "test -x ./core/system/monitor.sh" 0
run_test "queue.sh exists" "test -f ./core/tasks/queue.sh" 0
run_test "queue.sh is executable" "test -x ./core/tasks/queue.sh" 0
run_test "memory_utils.sh exists" "test -f ./core/memory/memory_utils.sh" 0
run_test "memory_utils.sh is executable" "test -x ./core/memory/memory_utils.sh" 0

# Test config files
run_test "system_config.json exists" "test -f ./config/system_config.json" 0
run_test "api_config.json exists" "test -f ./config/api_config.json" 0
run_test ".env.example exists" "test -f ./config/.env.example" 0

# Test module components
run_test "github_sponsors.sh exists" "test -f ./modules/funding/github_sponsors.sh" 0
run_test "github_sponsors.sh is executable" "test -x ./modules/funding/github_sponsors.sh" 0
run_test "kofi.sh exists" "test -f ./modules/funding/kofi.sh" 0
run_test "kofi.sh is executable" "test -x ./modules/funding/kofi.sh" 0
run_test "social_media.sh exists" "test -f ./modules/communication/social_media.sh" 0
run_test "social_media.sh is executable" "test -x ./modules/communication/social_media.sh" 0

# Print summary and exit with appropriate status
print_summary
exit $?