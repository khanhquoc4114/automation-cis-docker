#!/bin/bash

# Thay đổi thư mục làm việc thành thư mục chứa tập lệnh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "$SCRIPT_DIR" >/dev/null

# Lấy nguồn tệp cis_log.sh từ cùng thư mục
source "./cis_log.sh"

check_6_1() {
    local id="6.1"
    local desc="Ensure that image sprawl is avoided (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "Step 1 (as per PDF): docker images --quiet | xargs docker inspect --format '{{ .Id }}: Image={{ index .RepoTags 0 }}'"
    log_cmd "Step 2 (as per PDF): docker images"

    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi

    # This is a Manual check. We will execute the exact (and distinct)
    # commands from the PDF's audit section.
    
    log_note "6.1 - This is a MANUAL check. Please compare the lists below as per the benchmark."
    
    echo ""
    log_note "6.1 - Audit Step 1 Output (List all Docker image IDs that are currently instantiated ):"
    # [cite_start]This is the exact command from Audit Step 1 [cite: 2548]
    docker images --quiet | xargs docker inspect --format '{{ .Id }}: Image={{ index .RepoTags 0 }}' 2>/dev/null
    
    echo ""
    log_note "6.1 - Audit Step 2 Output (List of all images present on system):"
    # [cite_start]This is the exact command from Audit Step 2 [cite: 2549]
    docker images
    
    echo ""
    log_note "6.1 - Please manually review these lists for unused or old images."
}

check_6_2() {
    local id="6.2"
    local desc="Ensure that container sprawl is avoided (Manual)"
    add_summary "$id" "$desc" "INFO"
    log_cmd "Step 1: docker info --format '{{ .Containers }}'"
    log_cmd "Step 2: docker info --format '{{ .ContainersStopped }}'"
    log_cmd "Step 2: docker info --format '{{ .ContainersRunning }}'"

    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi

    log_note "6.2 - This is a MANUAL check. Review the container counts below."

    # [cite_start]Self-contained command (Audit Step 1) [cite: 2572]
    local total_containers=$(docker info --format '{{ .Containers }}' 2>/dev/null)
    
    # [cite_start]Self-contained command (Audit Step 2) [cite: 2573]
    local stopped_containers=$(docker info --format '{{ .ContainersStopped }}' 2>/dev/null)
    
    # [cite_start]Self-contained command (Audit Step 2) [cite: 2573]
    local running_containers=$(docker info --format '{{ .ContainersRunning }}' 2>/dev/null)

    log_note "6.2 - Total Containers:   $total_containers"
    log_note "6.2 - Running Containers: $running_containers"
    log_note "6.2 - Stopped Containers: $stopped_containers"
    
    if [ "$stopped_containers" -gt "$running_containers" ] && [ "$stopped_containers" -gt 10 ]; then
         add_summary "$id" "$desc" "FAIL"
    else
         add_summary "$id" "$desc" "INFO"
    fi
}

main() {
    echo "================================================================="
    echo "  Running CIS Docker v1.8.0 - Section 6 Checks (Unaltered Mode) "
    echo "================================================================="
    
    # --- Prerequisite Checks (Run once in main for user feedback) ---
    # Individual checks will still perform their own check
    local prereq_fail=false
    if ! command -v docker &> /dev/null; then
        log_fail "FATAL: 'docker' command not found. Please install Docker."
        prereq_fail=true
    fi
    
    if [ "$prereq_fail" = "true" ]; then
        echo "Exiting due to missing prerequisites."
        exit 1
    fi
    
    # --- Run All Checks ---
    check_6_1
    echo "-------------------------------------------------------------------"
    check_6_2
    
    echo "================================================================="
    echo "                  Section 6 Checks Complete                    "
    echo "================================================================="

    PASS_COUNT=0
    FAIL_COUNT=0
    INFO_COUNT=0
    log_info "6 - Docker Security Operations"
    
    for entry in "${SUMMARY[@]}"; do
        IFS='|' read -r id title status detail <<< "$entry"
        
        msg="$id - $title"

        case "$status" in
            PASS)
                log_pass "$msg" 
                ((PASS_COUNT++))
                ;;
            FAIL)
                log_fail "$msg"
                ((FAIL_COUNT++))
                ;;
            INFO)
                log_info "$msg"
                ((INFO_COUNT++))
                ;;
        esac
    done
    echo -e "${BLUE}===== SUMMARY REPORT =====${NC}"
    echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
    echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
    echo -e "${BLUE}INFO: $INFO_COUNT${NC}"
    echo -e "${YELLOW}TOTAL: $((PASS_COUNT + FAIL_COUNT + INFO_COUNT))${NC}"
    echo ""
    echo "=========================================="
    echo "Remediation script for Section 6 finished."
    echo "=========================================="
}

# Execute main function
main