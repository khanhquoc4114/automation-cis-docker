#!/bin/bash

# --- Colors (Formatting Only) ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # No Color

# --- Log Functions (Formatting Only) ---
log_pass() {
    echo -e " ${C_GREEN}[PASS]${C_NC} $1"
}
log_warn() {
    echo -e " ${C_YELLOW}[WARN]${C_NC} $1"
}
log_info() {
    echo -e "${C_BLUE}[INFO]${C_NC} $1"
}
log_note() {
    # Used for Manual checks that require user verification
    echo -e " ${C_BLUE}[NOTE]${C_NC} $1"
}
log_fail() {
    echo -e " ${C_RED}[FAIL]${C_NC} $1"
}
log_cmd() {
    echo -e " ${C_BLUE}Audit:${C_NC} $1"
}
