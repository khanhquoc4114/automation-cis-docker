#!/bin/bash

USE_COLOR=1
if [ -n "$FORCE_COLOR" ]; then
  USE_COLOR=1
elif [ ! -t 1 ] || [ -n "$NO_COLOR" ]; then
  USE_COLOR=0
fi

if [ "$USE_COLOR" -eq 0 ]; then
  C_RED='' ; C_GREEN='' ; C_YELLOW='' ; C_BLUE='' ; C_NC=''
else
  C_RED='\033[0;31m'
  C_GREEN='\033[0;32m'
  C_YELLOW='\033[0;33m'
  C_BLUE='\033[0;34m'
  C_NC='\033[0m'
fi

# --- Log Functions (Formatting Only) ---
log_pass() {
    echo -e "${C_GREEN}[PASS]${C_NC} $1"
}
log_warn() {
    echo -e "${C_YELLOW}[WARN]${C_NC} $1"
}
log_info() {
    echo -e "${C_BLUE}[INFO]${C_NC} $1"
}
log_note() {
    echo -e "${C_BLUE}[NOTE]${C_NC} $1"
}
log_fail() {
    echo -e "${C_RED}[FAIL]${C_NC} $1"
}
log_cmd() {
    echo -e " ${C_BLUE}Audit:${C_NC} $1"
}

declare -a REMEDIATION_SUMMARY=()

# Files to store failed tests and remediation commands
FAILED_TESTS_LOG="${FAILED_TESTS_LOG:-/tmp/cis_failed_tests_$$.log}"
REMEDIATION_LOG="${REMEDIATION_LOG:-/tmp/cis_remediation_$$.log}"

add_summary() {
    local id="$1"
    local title="$2"
    local status="$3"

    SUMMARY+=("$id|$title|$status")

    # If FAIL, log to failed tests file
    if [ "$status" = "FAIL" ]; then
        echo "$id|$title" >> "$FAILED_TESTS_LOG"
    fi
}

# Add remediation command for a failed test
add_remediation() {
    local id="$1"
    local remediation="$2"

    # Use delimiter that won't appear in commands
    echo "===START_REMEDIATION:${id}===" >> "$REMEDIATION_LOG"
    echo "$remediation" >> "$REMEDIATION_LOG"
    echo "===END_REMEDIATION:${id}===" >> "$REMEDIATION_LOG"
}
