#!/bin/bash

# # Thay đổi thư mục làm việc thành thư mục chứa tập lệnh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "$SCRIPT_DIR" >/dev/null

# Lấy nguồn tệp cis_log.sh từ cùng thư mục
source "./cis_log.sh"

# --- Helper Functions ---
get_service_file() {
    local service=$1
    systemctl show -p FragmentPath "$service" 2>/dev/null | cut -d'=' -f2
}

do_version_check() {
    local current=$1
    local installed=$2
    if [ "$(printf '%s\n' "$current" "$installed" | sort -V | head -n1)" = "$current" ]; then
        return 0
    fi
    return 11
}

auditrules="/etc/audit/audit.rules"

# --- Check Functions ---

check_1_1() {
  echo ""
  local id="1.1"
  local desc="Linux Hosts Specific Configuration"
  log_info "$id - $desc"
}

check_1_1_1() {
  local id="1.1.1"
  local desc="Ensure a separate partition for containers has been created (Automated)"

  docker_root_dir=$(docker info -f '{{ .DockerRootDir }}' 2>/dev/null)
  if docker info 2>/dev/null | grep -q userns ; then
    docker_root_dir=$(readlink -f "$docker_root_dir/..")
  fi

  if mountpoint -q -- "$docker_root_dir" >/dev/null 2>&1; then
    add_summary "$id" "$desc" "PASS"
    return
  fi
  add_summary "$id" "$desc" "FAIL"
}

check_1_1_2() {
  local id="1.1.2"
  local desc="Ensure only trusted users are allowed to control Docker daemon (Automated)"

  docker_users=$(grep 'docker' /etc/group 2>/dev/null)
  if command -v getent >/dev/null 2>&1; then
    docker_users=$(getent group docker 2>/dev/null)
  fi
  docker_users=$(printf "%s" "$docker_users" | awk -F: '{print $4}')

  if [ -n "$docker_users" ]; then
    add_summary "$id" "$desc" "INFO"
    echo "      * Docker group users: $docker_users"
  else
    add_summary "$id" "$desc" "PASS"
  fi
}

check_1_1_3() {
  local id="1.1.3"
  local desc="Ensure auditing is configured for the Docker daemon (Automated)"

  file="/usr/bin/dockerd"
  if command -v auditctl >/dev/null 2>&1; then
    if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
  fi
  if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
    add_summary "$id" "$desc" "PASS"
    return
  fi
  add_summary "$id" "$desc" "FAIL"
}

check_1_1_4() {
  local id="1.1.4"
  local desc="Ensure auditing is configured for Docker files and directories - /run/containerd (Automated)"

  file="/run/containerd"
  if command -v auditctl >/dev/null 2>&1; then
    if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
  fi
  if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
    add_summary "$id" "$desc" "PASS"
    return
  fi
  add_summary "$id" "$desc" "FAIL"
}

check_1_1_5() {
  local id="1.1.5"
  local desc="Ensure auditing is configured for Docker files and directories - /var/lib/docker (Automated)"

  directory="/var/lib/docker"
  if [ -d "$directory" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$directory" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$directory" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_6() {
  local id="1.1.6"
  local desc="Ensure auditing is configured for Docker files and directories - /etc/docker (Automated)"

  directory="/etc/docker"
  if [ -d "$directory" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$directory" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$directory" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_7() {
  local id="1.1.7"
  local desc="Ensure auditing is configured for Docker files and directories - docker.service (Automated)"

  file="$(get_service_file docker.service)"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_8() {
  local id="1.1.8"
  local desc="Ensure auditing is configured for Docker files and directories - containerd.sock (Automated)"

  file="/run/containerd/containerd.sock"
  if [ -e "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_9() {
  local id="1.1.9"
  local desc="Ensure auditing is configured for Docker files and directories - docker.socket (Automated)"

  file="$(get_service_file docker.socket)"
  if [ -e "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_10() {
  local id="1.1.10"
  local desc="Ensure auditing is configured for Docker files and directories - /etc/default/docker (Automated)"

  file="/etc/default/docker"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_11() {
  local id="1.1.11"
  local desc="Ensure auditing is configured for Docker files and directories - /etc/docker/daemon.json (Automated)"

  file="/etc/docker/daemon.json"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_12() {
  local id="1.1.12"
  local desc="Ensure auditing is configured for Docker files and directories - /etc/containerd/config.toml (Automated)"

  file="/etc/containerd/config.toml"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_13() {
  local id="1.1.13"
  local desc="Ensure auditing is configured for Docker files and directories - /etc/sysconfig/docker (Automated)"

  file="/etc/sysconfig/docker"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_14() {
  local id="1.1.14"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/containerd (Automated)"

  file="/usr/bin/containerd"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_15() {
  local id="1.1.15"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/containerd-shim (Automated)"

  file="/usr/bin/containerd-shim"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_16() {
  local id="1.1.16"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/containerd-shim-runc-v1 (Automated)"

  file="/usr/bin/containerd-shim-runc-v1"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_17() {
  local id="1.1.17"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/containerd-shim-runc-v2 (Automated)"

  file="/usr/bin/containerd-shim-runc-v2"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_1_18() {
  local id="1.1.18"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/runc (Automated)"

  file="/usr/bin/runc"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l 2>/dev/null | grep "$file" >/dev/null 2>&1; then
        add_summary "$id" "$desc" "PASS"
        return
      fi
    fi
    if [ -f "$auditrules" ] && grep -s "$file" "$auditrules" 2>/dev/null | grep "^[^#;]" >/dev/null 2>&1; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    return
  fi
  add_summary "$id" "$desc" "INFO"
}

check_1_2() {
  echo ""
  local id="1.2"
  local desc="General Configuration"
  add_summary "$id" "$desc" "INFO"
}

check_1_2_1() {
  local id="1.2.1"
  local desc="Ensure the container host has been Hardened (Manual)"
  
  add_summary "$id" "$desc" "INFO"
}

check_1_2_2() {
  local id="1.2.2"
  local desc="Ensure that the version of Docker is up to date (Manual)"

  docker_version=$(docker version 2>/dev/null | grep -i -A2 '^server' | grep ' Version:' \
    | awk '{print $NF; exit}' | tr -d '[:alpha:]-,')
  docker_current_version="$(date +%y.%m.0 -d @$(( $(date +%s) - 2592000)))"
  
  do_version_check "$docker_current_version" "$docker_version"
  if [ $? -eq 11 ]; then
    add_summary "$id" "$desc" "INFO"
    echo "       * Using $docker_version, verify if it is up to date"
    return
  fi
  add_summary "$id" "$desc" "PASS"
  echo "       * Using $docker_version which is current"
}

main (){
  echo "================================================================="
  echo "  Running CIS Docker v1.8.0 - Section 1 Checks (Unaltered Mode) "
  echo "================================================================="
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
  check_1_1
  check_1_1_1
  check_1_1_2
  check_1_1_3
  check_1_1_4
  check_1_1_5
  check_1_1_6
  check_1_1_7
  check_1_1_8
  check_1_1_9
  check_1_1_10
  check_1_1_11
  check_1_1_12
  check_1_1_13
  check_1_1_14
  check_1_1_15
  check_1_1_16
  check_1_1_17
  check_1_1_18
  check_1_2
  check_1_2_1
  check_1_2_2  
  echo "================================================================="
  echo "                  Section 1 Checks Complete                    "
  echo "================================================================="  

    PASS_COUNT=0
    FAIL_COUNT=0
    INFO_COUNT=0
    log_info "1 - Host Configuration"
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
    echo -e "${C_YELLOW}TOTAL: $((PASS_COUNT + FAIL_COUNT + INFO_COUNT))${NC}"
    echo ""
    echo "=========================================="
    echo "Remediation script for Section 1 finished."
    echo "=========================================="
}

main
