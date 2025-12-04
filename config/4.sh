#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cis_log.sh"

################################################################################
# 4.5 - Ensure Content trust for Docker is Enabled
################################################################################

remediate_4_5() {
    log_info "4.5 - Remediation: Enable Docker Content Trust"
    
    # Check if DOCKER_CONTENT_TRUST is already set
    if [ "${DOCKER_CONTENT_TRUST:-0}" = "1" ]; then
        log_pass "4.5 - Already compliant. DOCKER_CONTENT_TRUST is enabled."
        return
    fi
    
    # Add to /etc/environment for system-wide setting
    if ! grep -q "DOCKER_CONTENT_TRUST=1" /etc/environment 2>/dev/null; then
        echo "DOCKER_CONTENT_TRUST=1" >> /etc/environment
        log_remediate "4.5 - Added DOCKER_CONTENT_TRUST=1 to /etc/environment"
    fi
    
    # Add to /etc/profile.d for shell sessions
    if [ ! -f "/etc/profile.d/docker-content-trust.sh" ]; then
        echo 'export DOCKER_CONTENT_TRUST=1' > /etc/profile.d/docker-content-trust.sh
        chmod 644 /etc/profile.d/docker-content-trust.sh
        log_remediate "4.5 - Created /etc/profile.d/docker-content-trust.sh"
    fi
    
    # Export for current session
    export DOCKER_CONTENT_TRUST=1
    
    log_info "4.5 - Docker Content Trust enabled. Logout/login required for full effect."
    add_summary "4.5" "Docker Content Trust" "PASS"
}

main() {
    echo "=============================================="
    echo "CIS Docker Benchmark Section 4 Remediation"
    echo "Container Images and Build File Configuration"
    echo "=============================================="
    echo ""

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root or with sudo"
        exit 1
    fi

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi

    # Since all checks in Section 4 are manual, we just log their status as INFO.
    log_info "Running all checks for Section 4 (Manual Checks)..."
    add_summary "4.1" "Ensure that a user for the container has been created" "INFO"
    add_summary "4.2" "Ensure that containers use only trusted base images" "INFO"
    add_summary "4.3" "Ensure that unnecessary packages are not installed in the container" "INFO"
    add_summary "4.4" "Ensure images are scanned and rebuilt to include security patches" "INFO"
    add_summary "4.6" "Ensure that HEALTHCHECK instructions have been added to container images" "INFO"
    add_summary "4.7" "Ensure update instructions are not used alone in Dockerfiles" "INFO"
    add_summary "4.9" "Ensure that COPY is used instead of ADD in Dockerfiles" "INFO"
    add_summary "4.10" "Ensure secrets are not stored in Dockerfiles" "INFO"
    add_summary "4.12" "Ensure all signed artifacts are validated" "INFO"
    
    INFO_COUNT=0
    log_info "4 - Container Images and Build File Configuration"
    for entry in "${SUMMARY[@]}"; do
        IFS='|' read -r id title status detail <<< "$entry"
        
        msg="$id - $title"

        case "$status" in
            INFO)
                log_info "$msg" 
                ((INFO_COUNT++))
                ;;
        esac
    done
    echo -e "${C_BLUE}===== SUMMARY REPORT =====${NC}"
    echo -e "${C_BLUE}INFO: $INFO_COUNT${NC}"
    echo -e "${C_YELLOW}TOTAL: $((INFO_COUNT))${NC}"
    echo ""
    echo "=========================================="
    echo "Remediation script for Section 4 finished."
    echo "=========================================="
}

# Chỉ chạy main khi file được thực thi trực tiếp, không phải khi được source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
