#!/bin/bash

# This script runs all the CIS benchmark tests and provides a final summary.

# Ensure we are in the script's directory
cd "$(dirname "${BASH_SOURCE[0]}")" || exit

# Initialize total counters
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_INFO=0

# Array of test scripts to run
TEST_SCRIPTS=(
    "1.sh"
    "2.sh"
    "3.sh"
    "4.sh"
    "5.sh"
    "6.sh"
    "7.sh"
)

# --- Main Execution ---
echo "================================================================="
echo "          Running All CIS Docker Benchmark Tests             "
echo "================================================================="
echo ""

# Loop through and execute each test script
for script in "${TEST_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        
        # Execute the script, display output, and capture to a temporary file for summary parsing
        temp_output_file=$(mktemp)
        bash "$script" | tee "$temp_output_file"
        
        # Parse the summary from the temporary file
        pass_count=$(grep -o 'PASS: [0-9]*' "$temp_output_file" | tail -n 1 | awk '{print $2}')
        fail_count=$(grep -o 'FAIL: [0-9]*' "$temp_output_file" | tail -n 1 | awk '{print $2}')
        info_count=$(grep -o 'INFO: [0-9]*' "$temp_output_file" | tail -n 1 | awk '{print $2}')
        
        # Clean up the temporary file
        rm "$temp_output_file"
        
        # Add to totals, defaulting to 0 if not found
        TOTAL_PASS=$((TOTAL_PASS + ${pass_count:-0}))
        TOTAL_FAIL=$((TOTAL_FAIL + ${fail_count:-0}))
        TOTAL_INFO=$((TOTAL_INFO + ${info_count:-0}))
        
        echo ""
    else
        echo "WARNING: Test script not found: $script"
    fi
done

# --- Grand Total Summary ---
# Using the same color codes as cis_log.sh for consistency
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================================="
echo "                GRAND TOTAL SUMMARY OF ALL TESTS                 "
echo "================================================================="
echo -e "${GREEN}TOTAL PASS: $TOTAL_PASS${NC}"
echo -e "${RED}TOTAL FAIL: $TOTAL_FAIL${NC}"
echo -e "${BLUE}TOTAL INFO: $TOTAL_INFO${NC}"
TOTAL_TESTS=$((TOTAL_PASS + TOTAL_FAIL + TOTAL_INFO))
echo -e "${YELLOW}GRAND TOTAL: $TOTAL_TESTS${NC}"
echo "================================================================="