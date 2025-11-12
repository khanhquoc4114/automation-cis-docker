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
    echo -e "        ${C_BLUE}Audit:${C_NC} $1"
}

# --- Check 6.1 ---
check_6_1() {
    log_info "6.1 - Ensure that image sprawl is avoided (Manual)"
    log_cmd "Step 1 (as per PDF): docker images --quiet | xargs docker inspect --format '{{ .Id }}: Image={{ index .RepoTags 0 }}'"
    log_cmd "Step 2 (as per PDF): docker images"

    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        log_fail "6.1 - COMMAND NOT FOUND: 'docker' is not installed."
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

# --- Check 6.2 ---
check_6_2() {
    log_info "6.2 - Ensure that container sprawl is avoided (Manual)"
    log_cmd "Step 1: docker info --format '{{ .Containers }}'"
    log_cmd "Step 2: docker info --format '{{ .ContainersStopped }}'"
    log_cmd "Step 2: docker info --format '{{ .ContainersRunning }}'"

    # Self-contained prerequisite check
    if ! command -v docker &> /dev/null; then
        log_fail "6.2 - COMMAND NOT FOUND: 'docker' is not installed."
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
         log_warn "6.2 - There is a high number of stopped containers. Please review manually."
    else
         log_note "6.2 - Please manually review if the number of stopped containers is excessive for your environment."
    fi
}

# --- Main Function ---
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
}

# Execute main function
main