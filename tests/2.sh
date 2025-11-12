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

# --- Check 2.1 ---
check_2_1() {
    log_info "2.1 - Run the Docker daemon as a non-root user, if possible (Manual)"
    log_cmd "ps -fe | grep 'dockerd'"
    
    # Self-contained command
    local DOCKER_CMD_LINE=$(ps -fe | grep 'dockerd' | grep -v 'grep' || true)

    if [ -z "$DOCKER_CMD_LINE" ]; then
        log_fail "2.1 - NOT FOUND: No 'dockerd' process is running."
        return
    fi

    local user=$(echo "$DOCKER_CMD_LINE" | awk '{print $1}')

    if [ "$user" = "root" ]; then
        log_note "2.1 - Docker daemon is running as 'root'."
        log_note "     (This is the default. CIS recommends rootless mode if possible. Please verify manually.)"
    else
        log_pass "2.1 - Docker daemon is running as non-root user: '$user'."
    fi
}

# --- Check 2.2 ---
check_2_2() {
    log_info "2.2 - Ensure network traffic is restricted between containers on the default bridge (Manual)"
    log_cmd "docker network ls --quiet | xargs docker network inspect --format '{{.Name }}: {{ .Options }}'"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.2 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    # Self-contained command
    local icc_setting=$(docker network ls --quiet | xargs docker network inspect --format '{{.Name }}: {{ .Options }}' 2>/dev/null | grep '^bridge:')

    if echo "$icc_setting" | grep -q "com.docker.network.bridge.enable_icc:false"; then
        log_pass "2.2 - Inter-container communication (icc=false) is restricted on the default bridge."
    else
        log_warn "2.2 - Inter-container communication (icc) is allowed on the default bridge (Default)."
    fi
}

# --- Check 2.3 ---
check_2_3() {
    log_info "2.3 - Ensure the logging level is set to 'info' (Manual)"
    log_cmd "Check dockerd process flags and /etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.3 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi

    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)

    local json_log_level="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_log_level=$(jq -r '."log-level"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi
    
    local cmd_log_level=$(echo "$DOCKER_CMD_LINE" | grep -o 'log-level=[^ ]*' | cut -d= -f2)

    if [ -n "$cmd_log_level" ]; then
        if [ "$cmd_log_level" = "info" ]; then
            log_pass "2.3 - Logging level is set to 'info' via command line flag."
        else
            log_warn "2.3 - Logging level is set to '$cmd_log_level' via command line flag, not 'info'."
        fi
        return
    fi
    
    if [ "$json_log_level" != "null" ]; then
        if [ "$json_log_level" = "info" ]; then
            log_pass "2.3 - Logging level is set to 'info' in $DAEMON_JSON_FILE."
        else
            log_warn "2.3 - Logging level is set to '$json_log_level' in $DAEMON_JSON_FILE, not 'info'."
        fi
    else
        log_pass "2.3 - Logging level is not set, using default 'info'."
    fi
}

# --- Check 2.4 ---
check_2_4() {
    log_info "2.4 - Ensure Docker is allowed to make changes to iptables (Manual)"
    log_cmd "Check dockerd process flags and /etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.4 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi

    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)
    
    local json_iptables="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_iptables=$(jq -r '."iptables"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi
    
    local cmd_iptables=$(echo "$DOCKER_CMD_LINE" | grep -o 'iptables=false')

    if [ -n "$cmd_iptables" ]; then
        log_warn "2.4 - Docker is forbidden from changing iptables via command line flag (iptables=false)."
    elif [ "$json_iptables" = "false" ]; then
        log_warn "2.4 - Docker is forbidden from changing iptables in $DAEMON_JSON_FILE (iptables: false)."
    else
        log_pass "2.4 - Docker is allowed to change iptables (Default: true)."
    fi
}

# --- Check 2.5 ---
check_2_5() {
    log_info "2.5 - Ensure insecure registries are not used (Manual)"
    log_cmd "docker info --format '{{json .RegistryConfig.InsecureRegistryCIDRs}}'"

    if ! command -v docker &> /dev/null; then
        log_fail "2.5 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi

    local registries=$(docker info --format '{{json .RegistryConfig.InsecureRegistryCIDRs}}' 2>/dev/null | jq -r '.[]?')

    # Loại bỏ mặc định 127.0.0.0/8 và ::1/128
    local non_default=$(echo "$registries" | grep -Ev '^(127\.0\.0\.0/8|::1/128)$')

    if [ -z "$non_default" ]; then
        log_pass "2.5 - No non-default insecure registries are configured."
    else
        log_warn "2.5 - Insecure registries are in use: $non_default"
    fi
}

# --- Check 2.6 ---
check_2_6() {
    log_info "2.6 - Ensure aufs storage driver is not used (Manual)"
    log_cmd "docker info --format '{{ .Driver }}'"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.6 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi

    # Self-contained command (Corrected PDF template)
    local driver=$(docker info --format '{{ .Driver }}' 2>/dev/null)
    
    if [ "$driver" = "aufs" ]; then
        log_warn "2.6 - 'aufs' storage driver is in use. This is deprecated."
    else
        log_pass "2.6 - 'aufs' storage driver is not in use. (Current driver: $driver)"
    fi
}

# --- Check 2.7 ---
check_2_7() {
    log_info "2.7 - Ensure devicemapper storage driver is not used (Manual)"
    log_cmd "docker info --format '{{ .Driver }}'"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.7 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi

    # Self-contained command (Corrected PDF template)
    local driver=$(docker info --format '{{ .Driver }}' 2>/dev/null)
    
    if [ "$driver" = "devicemapper" ]; then
        log_warn "2.7 - 'devicemapper' storage driver is in use. This is removed in v25.0."
    else
        log_pass "2.7 - 'devicemapper' storage driver is not in use. (Current driver: $driver)"
    fi
}

# --- Check 2.8 ---
check_2_8() {
    log_info "2.8 - Ensure TLS authentication for Docker daemon is configured (Manual)"
    log_cmd "Check dockerd process flags for '-H tcp://' and TLS settings"

    # Check if docker command exists
    if ! command -v docker &> /dev/null; then
        log_fail "2.8 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi

    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep '[d]ockerd' || true)

    # Check if Docker daemon is listening on TCP
    local is_tcp_host=false
    if echo "$DOCKER_CMD_LINE" | grep -q -- '-H tcp://'; then
        is_tcp_host=true
    fi
    if [ -f "$DAEMON_JSON_FILE" ]; then
        if jq -e '."hosts"[] | test("tcp://")' "$DAEMON_JSON_FILE" >/dev/null 2>&1; then
            is_tcp_host=true
        fi
    fi

    # If not listening on TCP, pass the check
    if [ "$is_tcp_host" = "false" ]; then
        log_pass "2.8 - Docker daemon is not configured to listen on TCP."
        return
    fi

    log_note "2.8 - Docker daemon is listening on TCP. Checking TLS settings..."

    # Check TLS flags from command line
    local cmd_tlsverify=$(echo "$DOCKER_CMD_LINE" | grep -o -- 'tlsverify')
    local cmd_tlscacert=$(echo "$DOCKER_CMD_LINE" | grep -o -- 'tlscacert')
    local cmd_tlscert=$(echo "$DOCKER_CMD_LINE" | grep -o -- 'tlscert')
    local cmd_tlskey=$(echo "$DOCKER_CMD_LINE" | grep -o -- 'tlskey')

    # Check TLS settings from daemon.json
    local json_tlsverify="false"
    local json_tlscacert=""
    local json_tlscert=""
    local json_tlskey=""
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_tlsverify=$(jq -r '."tlsverify" // "false"' "$DAEMON_JSON_FILE" 2>/dev/null)
        json_tlscacert=$(jq -r '."tlscacert" // empty' "$DAEMON_JSON_FILE" 2>/dev/null)
        json_tlscert=$(jq -r '."tlscert" // empty' "$DAEMON_JSON_FILE" 2>/dev/null)
        json_tlskey=$(jq -r '."tlskey" // empty' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi

    # Verify that TLS is fully configured
    if { [ -n "$cmd_tlsverify" ] && [ -n "$cmd_tlscacert" ] && [ -n "$cmd_tlscert" ] && [ -n "$cmd_tlskey" ]; } || \
       { [ "$json_tlsverify" = "true" ] && [ -n "$json_tlscacert" ] && [ -n "$json_tlscert" ] && [ -n "$json_tlskey" ]; }; then
        log_pass "2.8 - TLS verification is enabled and all certificates are configured."
    else
        log_warn "2.8 - Docker daemon is listening on TCP but TLS is not fully configured (missing tlsverify or certificates)."
    fi
}


# --- Check 2.9 ---
check_2_9() {
    log_info "2.9 - Ensure the default ulimit is configured appropriately (Manual)"
    log_cmd "Check dockerd process flags and /etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.9 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi

    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)

    local cmd_ulimit=$(echo "$DOCKER_CMD_LINE" | grep -o 'default-ulimit')
    local json_ulimit="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_ulimit=$(jq -r '."default-ulimits"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi

    if [ -n "$cmd_ulimit" ]; then
        log_pass "2.9 - Default ulimit is set via command line flag."
        log_note "     Please verify settings manually: $(echo "$DOCKER_CMD_LINE" | grep -o 'default-ulimit=[^ ]*')"
    elif [ "$json_ulimit" != "null" ] && [ "$json_ulimit" != "{}" ]; then
        log_pass "2.9 - Default ulimit is set in $DAEMON_JSON_FILE."
        log_note "     Please verify settings manually: $json_ulimit"
    else
        log_warn "2.9 - Default ulimit is not configured."
    fi
}

# --- Check 2.10 ---
check_2_10() {
    log_info "2.10 - Enable user namespace support (Manual)"
    log_cmd "docker info --format '{{ .SecurityOptions }}'"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.10 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi

    # Self-contained command (Corrected PDF template)
    local userns=$(docker info --format '{{ .SecurityOptions }}' 2>/dev/null | grep 'userns')
    
    if [ -n "$userns" ]; then
        log_pass "2.10 - User namespace support (userns) is enabled."
    else
        log_warn "2.10 - User namespace support (userns) is not enabled."
    fi
}

# --- Check 2.11 ---
check_2_11() {
    log_info "2.11 - Ensure the default cgroup usage has been confirmed (Manual)"
    log_cmd "Check dockerd process flags and /etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.11 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi

    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)

    local cmd_cgroup_parent=$(echo "$DOCKER_CMD_LINE" | grep -o 'cgroup-parent=[^ ]*')
    local json_cgroup_parent="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_cgroup_parent=$(jq -r '."cgroup-parent"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi

    if [ -n "$cmd_cgroup_parent" ]; then
        log_note "2.11 - Custom cgroup parent set via command line: $cmd_cgroup_parent"
        log_note "       Please confirm this is appropriate for your environment."
    elif [ "$json_cgroup_parent" != "null" ]; then
        log_note "2.11 - Custom cgroup parent set in $DAEMON_JSON_FILE: $json_cgroup_parent"
        log_note "       Please confirm this is appropriate for your environment."
    else
        log_pass "2.11 - Default cgroup parent is in use."
    fi
}

# --- Check 2.12 ---
check_2_12() {
    log_info "2.12 - Ensure base device size is not changed until needed (Manual)"
    log_cmd "Check storage driver and storage-opts"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.12 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    if ! command -v jq &> /dev/null; then
        log_fail "2.12 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi

    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)

    local driver=$(docker info --format '{{ .Driver }}' 2>/dev/null)
    if [ "$driver" != "devicemapper" ]; then
        log_pass "2.12 - N/A: Storage driver is not 'devicemapper' (Current: $driver)."
        return
    fi
    
    local cmd_base_size=$(echo "$DOCKER_CMD_LINE" | grep -o 'dm.basesize=[^ ]*')
    local json_base_size=""
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_base_size=$(jq -r '."storage-opts"[] | select(. | contains("dm.basesize"))' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi

    if [ -n "$cmd_base_size" ]; then
        log_warn "2.12 - 'dm.basesize' is set via command line: $cmd_base_size. Ensure this is needed."
    elif [ -n "$json_base_size" ]; then
        log_warn "2.12 - 'dm.basesize' is set in $DAEMON_JSON_FILE: $json_base_size. Ensure this is needed."
    else
        log_pass "2.12 - 'dm.basesize' is not set (using default 10G)."
    fi
}

# --- Check 2.13 ---
check_2_13() {
    log_info "2.13 - Ensure that authorization for Docker client commands is enabled (Manual)"
    log_cmd "Check dockerd process flags and /etc/docker/daemon.json"

    if ! command -v jq &> /dev/null; then
        log_fail "2.13 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi
    
    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)
    
    local cmd_auth_plugin=$(echo "$DOCKER_CMD_LINE" | grep -o 'authorization-plugin=[^ ]*')
    local json_auth_plugin="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_auth_plugin=$(jq -r '."authorization-plugins"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi

    if [ -n "$cmd_auth_plugin" ]; then
        log_pass "2.13 - Authorization plugin is enabled via command line: $cmd_auth_plugin"
    elif [ "$json_auth_plugin" != "null" ] && [ "$json_auth_plugin" != "[]" ]; then
        log_pass "2.13 - Authorization plugin is enabled in $DAEMON_JSON_FILE: $json_auth_plugin"
    else
        log_warn "2.13 - No authorization plugin is enabled."
    fi
}

# --- Check 2.14 ---
check_2_14() {
    log_info "2.14 - Ensure centralized and remote logging is configured (Manual)"
    log_cmd "docker info --format '{{ .LoggingDriver }}'"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.14 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    # Self-contained command (Corrected PDF template)
    local log_driver=$(docker info --format '{{ .LoggingDriver }}' 2>/dev/null)
    
    if [ "$log_driver" = "json-file" ]; then
        log_warn "2.14 - Logging driver is 'json-file' (default, not centralized)."
    else
        log_pass "2.14 - Logging driver is set to '$log_driver'."
    fi
}

# --- Check 2.15 ---
check_2_15() {
    log_info "2.15 - Ensure containers are restricted from acquiring new privileges (Manual)"
    log_cmd "Check dockerd process flags and /etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.15 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi
    
    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)

    local cmd_no_new_priv=$(echo "$DOCKER_CMD_LINE" | grep -o 'no-new-privileges')
    local json_no_new_priv="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_no_new_priv=$(jq -r '."no-new-privileges"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi

    if [ -n "$cmd_no_new_priv" ]; then
        log_pass "2.15 - 'no-new-privileges' is enabled via command line flag."
    elif [ "$json_no_new_priv" = "true" ]; then
        log_pass "2.15 - 'no-new-privileges' is enabled in $DAEMON_JSON_FILE."
    else
        log_warn "2.15 - 'no-new-privileges' is not enabled (Default: false)."
    fi
}

# --- Check 2.16 ---
check_2_16() {
    log_info "2.16 - Ensure live restore is enabled (Manual)"
    log_cmd "docker info --format '{{ .LiveRestoreEnabled }}'"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.16 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    if ! command -v jq &> /dev/null; then
        log_fail "2.16 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi
    
    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"

    # Self-contained command (Corrected PDF template)
    local live_restore_info=$(docker info --format '{{ .LiveRestoreEnabled }}' 2>/dev/null)
    
    local json_live_restore="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_live_restore=$(jq -r '."live-restore"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi
    
    if [ "$live_restore_info" = "true" ] || [ "$json_live_restore" = "true" ]; then
        log_pass "2.16 - Live restore is enabled."
    else
        log_warn "2.16 - Live restore is not enabled (Default: false)."
    fi
}

# --- Check 2.17 ---
check_2_17() {
    log_info "2.17 - Ensure Userland Proxy is Disabled (Manual)"
    log_cmd "Check dockerd process flags and /etc/docker/daemon.json"
    
    if ! command -v jq &> /dev/null; then
        log_fail "2.17 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi
    
    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)

    local cmd_userland_proxy=$(echo "$DOCKER_CMD_LINE" | grep -o 'userland-proxy=false')
    local json_userland_proxy="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_userland_proxy=$(jq -r '."userland-proxy"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi

    if [ -n "$cmd_userland_proxy" ]; then
        log_pass "2.17 - Userland proxy is disabled via command line flag."
    elif [ "$json_userland_proxy" = "false" ]; then
        log_pass "2.17 - Userland proxy is disabled in $DAEMON_JSON_FILE."
    else
        log_warn "2.17 - Userland proxy is enabled (Default: true)."
    fi
}

# --- Check 2.18 ---
check_2_18() {
    log_info "2.18 - Ensure that a daemon-wide custom seccomp profile is applied if appropriate (Manual)"
    log_cmd "docker info --format '{{ .SecurityOptions }}'"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.18 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    if ! command -v jq &> /dev/null; then
        log_fail "2.18 - COMMAND NOT FOUND: 'jq' is not installed."
        return
    fi
    
    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)

    local cmd_seccomp=$(echo "$DOCKER_CMD_LINE" | grep -o 'seccomp-profile=[^ ]*')
    local json_seccomp="null"
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_seccomp=$(jq -r '."seccomp-profile"' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi
    
    local info_seccomp=$(docker info --format '{{ .SecurityOptions }}' 2>/dev/null | grep 'seccomp')
    
    if [ -n "$cmd_seccomp" ]; then
        log_note "2.18 - Custom seccomp profile set via command line: $cmd_seccomp"
        log_note "       Please confirm this is appropriate for your environment."
    elif [ "$json_seccomp" != "null" ]; then
         log_note "2.18 - Custom seccomp profile set in $DAEMON_JSON_FILE: $json_seccomp"
         log_note "       Please confirm this is appropriate for your environment."
    elif echo "$info_seccomp" | grep -q 'default'; then
        log_pass "2.18 - Default seccomp profile is in use."
    else
        log_warn "2.18 - Could not determine seccomp profile. (Value: $info_seccomp)"
    fi
}

# --- Check 2.19 ---
check_2_19() {
    log_info "2.19 - Ensure that experimental features are not implemented in production (Manual)"
    log_cmd "docker version --format '{{ .Server.Experimental }}'"
    
    if ! command -v docker &> /dev/null; then
        log_fail "2.19 - COMMAND NOT FOUND: 'docker' is not installed."
        return
    fi
    
    # Self-contained command (Corrected PDF template)
    local experimental=$(docker version --format '{{ .Server.Experimental }}' 2>/dev/null)
    
    if [ "$experimental" = "true" ]; then
        log_warn "2.19 - Experimental features are enabled on the daemon."
    else
        log_pass "2.19 - Experimental features are disabled (Default: false)."
    fi
}


# --- Main Function ---
main() {
    echo "================================================================="
    echo "  Running CIS Docker v1.8.0 - Section 2 Checks (Unaltered Mode) "
    echo "================================================================="
    
    # --- Prerequisite Checks (Run once in main for user feedback) ---
    # Individual checks will still perform their own check
    local prereq_fail=false
    if ! command -v docker &> /dev/null; then
        log_fail "FATAL: 'docker' command not found. Please install Docker."
        prereq_fail=true
    fi
    if ! command -v jq &> /dev/null; then
        log_fail "FATAL: 'jq' command not found. Please install 'jq' to parse JSON files."
        prereq_fail=true
    fi
    
    local initial_docker_cmd=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)
    if [ -z "$initial_docker_cmd" ]; then
        log_fail "FATAL: No 'dockerd' process is running. Cannot proceed."
        prereq_fail=true
    fi
    
    if [ "$prereq_fail" = "true" ]; then
        echo "Exiting due to missing prerequisites."
        exit 1
    fi
    
    # --- Run All Checks ---
    check_2_1
    echo "---"
    check_2_2
    echo "---"
    check_2_3
    echo "---"
    check_2_4
    echo "---"
    check_2_5
    echo "---"
    check_2_6
    echo "---"
    check_2_7
    echo "---"
    check_2_8
    echo "---"
    check_2_9
    echo "---"
    check_2_10
    echo "---"
    check_2_11
    echo "---"
    check_2_12
    echo "---"
    check_2_13
    echo "---"
    check_2_14
    echo "---"
    check_2_15
    echo "---"
    check_2_16
    echo "---"
    check_2_17
    echo "---"
    check_2_18
    echo "---"
    check_2_19
    
    echo "================================================================="
    echo "                  Section 2 Checks Complete                    "
    echo "================================================================="
}

# Execute main function
main