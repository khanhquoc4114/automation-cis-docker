#!/bin/bash

# Thay đổi thư mục làm việc thành thư mục chứa tập lệnh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "$SCRIPT_DIR" >/dev/null

# Lấy nguồn tệp cis_log.sh từ cùng thư mục
source "./cis_log.sh"

check_7_1() {
    local id="7.1"
    local desc="Ensure that the minimum number of manager nodes have been created in a swarm (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "docker info --format '{{ .Swarm.Managers }}'"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    # Self-contained command (Corrected PDF template)
    local manager_count=$(docker info --format '{{ .Swarm.Managers }}' 2>/dev/null)
    
    log_note "7.1 - Number of managers found: $manager_count"
    log_note "7.1 - Please manually verify this is the minimum odd number required for your fault tolerance."
}

check_7_2() {
    local id="7.2"
    local desc="Ensure that swarm services are bound to a specific host interface (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "ss -lp | grep -iE ':2377|:7946'"
    
    # Self-contained prerequisite check
    if ! command -v ss &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    # Self-contained command (using -lpn for numeric output, as implied by PDF)
    local listen_addrs=$(ss -lpn | grep -iE ':(2377|7946)' || true)
    
    if [ -z "$listen_addrs" ]; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    log_note "7.2 - Found listening services:"
    echo "$listen_addrs"
    
    if echo "$listen_addrs" | grep -qE '0\.0\.0\.0:|\*:'; then
        add_summary "$id" "$desc" "FAIL"
    else
        add_summary "$id" "$desc" "PASS"
    fi
    log_note "7.2 - Please manually verify the listening addresses above."
}

check_7_3() {
    local id="7.3"
    local desc="Ensure that all Docker swarm overlay networks are encrypted (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "docker network ls --filter driver=overlay --quiet | xargs docker network inspect --format '{{.Name}} {{ .Options }}'"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    # Self-contained command
    local overlay_networks=$(docker network ls --filter driver=overlay --quiet 2>/dev/null)
    
    if [ -z "$overlay_networks" ]; then
        add_summary "$id" "$desc" "PASS"
        return
    fi

    local all_encrypted=true
    
    # Loop through each network ID
    for net_id in $overlay_networks; do
        # Self-contained command inside loop
        local net_info=$(docker network inspect $net_id --format '{{.Name}} {{ .Options }}' 2>/dev/null)
        
        if ! echo "$net_info" | grep -q "encrypted:true"; then
            add_summary "$id" "$desc" "FAIL"
            all_encrypted=false
        else
            add_summary "$id" "$desc" "PASS"
        fi
    done
    
    if [ "$all_encrypted" = "true" ]; then
        add_summary "$id" "$desc" "PASS"
    fi
}

check_7_4() {
    local id="7.4"
    local desc="Ensure that Docker's secret management commands are used for managing secrets in a swarm cluster (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "docker secret ls"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    log_note "7.4 - Listing Docker secrets. Please verify this is in line with your security policy."
    
    # Self-contained command
    docker secret ls 2>/dev/null
}

check_7_5() {
    local id="7.5"
    local desc="Ensure that swarm manager is run in auto-lock mode (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "docker info --format '{{ .Swarm.Cluster.Spec.EncryptionConfig.AutoLockManagers }}'"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    # Self-contained command (Corrected PDF template)
    local autolock=$(docker info --format '{{ .Swarm.Cluster.Spec.EncryptionConfig.AutoLockManagers }}' 2>/dev/null)

    if [ "$autolock" = "true" ]; then
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
    fi
    log_note "7.5 - Please manually review if this setting is appropriate for your organization's policy."
}

check_7_6() {
    local id="7.6"
    local desc="Ensure that the swarm manager auto-lock key is rotated periodically (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "(No command available)"
    
    log_note "7.6 - This is a procedural check."
    log_note "7.6 - There is no mechanism to find out when the key was last rotated."
    log_note "7.6 - Please verify your organization's key rotation process."
}

check_7_7() {
    local id="7.7"
    local desc="Ensure that node certificates are rotated as appropriate (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "docker info --format '{{ .Swarm.Cluster.Spec.CAConfig.NodeCertExpiry }}'"

    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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

check_7_8() {
    local id="7.8"
    local desc="Ensure that CA certificates are rotated as appropriate (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "ls -l /var/lib/docker/swarm/certificates/swarm-root-ca.crt"
    
    local ca_cert_file="/var/lib/docker/swarm/certificates/swarm-root-ca.crt"
    
    if [ ! -f "$ca_cert_file" ]; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    # Self-contained command
    local file_stat=$(ls -l "$ca_cert_file" 2>/dev/null)
    
    log_note "7.8 - CA Certificate file details: $file_stat"
    log_note "7.8 - Please manually verify the file timestamp (Date) is in line with your rotation policy."
}

check_7_9() {
    local id="7.9"
    local desc="Ensure that management plane traffic is separated from data plane traffic (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "docker node inspect --format '{{ .Status.Addr }}' self"
    
    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    # Self-contained command
    local mgmt_addr=$(docker node inspect --format '{{ .Status.Addr }}' self 2>/dev/null)
    
    log_note "7.9 - The Management Plane Address (.Status.Addr) for this node is: $mgmt_addr"
    log_note "7.9 - Please manually verify this is on a different interface from your Data Plane."
}


main() {
    echo "================================================================="
    echo "  Running CIS Docker v1.8.0 - Section 7 Checks (Unaltered Mode) "
    echo "================================================================="
    
    local prereq_fail=false
    if ! command -v docker &> /dev/null; then
        log_fail "FATAL: 'docker' command not found. Please install Docker."
        prereq_fail=true
    fi
    
    if [ "$prereq_fail" = "true" ]; then
        echo "Exiting due to missing prerequisites."
        exit 1
    fi

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

    PASS_COUNT=0
    FAIL_COUNT=0
    INFO_COUNT=0
    log_info "7 - Docker Swarm Configuration"
    for entry in "${SUMMARY[@]}"; do
        IFS='|' read -r id title status detail <<< "$entry"
        
        msg="$id - $title"

        case "$status" in
            PASS)
                log_pass "$$msg" 
                ((PASS_COUNT++))
                ;;
            FAIL)
                log_fail "$$msg"
                ((FAIL_COUNT++))
                ;;
            INFO)
                log_info "$$msg"
                ((INFO_COUNT++))
                ;;
        esac
    done
    echo -e "${C_BLUE}===== SUMMARY REPORT =====${NC}"
    echo -e "${C_GREEN}PASS: $PASS_COUNT${NC}"
    echo -e "${C_RED}FAIL: $FAIL_COUNT${NC}"
    echo -e "${C_BLUE}INFO: $INFO_COUNT${NC}"
    echo -e "${YELLOW}TOTAL: $((PASS_COUNT + FAIL_COUNT + INFO_COUNT))${NC}"
    echo ""
    echo "=========================================="
    echo "Remediation script for Section 7 finished."
    echo "=========================================="
}

# Execute main function
main