#!/bin/bash

# Thay đổi thư mục làm việc thành thư mục chứa tập lệnh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "$SCRIPT_DIR" >/dev/null


# Lấy nguồn tệp cis_log.sh từ cùng thư mục
source "./cis_log.sh"

# --- Helper Functions ---
get_service_file() {
  local service="$1"
  systemctl show -p FragmentPath "$service" 2>/dev/null | sed 's/FragmentPath=//'
}

get_docker_effective_command_line_args() {
  local arg="$1"
  ps -ef | grep dockerd | grep -v grep | grep -o -- "$arg[^ ]*" || echo ""
}

get_docker_configuration_file_args() {
  local arg="$1"
  local config_file="/etc/docker/daemon.json"
  if [ -f "$config_file" ]; then
    grep -o "\"$arg\"[^,}]*" "$config_file" | cut -d':' -f2 | tr -d ' "' || echo ""
  else
    echo ""
  fi
}

check_3() {
  echo ""
  local id="3"
  local desc="Docker daemon configuration files"
  log_info "$id - $desc"
}

check_3_1() {
  local id="3.1"
  local desc="Ensure that the docker.service file ownership is set to root:root (Automated)"

  file=$(get_service_file docker.service)
  if [ -f "$file" ]; then
    if [ "$(stat -c %u%g "$file")" -eq 00 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "     * Wrong ownership for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * File not found"
}

check_3_2() {
  local id="3.2"
  local desc="Ensure that docker.service file permissions are appropriately set (Automated)"

  file=$(get_service_file docker.service)
  if [ -f "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 644 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "     * Wrong permissions for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * File not found"
}

check_3_3() {
  local id="3.3"
  local desc="Ensure that docker.socket file ownership is set to root:root (Automated)"

  file=$(get_service_file docker.socket)
  if [ -f "$file" ]; then
    if [ "$(stat -c %u%g "$file")" -eq 00 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "     * Wrong ownership for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * File not found"
}

check_3_4() {
  local id="3.4"
  local desc="Ensure that docker.socket file permissions are set to 644 or more restrictive (Automated)"

  file=$(get_service_file docker.socket)
  if [ -f "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 644 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "     * Wrong permissions for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * File not found"
}

check_3_5() {
  local id="3.5"
  local desc="Ensure that the /etc/docker directory ownership is set to root:root (Automated)"

  directory="/etc/docker"
  if [ -d "$directory" ]; then
    if [ "$(stat -c %u%g "$directory")" -eq 00 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "     * Wrong ownership for $directory"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * Directory not found"
}

check_3_6() {
  local id="3.6"
  local desc="Ensure that /etc/docker directory permissions are set to 755 or more restrictively (Automated)"

  directory="/etc/docker"
  if [ -d "$directory" ]; then
    if [ "$(stat -c %a "$directory")" -le 755 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "     * Wrong permissions for $directory"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * Directory not found"
}

check_3_7() {
  local id="3.7"
  local desc="Ensure that registry certificate file ownership is set to root:root (Automated)"

  directory="/etc/docker/certs.d/"
  if [ -d "$directory" ]; then
    fail=0
    owners=$(find "$directory" -type f -name '*.crt' 2>/dev/null)
    for p in $owners; do
      if [ "$(stat -c %u "$p")" -ne 0 ]; then
        fail=1
      fi
    done
    if [ $fail -eq 1 ]; then
      add_summary "$id" "$desc" "FAIL"
      echo "     * Wrong ownership for $directory"
      return
    fi
    add_summary "$id" "$desc" "PASS"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * Directory not found"
}

check_3_8() {
  local id="3.8"
  local desc="Ensure that registry certificate file permissions are set to 444 or more restrictively (Automated)"

  directory="/etc/docker/certs.d/"
  if [ -d "$directory" ]; then
    fail=0
    perms=$(find "$directory" -type f -name '*.crt' 2>/dev/null)
    for p in $perms; do
      if [ "$(stat -c %a "$p")" -gt 444 ]; then
        fail=1
      fi
    done
    if [ $fail -eq 1 ]; then
      add_summary "$id" "$desc" "FAIL"
      echo "     * Wrong permissions for $directory"
      return
    fi
    add_summary "$id" "$desc" "PASS"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * Directory not found"
}

check_3_9() {
  local id="3.9"
  local desc="Ensure that TLS CA certificate file ownership is set to root:root (Automated)"

  tlscacert=$(get_docker_effective_command_line_args '--tlscacert' | sed -n 's/.*tlscacert=\([^[:space:]]*\).*/\1/p')
  if [ -z "$tlscacert" ]; then
    tlscacert=$(get_docker_configuration_file_args 'tlscacert')
  fi
  if [ -n "$tlscacert" ] && [ -f "$tlscacert" ]; then
    if [ "$(stat -c %u%g "$tlscacert")" -eq 00 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "     * Wrong ownership for $tlscacert"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "     * No TLS CA certificate found"
}

check_3_10() {
  local id="3.10"
  local desc="Ensure that TLS CA certificate file permissions are set to 444 or more restrictively (Automated)"

  tlscacert=$(get_docker_effective_command_line_args '--tlscacert' | sed -n 's/.*tlscacert=\([^[:space:]]*\).*/\1/p')
  if [ -z "$tlscacert" ]; then
    tlscacert=$(get_docker_configuration_file_args 'tlscacert')
  fi
  if [ -n "$tlscacert" ] && [ -f "$tlscacert" ]; then
    if [ "$(stat -c %a "$tlscacert")" -le 444 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong permissions for $tlscacert"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * No TLS CA certificate found"
}

check_3_11() {
  local id="3.11"
  local desc="Ensure that Docker server certificate file ownership is set to root:root (Automated)"

  tlscert=$(get_docker_effective_command_line_args '--tlscert' | sed -n 's/.*tlscert=\([^[:space:]]*\).*/\1/p')
  if [ -z "$tlscert" ]; then
    tlscert=$(get_docker_configuration_file_args 'tlscert')
  fi
  if [ -n "$tlscert" ] && [ -f "$tlscert" ]; then
    if [ "$(stat -c %u%g "$tlscert")" -eq 00 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong ownership for $tlscert"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * No TLS Server certificate found"
}

check_3_12() {
  local id="3.12"
  local desc="Ensure that the Docker server certificate file permissions are set to 444 or more restrictively (Automated)"

  tlscert=$(get_docker_effective_command_line_args '--tlscert' | sed -n 's/.*tlscert=\([^[:space:]]*\).*/\1/p')
  if [ -z "$tlscert" ]; then
    tlscert=$(get_docker_configuration_file_args 'tlscert')
  fi
  if [ -n "$tlscert" ] && [ -f "$tlscert" ]; then
    if [ "$(stat -c %a "$tlscert")" -le 444 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong permissions for $tlscert"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * No TLS Server certificate found"
}

check_3_13() {
  local id="3.13"
  local desc="Ensure that the Docker server certificate key file ownership is set to root:root (Automated)"

  tlskey=$(get_docker_effective_command_line_args '--tlskey' | sed -n 's/.*tlskey=\([^[:space:]]*\).*/\1/p')
  if [ -z "$tlskey" ]; then
    tlskey=$(get_docker_configuration_file_args 'tlskey')
  fi
  if [ -n "$tlskey" ] && [ -f "$tlskey" ]; then
    if [ "$(stat -c %u%g "$tlskey")" -eq 00 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong ownership for $tlskey"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * No TLS Key found"
}

check_3_14() {
  local id="3.14"
  local desc="Ensure that the Docker server certificate key file permissions are set to 400 (Automated)"

  tlskey=$(get_docker_effective_command_line_args '--tlskey' | sed -n 's/.*tlskey=\([^[:space:]]*\).*/\1/p')
  if [ -z "$tlskey" ]; then
    tlskey=$(get_docker_configuration_file_args 'tlskey')
  fi
  if [ -n "$tlskey" ] && [ -f "$tlskey" ]; then
    if [ "$(stat -c %a "$tlskey")" -eq 400 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong permissions for $tlskey"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * No TLS Key found"
}

check_3_15() {
  local id="3.15"
  local desc="Ensure that the Docker socket file ownership is set to root:docker (Automated)"

  file="/var/run/docker.sock"
  if [ -S "$file" ]; then
    if [ "$(stat -c %U:%G "$file")" = 'root:docker' ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong ownership for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_16() {
  local id="3.16"
  local desc="Ensure that the Docker socket file permissions are set to 660 or more restrictively (Automated)"

  file="/var/run/docker.sock"
  if [ -S "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 660 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong permissions for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_17() {
  local id="3.17"
  local desc="Ensure that the daemon.json file ownership is set to root:root (Automated)"

  file="/etc/docker/daemon.json"
  if [ -f "$file" ]; then
    if [ "$(stat -c %U:%G "$file")" = 'root:root' ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong ownership for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_18() {
  local id="3.18"
  local desc="Ensure that daemon.json file permissions are set to 644 or more restrictive (Automated)"

  file="/etc/docker/daemon.json"
  if [ -f "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 644 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong permissions for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_19() {
  local id="3.19"
  local desc="Ensure that the /etc/default/docker file ownership is set to root:root (Automated)"

  file="/etc/default/docker"
  if [ -f "$file" ]; then
    if [ "$(stat -c %U:%G "$file")" = 'root:root' ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong ownership for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_20() {
  local id="3.20"
  local desc="Ensure that the /etc/default/docker file permissions are set to 644 or more restrictively (Automated)"

  file="/etc/default/docker"
  if [ -f "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 644 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong permissions for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_21() {
  local id="3.21"
  local desc="Ensure that the /etc/sysconfig/docker file permissions are set to 644 or more restrictively (Automated)"

  file="/etc/sysconfig/docker"
  if [ -f "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 644 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong permissions for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_22() {
  local id="3.22"
  local desc="Ensure that the /etc/sysconfig/docker file ownership is set to root:root (Automated)"

  file="/etc/sysconfig/docker"
  if [ -f "$file" ]; then
    if [ "$(stat -c %U:%G "$file")" = 'root:root' ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong ownership for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_23() {
  local id="3.23"
  local desc="Ensure that the Containerd socket file ownership is set to root:root (Automated)"

  file="/run/containerd/containerd.sock"
  if [ -S "$file" ]; then
    if [ "$(stat -c %U:%G "$file")" = 'root:root' ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong ownership for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}

check_3_24() {
  local id="3.24"
  local desc="Ensure that the Containerd socket file permissions are set to 660 or more restrictively (Automated)"

  file="/run/containerd/containerd.sock"
  if [ -S "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 660 ]; then
      add_summary "$id" "$desc" "PASS"
      return
    fi
    add_summary "$id" "$desc" "FAIL"
    echo "      * Wrong permissions for $file"
    return
  fi
  add_summary "$id" "$desc" "INFO"
  echo "      * File not found"
}


main (){
  echo "================================================================="
  echo "  Running CIS Docker v1.8.0 - Section 3 Checks (Unaltered Mode) "
  echo "================================================================="
  # Main execution for Section 3
  check_3
  check_3_1
  check_3_2
  check_3_3
  check_3_4
  check_3_5
  check_3_6
  check_3_7
  check_3_8
  check_3_9
  check_3_10
  check_3_11
  check_3_12
  check_3_13
  check_3_14
  check_3_15
  check_3_16
  check_3_17
  check_3_18
  check_3_19
  check_3_20
  check_3_21
  check_3_22
  check_3_23
  check_3_24
  echo "================================================================="
  echo "                  Section 3 Checks Complete                    "
  echo "================================================================="

    PASS_COUNT=0
    FAIL_COUNT=0
    INFO_COUNT=0
    log_info "3 - Docker Daemon Configuration Files"
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
    echo "Remediation script for Section 3 finished."
    echo "=========================================="
}

main

