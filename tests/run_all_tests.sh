#!/bin/bash

# This script runs all the CIS benchmark tests and provides a final summary.

# Ensure we are in the script's directory
cd "$(dirname "${BASH_SOURCE[0]}")" || exit

# Create log files and export for subprocesses
export FAILED_TESTS_LOG=$(mktemp)
export REMEDIATION_LOG=$(mktemp)

source "./cis_log.sh"

# Force color output even when piping to tee
export FORCE_COLOR=1

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

echo "================================================================="
echo "                GRAND TOTAL SUMMARY OF ALL TESTS                 "
echo "================================================================="
echo -e "${C_GREEN}TOTAL PASS: $TOTAL_PASS${C_NC}"
echo -e "${C_RED}TOTAL FAIL: $TOTAL_FAIL${C_NC}"
echo -e "${C_BLUE}TOTAL INFO: $TOTAL_INFO${C_NC}"
TOTAL_TESTS=$((TOTAL_PASS + TOTAL_FAIL + TOTAL_INFO))
echo -e "${C_YELLOW}GRAND TOTAL: $TOTAL_TESTS${C_NC}"
echo "================================================================="

# --- Failed Tests and Remediation Summary ---
if [ "$TOTAL_FAIL" -gt 0 ] && [ -f "$FAILED_TESTS_LOG" ]; then
    echo ""
    echo "================================================================="
    echo "           FAILED TESTS AND REMEDIATION GUIDE                "
    echo "================================================================="
    echo ""

    # Build associative array from remediation log
    declare -A REMEDIATION_MAP
    if [ -f "$REMEDIATION_LOG" ]; then
        current_id=""
        current_remediation=""
        while IFS= read -r line; do
            if [[ "$line" =~ ===START_REMEDIATION:([^=]+)=== ]]; then
                current_id="${BASH_REMATCH[1]}"
                current_remediation=""
            elif [[ "$line" =~ ===END_REMEDIATION:([^=]+)=== ]]; then
                if [ -n "$current_id" ]; then
                    REMEDIATION_MAP["$current_id"]="$current_remediation"
                fi
                current_id=""
                current_remediation=""
            elif [ -n "$current_id" ]; then
                if [ -z "$current_remediation" ]; then
                    current_remediation="$line"
                else
                    current_remediation="${current_remediation}
${line}"
                fi
            fi
        done < "$REMEDIATION_LOG"
    fi

    # Read failed tests from log file and display with remediation
    declare -A displayed_tests
    while IFS='|' read -r test_id title; do
        # Skip if already displayed (avoid duplicates)
        if [ -n "${displayed_tests[$test_id]}" ]; then
            continue
        fi
        displayed_tests[$test_id]=1

        echo -e "${C_RED}✗ ${test_id}${C_NC} - ${title}"

        # Get remediation from map
        if [ -n "${REMEDIATION_MAP[$test_id]}" ]; then
            echo -e "${C_YELLOW}→ Cách fix:${C_NC}"
            # Print each line of remediation with indentation
            while IFS= read -r line; do
                if [[ "$line" == *"⚠️"* || "$line" == *"CẢNH BÁO"* ]]; then
                    echo -e "  ${C_RED}${line}${C_NC}"
                elif [[ "$line" == \#* ]]; then
                    echo -e "  ${C_BLUE}${line}${C_NC}"
                else
                    echo -e "  ${line}"
                fi
            done <<< "${REMEDIATION_MAP[$test_id]}"
        else
            echo -e "${C_YELLOW}→ Chưa có hướng dẫn fix cho test này${C_NC}"
        fi
        echo ""
    done < "$FAILED_TESTS_LOG"

    echo "================================================================="
fi

# Clean up
rm -f "$FAILED_TESTS_LOG" "$REMEDIATION_LOG"