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
    echo -e " ${C_BLUE}[NOTE]${C_NC} $1"
}
log_fail() {
    echo -e " ${C_RED}[FAIL]${C_NC} $1"
}
log_cmd() {
    echo -e "        ${C_BLUE}Audit:${C_NC} $1"
}

# --- Check 7.1 ---
check_7_1() {
    log_info "7.1 - Ensure that the minimum number of manager nodes have been created in a swarm (Manual)"
    log_cmd "docker info --format '{{ .Swarm.Managers }}'"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        log_fail "7.1 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    # Self-contained command (Corrected PDF template)
    local manager_count=$(docker info --format '{{ .Swarm.Managers }}' 2>/dev/null)
    
    log_note "7.1 - Number of managers found: $manager_count"
    log_note "7.1 - Please manually verify this is the minimum odd number required for your fault tolerance."
}

# --- Check 7.2 ---
check_7_2() {
    log_info "7.2 - Ensure that swarm services are bound to a specific host interface (Manual)"
    log_cmd "ss -lp | grep -iE ':2377|:7946'"
    
    # Self-contained prerequisite check
    if ! command -v ss &> /dev/null; then
        log_fail "7.2 - COMMAND NOT FOUND: 'ss' is not installed."
        return
    fi
    
    # Self-contained command (using -lpn for numeric output, as implied by PDF)
    local listen_addrs=$(ss -lpn | grep -iE ':(2377|7946)' || true)
    
    if [ -z "$listen_addrs" ]; then
        log_warn "7.2 - Could not find listeners on port 2377 or 7946."
        return
    fi
    
    log_note "7.2 - Found listening services:"
    echo "$listen_addrs"
    
    if echo "$listen_addrs" | grep -qE '0\.0\.0\.0:|\*:'; then
        log_warn "7.2 - Swarm services are listening on all interfaces (0.0.0.0 or *)."
    else
        log_pass "7.2 - Swarm services appear to be bound to specific interfaces."
    fi
    log_note "7.2 - Please manually verify the listening addresses above."
}

# --- Check 7.3 ---
check_7_3() {
    log_info "7.3 - Ensure that all Docker swarm overlay networks are encrypted (Manual)"
    log_cmd "docker network ls --filter driver=overlay --quiet | xargs docker network inspect --format '{{.Name}} {{ .Options }}'"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        log_fail "7.3 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    # Self-contained command
    local overlay_networks=$(docker network ls --filter driver=overlay --quiet 2>/dev/null)
    
    if [ -z "$overlay_networks" ]; then
        log_pass "7.3 - No overlay networks found."
        return
    fi

    local all_encrypted=true
    
    # Loop through each network ID
    for net_id in $overlay_networks; do
        # Self-contained command inside loop
        local net_info=$(docker network inspect $net_id --format '{{.Name}} {{ .Options }}' 2>/dev/null)
        
        if ! echo "$net_info" | grep -q "encrypted:true"; then
            log_warn "7.3 - Network '$net_id' (Name: $(echo $net_info | awk '{print $1}')) is NOT encrypted."
            all_encrypted=false
        else
            log_pass "7.3 - Network '$net_id' (Name: $(echo $net_info | awk '{print $1}')) is encrypted."
        fi
    done
    
    if [ "$all_encrypted" = "true" ]; then
        log_pass "7.3 - All overlay networks found are encrypted."
    fi
}

# --- Check 7.4 ---
check_7_4() {
    log_info "7.4 - Ensure that Docker's secret management commands are used for managing secrets in a swarm cluster (Manual)"
    log_cmd "docker secret ls"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        log_fail "7.4 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    log_note "7.4 - Listing Docker secrets. Please verify this is in line with your security policy."
    
    # Self-contained command
    docker secret ls 2>/dev/null
}

# --- Check 7.5 ---
check_7_5() {
    log_info "7.5 - Ensure that swarm manager is run in auto-lock mode (Manual)"
    log_cmd "docker info --format '{{ .Swarm.Cluster.Spec.EncryptionConfig.AutoLockManagers }}'"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        log_fail "7.5 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    # Self-contained command (Corrected PDF template)
    local autolock=$(docker info --format '{{ .Swarm.Cluster.Spec.EncryptionConfig.AutoLockManagers }}' 2>/dev/null)

    if [ "$autolock" = "true" ]; then
        log_pass "7.5 - Swarm auto-lock is enabled."
    else
        log_warn "7.5 - Swarm auto-lock is disabled (Default)."
    fi
    log_note "7.5 - Please manually review if this setting is appropriate for your organization's policy."
}

# --- Check 7.6 ---
check_7_6() {
    log_info "7.6 - Ensure that the swarm manager auto-lock key is rotated periodically (Manual)"
    log_cmd "(No command available)"
    
    log_note "7.6 - This is a procedural check."
    log_note "7.6 - There is no mechanism to find out when the key was last rotated."
    log_note "7.6 - Please verify your organization's key rotation process."
}

# --- Check 7.7 ---
check_7_7() {
    log_info "7.7 - Ensure that node certificates are rotated as appropriate (Manual)"
    log_cmd "docker info --format '{{ .Swarm.Cluster.Spec.CAConfig.NodeCertExpiry }}'"

    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        log_fail "7.7 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    # Self-contained command
    local expiry_duration=$(docker info --format '{{ .Swarm.Cluster.Spec.CAConfig.NodeCertExpiry }}' 2>/dev/null)
    
    log_note "7.7 - Node certificate expiry duration (NodeCertExpiry) is: $expiry_duration"
    
    if [ "$expiry_duration" = "2160h0m0s" ]; then
         log_note "7.7 - This is the default of 90 days."
    fi
    
    log_note "7.7 - Please manually verify this rotation period is appropriate for your environment."
}

# --- Check 7.8 ---
check_7_8() {
    log_info "7.8 - Ensure that CA certificates are rotated as appropriate (Manual)"
    log_cmd "ls -l /var/lib/docker/swarm/certificates/swarm-root-ca.crt"
    
    local ca_cert_file="/var/lib/docker/swarm/certificates/swarm-root-ca.crt"
    
    if [ ! -f "$ca_cert_file" ]; then
        log_warn "7.8 - CA certificate file not found at $ca_cert_file"
        return
    fi
    
    # Self-contained command
    local file_stat=$(ls -l "$ca_cert_file" 2>/dev/null)
    
    log_note "7.8 - CA Certificate file details: $file_stat"
    log_note "7.8 - Please manually verify the file timestamp (Date) is in line with your rotation policy."
}

# --- Check 7.9 ---
check_7_9() {
    log_info "7.9 - Ensure that management plane traffic is separated from data plane traffic (Manual)"
    log_cmd "docker node inspect --format '{{ .Status.Addr }}' self"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        log_fail "7.9 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    # Self-contained command
    local mgmt_addr=$(docker node inspect --format '{{ .Status.Addr }}' self 2>/dev/null)
    
    log_note "7.9 - The Management Plane Address (.Status.Addr) for this node is: $mgmt_addr"
    log_note "7.9 - Please manually verify this is on a different interface from your Data Plane."
}


# --- Main Function ---
main() {
    echo "================================================================="
    echo "  Running CIS Docker v1.8.0 - Section 7 Checks (Unaltered Mode) "
    echo "================================================================="
    
    # --- Prerequisite Checks (Run once in main for user feedback) ---
    local prereq_fail=false
    if ! command -v docker &> /dev/null; then
        log_fail "FATAL: 'docker' command not found. Please install Docker."
        prereq_fail=true
    fi
    
    if [ "$prereq_fail" = "true" ]; then
        echo "Exiting due to missing prerequisites."
        exit 1
    fi

    # --- Swarm Active Check ---
    # Check if swarm is active before running any tests
    local swarm_status=$(docker info --format '{{ .Swarm.LocalNodeState }}' 2>/dev/null)
    
    if [ "$swarm_status" != "active" ]; then
        log_warn "Docker Swarm is not active on this node (State: $swarm_status)."
        log_warn "Skipping all Section 7 checks."
        echo "================================================================="
        echo "             Section 7 Checks Skipped (Swarm Inactive)         "
        echo "================================================================="
        exit 0
    else
        log_pass "Docker Swarm is active. Proceeding with Section 7 checks."
        echo "---"
    fi
    
    # --- Run All Checks ---
    check_7_1
    echo "---"
    check_7_2
    echo "---"
    check_7_3
    echo "---"
    check_7_4
    echo "---"
    check_7_5
    echo "---"
    check_7_6
    echo "---"
    check_7_7
    echo "---"
    check_7_8
    echo "---"
    check_7_9
    
    echo "================================================================="
    echo "                  Section 7 Checks Complete                    "
    echo "================================================================="
}

# Execute main function
main