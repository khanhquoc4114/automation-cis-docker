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
log_cmd() {
    echo -e "        ${C_BLUE}Audit:${C_NC} $1"
}

# --- Check 7.7 Remediation ---
remediate_7_7() {
    log_info "7.7 - Remediation: Ensure node certificates are rotated as appropriate (Manual)"
    
    local TARGET_EXPIRY="720h0m0s"
    
    if ! command -v docker &> /dev/null; then
        log_fail "7.7 - FAILED: 'docker' command not found. Cannot remediate."
        return
    fi
    
    log_cmd "docker info --format '{{ .Swarm.Cluster.Spec.CAConfig.NodeCertExpiry }}'"
    
    local current_expiry=$(docker info --format '{{ .Swarm.Cluster.Spec.CAConfig.NodeCertExpiry }}' 2>/dev/null)
    
    if [ "$current_expiry" = "$TARGET_EXPIRY" ]; then
        log_pass "7.7 - Already compliant. 'NodeCertExpiry' is '$TARGET_EXPIRY'."
        return
    fi
    
    log_warn "7.7 - 'NodeCertExpiry' is '$current_expiry', not '$TARGET_EXPIRY'. Attempting remediation."
    
    if docker swarm update --cert-expiry "${TARGET_EXPIRY%0m0s}" > /dev/null 2>&1; then
        log_remediate "7.7 - Set 'NodeCertExpiry' to '${TARGET_EXPIRY%0m0s}'."
    else
        log_fail "7.7 - FAILED: 'docker swarm update' command failed."
    fi
}


main() {
    if [ "$(id -u)" -ne 0 ]; then
      log_fail "FATAL: This script must be run as root to modify Swarm settings."
      exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_fail "FATAL: 'docker' command not found. Please install Docker."
        exit 1
    fi

    local swarm_status=$(docker info --format '{{ .Swarm.LocalNodeState }}' 2>/dev/null)
    
    if [ "$swarm_status" != "active" ]; then
        log_warn "Docker Swarm is not active on this node (State: $swarm_status)."
        log_warn "Skipping all Section 7 remediation."
        echo "================================================================="
        echo "           Section 7 Remediation Skipped (Swarm Inactive)      "
        echo "================================================================="
        exit 0
    else
        log_pass "Docker Swarm is active. Proceeding with Section 7.7 remediation."
        echo "---"
    fi
    remediate_7_7
}

main