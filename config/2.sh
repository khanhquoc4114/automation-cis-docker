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
log_fail() {
    echo -e " ${C_RED}[FAIL]${C_NC} $1"
}
log_remediate() {
    echo -e " ${C_GREEN}[REMEDIATE]${C_NC} $1"
}

# --- Check 2.2 Remediation ---
remediate_2_2() {
    log_info "2.2 - Remediation: Set 'icc' to false"
    
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.2 - FAILED: 'jq' command not found. Cannot remediate."
        return
    fi
    
    [ ! -f "$DAEMON_JSON_FILE" ] && echo "{}" > "$DAEMON_JSON_FILE"
    
    local current_val=$(jq -r '."icc"' "$DAEMON_JSON_FILE" 2>/dev/null)
    
    if [ "$current_val" = "false" ]; then
        log_pass "2.2 - Already compliant. 'icc' is 'false'."
        return
    fi
    
    if jq '.icc = false' "$DAEMON_JSON_FILE" > "$DAEMON_JSON_FILE.tmp"; then
        mv "$DAEMON_JSON_FILE.tmp" "$DAEMON_JSON_FILE"
        chown root:root "$DAEMON_JSON_FILE"
        chmod 644 "$DAEMON_JSON_FILE"
        log_remediate "2.2 - Set 'icc' to false in $DAEMON_JSON_FILE"
    else
        log_fail "2.2 - FAILED: 'jq' command failed to update $DAEMON_JSON_FILE"
        rm -f "$DAEMON_JSON_FILE.tmp"
    fi
}

# --- Check 2.3 Remediation ---
remediate_2_3() {
    log_info "2.3 - Remediation: Set 'log-level' to 'info'"
    
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.3 - FAILED: 'jq' command not found. Cannot remediate."
        return
    fi
    
    [ ! -f "$DAEMON_JSON_FILE" ] && echo "{}" > "$DAEMON_JSON_FILE"
    
    local current_val=$(jq -r '."log-level"' "$DAEMON_JSON_FILE" 2>/dev/null)
    
    if [ "$current_val" = "info" ]; then
        log_pass "2.3 - Already compliant. 'log-level' is 'info'."
        return
    fi
    
    if jq '."log-level" = "info"' "$DAEMON_JSON_FILE" > "$DAEMON_JSON_FILE.tmp"; then
        mv "$DAEMON_JSON_FILE.tmp" "$DAEMON_JSON_FILE"
        chown root:root "$DAEMON_JSON_FILE"
        chmod 644 "$DAEMON_JSON_FILE"
        log_remediate "2.3 - Set 'log-level' to 'info' in $DAEMON_JSON_FILE"
    else
        log_fail "2.3 - FAILED: 'jq' command failed to update $DAEMON_JSON_FILE"
        rm -f "$DAEMON_JSON_FILE.tmp"
    fi
}

# --- Check 2.4 Remediation ---
remediate_2_4() {
    log_info "2.4 - Remediation: Ensure 'iptables' is not set to 'false'"
    
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.4 - FAILED: 'jq' command not found. Cannot remediate."
        return
    fi
    
    [ ! -f "$DAEMON_JSON_FILE" ] && echo "{}" > "$DAEMON_JSON_FILE"
    
    local current_val=$(jq -r '."iptables"' "$DAEMON_JSON_FILE" 2>/dev/null)
    
    if [ "$current_val" != "false" ]; then
        log_pass "2.4 - Already compliant. 'iptables' is not 'false' (defaults to true)."
        return
    fi
    
    if jq 'del(."iptables")' "$DAEMON_JSON_FILE" > "$DAEMON_JSON_FILE.tmp"; then
        mv "$DAEMON_JSON_FILE.tmp" "$DAEMON_JSON_FILE"
        chown root:root "$DAEMON_JSON_FILE"
        chmod 644 "$DAEMON_JSON_FILE"
        log_remediate "2.4 - Removed 'iptables: false' from $DAEMON_JSON_FILE to revert to default (true)."
    else
        log_fail "2.4 - FAILED: 'jq' command failed to update $DAEMON_JSON_FILE"
        rm -f "$DAEMON_JSON_FILE.tmp"
    fi
}

# --- Check 2.15 Remediation ---
remediate_2_15() {
    log_info "2.15 - Remediation: Set 'no-new-privileges' to true"
    
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.15 - FAILED: 'jq' command not found. Cannot remediate."
        return
    fi
    
    [ ! -f "$DAEMON_JSON_FILE" ] && echo "{}" > "$DAEMON_JSON_FILE"
    
    local current_val=$(jq -r '."no-new-privileges"' "$DAEMON_JSON_FILE" 2>/dev/null)
    
    if [ "$current_val" = "true" ]; then
        log_pass "2.15 - Already compliant. 'no-new-privileges' is 'true'."
        return
    fi
    
    if jq '."no-new-privileges" = true' "$DAEMON_JSON_FILE" > "$DAEMON_JSON_FILE.tmp"; then
        mv "$DAEMON_JSON_FILE.tmp" "$DAEMON_JSON_FILE"
        chown root:root "$DAEMON_JSON_FILE"
        chmod 644 "$DAEMON_JSON_FILE"
        log_remediate "2.15 - Set 'no-new-privileges' to true in $DAEMON_JSON_FILE"
    else
        log_fail "2.15 - FAILED: 'jq' command failed to update $DAEMON_JSON_FILE"
        rm -f "$DAEMON_JSON_FILE.tmp"
    fi
}

# --- Check 2.16 Remediation ---
remediate_2_16() {
    log_info "2.16 - Remediation: Set 'live-restore' to true"
    
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.16 - FAILED: 'jq' command not found. Cannot remediate."
        return
    fi
    
    [ ! -f "$DAEMON_JSON_FILE" ] && echo "{}" > "$DAEMON_JSON_FILE"
    
    local current_val=$(jq -r '."live-restore"' "$DAEMON_JSON_FILE" 2>/dev/null)
    
    if [ "$current_val" = "true" ]; then
        log_pass "2.16 - Already compliant. 'live-restore' is 'true'."
        return
    fi
    
    if jq '."live-restore" = true' "$DAEMON_JSON_FILE" > "$DAEMON_JSON_FILE.tmp"; then
        mv "$DAEMON_JSON_FILE.tmp" "$DAEMON_JSON_FILE"
        chown root:root "$DAEMON_JSON_FILE"
        chmod 644 "$DAEMON_JSON_FILE"
        log_remediate "2.16 - Set 'live-restore' to true in $DAEMON_JSON_FILE"
    else
        log_fail "2.16 - FAILED: 'jq' command failed to update $DAEMON_JSON_FILE"
        rm -f "$DAEMON_JSON_FILE.tmp"
    fi
}

# --- Check 2.17 Remediation ---
remediate_2_17() {
    log_info "2.17 - Remediation: Set 'userland-proxy' to false"
    
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.17 - FAILED: 'jq' command not found. Cannot remediate."
        return
    fi
    
    [ ! -f "$DAEMON_JSON_FILE" ] && echo "{}" > "$DAEMON_JSON_FILE"
    
    local current_val=$(jq -r '."userland-proxy"' "$DAEMON_JSON_FILE" 2>/dev/null)
    
    if [ "$current_val" = "false" ]; then
        log_pass "2.17 - Already compliant. 'userland-proxy' is 'false'."
        return
    fi
    
    if jq '."userland-proxy" = false' "$DAEMON_JSON_FILE" > "$DAEMON_JSON_FILE.tmp"; then
        mv "$DAEMON_JSON_FILE.tmp" "$DAEMON_JSON_FILE"
        chown root:root "$DAEMON_JSON_FILE"
        chmod 644 "$DAEMON_JSON_FILE"
        log_remediate "2.17 - Set 'userland-proxy' to false in $DAEMON_JSON_FILE"
    else
        log_fail "2.17 - FAILED: 'jq' command failed to update $DAEMON_JSON_FILE"
        rm -f "$DAEMON_JSON_FILE.tmp"
    fi
}

# --- Check 2.18 Remediation ---
remediate_2_18() {
    log_info "2.18 - Remediation: Revert 'seccomp-profile' to default"
    
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.18 - FAILED: 'jq' command not found. Cannot remediate."
        return
    fi
    
    [ ! -f "$DAEMON_JSON_FILE" ] && echo "{}" > "$DAEMON_JSON_FILE"
    
    local current_val=$(jq -r '."seccomp-profile"' "$DAEMON_JSON_FILE" 2>/dev/null)
    
    if [ "$current_val" = "null" ]; then
        log_pass "2.18 - Already compliant. 'seccomp-profile' is not set (using default)."
        return
    fi
    
    if jq 'del(."seccomp-profile")' "$DAEMON_JSON_FILE" > "$DAEMON_JSON_FILE.tmp"; then
        mv "$DAEMON_JSON_FILE.tmp" "$DAEMON_JSON_FILE"
        chown root:root "$DAEMON_JSON_FILE"
        chmod 644 "$DAEMON_JSON_FILE"
        log_remediate "2.18 - Removed custom 'seccomp-profile' from $DAEMON_JSON_FILE to revert to default."
    else
        log_fail "2.18 - FAILED: 'jq' command failed to update $DAEMON_JSON_FILE"
        rm -f "$DAEMON_JSON_FILE.tmp"
    fi
}

# --- Check 2.19 Remediation ---
remediate_2_19() {
    log_info "2.19 - Remediation: Set 'experimental' to false"
    
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.19 - FAILED: 'jq' command not found. Cannot remediate."
        return
    fi
    
    [ ! -f "$DAEMON_JSON_FILE" ] && echo "{}" > "$DAEMON_JSON_FILE"
    
    local current_val=$(jq -r '."experimental"' "$DAEMON_JSON_FILE" 2>/dev/null)
    
    if [ "$current_val" = "false" ]; then
        log_pass "2.19 - Already compliant. 'experimental' is 'false'."
        return
    fi
    
    if jq '."experimental" = false' "$DAEMON_JSON_FILE" > "$DAEMON_JSON_FILE.tmp"; then
        mv "$DAEMON_JSON_FILE.tmp" "$DAEMON_JSON_FILE"
        chown root:root "$DAEMON_JSON_FILE"
        chmod 644 "$DAEMON_JSON_FILE"
        log_remediate "2.19 - Set 'experimental' to false in $DAEMON_JSON_FILE"
    else
        log_fail "2.19 - FAILED: 'jq' command failed to update $DAEMON_JSON_FILE"
        rm -f "$DAEMON_JSON_FILE.tmp"
    fi
}


# --- Main Function ---
main() {    
    if [ "$(id -u)" -ne 0 ]; then
      log_fail "FATAL: This script must be run as root to modify $DAEMON_JSON_FILE"
      exit 1
    fi
    
    local prereq_fail=false
    if ! command -v docker &> /dev/null; then
        log_fail "FATAL: 'docker' command not found. Please install Docker."
        prereq_fail=true
    fi
    if ! command -v jq &> /dev/null; then
        log_fail "FATAL: 'jq' command not found. Please install 'jq' to modify JSON files."
        prereq_fail=true
    fi
    
    if [ "$prereq_fail" = "true" ]; then
        echo "Exiting due to missing prerequisites."
        exit 1
    fi
    
    remediate_2_2
    echo "---"
    remediate_2_3
    echo "---"
    remediate_2_4
    echo "---"
    remediate_2_15
    echo "---"
    remediate_2_16
    echo "---"
    remediate_2_17
    echo "---"
    remediate_2_18
    echo "---"
    remediate_2_19
}

main