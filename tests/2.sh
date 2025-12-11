#!/bin/bash

# Thay đổi thư mục làm việc thành thư mục chứa tập lệnh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "$SCRIPT_DIR" >/dev/null

# Lấy nguồn tệp cis_log.sh từ cùng thư mục
source "./cis_log.sh"

# --- Check 2.1 ---
check_2_1() {
    local id="2.1"
    local desc="Run the Docker daemon as a non-root user, if possible (Manual)"
    
    # Self-contained command
    local DOCKER_CMD_LINE=$(ps -fe | grep 'dockerd' | grep -v 'grep' || true)

    if [ -z "$DOCKER_CMD_LINE" ]; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi

    local user=$(echo "$DOCKER_CMD_LINE" | awk '{print }')

    if [ "$user" = "root" ]; then
        add_summary "$id" "$desc" "INFO"
        echo "     (This is the default. CIS recommends rootless mode if possible. Please verify manually.)"
    else
        add_summary "$id" "$desc" "PASS"
    fi
}

# --- Check 2.2 ---
check_2_2() {
    local id="2.2"
    local desc="Ensure network traffic is restricted between containers on the default bridge (Manual)"
    
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    # Self-contained command
    local icc_setting=$(docker network ls --quiet | xargs docker network inspect --format '{{.Name }}: {{ .Options }}' 2>/dev/null | grep '^bridge:')

    if echo "$icc_setting" | grep -q "com.docker.network.bridge.enable_icc:false"; then
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
    fi
}

# --- Check 2.3 ---
check_2_3() {
    local id="2.3"
    local desc="Ensure the logging level is set to 'info' (Manual)"
    
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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
            add_summary "$id" "$desc" "PASS"
        else
            add_summary "$id" "$desc" "FAIL"
        fi
        return
    fi
    
    if [ "$json_log_level" != "null" ]; then
        if [ "$json_log_level" = "info" ]; then
            add_summary "$id" "$desc" "PASS"
        else
            add_summary "$id" "$desc" "FAIL"
        fi
    else
        add_summary "$id" "$desc" "PASS"
    fi
}

# --- Check 2.4 ---
check_2_4() {
    local id="2.4"
    local desc="Ensure Docker is allowed to make changes to iptables (Manual)"
    
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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
        add_summary "$id" "$desc" "FAIL"
    elif [ "$json_iptables" = "false" ]; then
        add_summary "$id" "$desc" "FAIL"
    else
        add_summary "$id" "$desc" "PASS"
    fi
}

# --- Check 2.5 ---
check_2_5() {
    local id="2.5"
    local desc="Ensure insecure registries are not used (Manual)"

    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi

    local registries=$(docker info --format '{{json .RegistryConfig.InsecureRegistryCIDRs}}' 2>/dev/null | jq -r '.[]?')

    # Loại bỏ mặc định 127.0.0.0/8 và ::1/128
    local non_default=$(echo "$registries" | grep -Ev '^(127\.0\.0\.0/8|::1/128)$')

    if [ -z "$non_default" ]; then
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
    fi
}

# --- Check 2.6 ---
check_2_6() {
    local id="2.6"
    local desc="Ensure aufs storage driver is not used (Manual)"
    
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi

    # Self-contained command (Corrected PDF template)
    local driver=$(docker info --format '{{ .Driver }}' 2>/dev/null)
    
    if [ "$driver" = "aufs" ]; then
        add_summary "$id" "$desc" "FAIL"
    else
        add_summary "$id" "$desc" "PASS"
    fi
}

# --- Check 2.7 ---
check_2_7() {
    local id="2.7"
    local desc="Ensure devicemapper storage driver is not used (Manual)"
    
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi

    # Self-contained command (Corrected PDF template)
    local driver=$(docker info --format '{{ .Driver }}' 2>/dev/null)
    
    if [ "$driver" = "devicemapper" ]; then
        add_summary "$id" "$desc" "FAIL"
    else
        add_summary "$id" "$desc" "PASS"
    fi
}

# --- Check 2.8 ---
check_2_8() {
    local id="2.8"
    local desc="Ensure TLS authentication for Docker daemon is configured (Manual)"

    # Check if docker command exists
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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
        add_summary "$id" "$desc" "PASS"
        return
    fi

    add_summary "$id" "$desc" "INFO"

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
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
    fi
}


# --- Check 2.9 ---
check_2_9() {
    local id="2.9"
    local desc="Ensure the default ulimit is configured appropriately (Manual)"
    
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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
        add_summary "$id" "$desc" "PASS"
        echo "     Please verify settings manually: $(echo "$DOCKER_CMD_LINE" | grep -o 'default-ulimit=[^ ]*')"
    elif [ "$json_ulimit" != "null" ] && [ "$json_ulimit" != "{}" ]; then
        add_summary "$id" "$desc" "PASS"
        echo "     Please verify settings manually: $json_ulimit"
    else
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Cài đặt jq nếu chưa có
sudo apt-get install -y jq
# Tạo daemon.json nếu chưa tồn tại
sudo mkdir -p /etc/docker
[ ! -f /etc/docker/daemon.json ] && echo '{}' | sudo tee /etc/docker/daemon.json
# Thêm default ulimits
sudo jq '. + {\"default-ulimits\": {\"nofile\": {\"Name\": \"nofile\", \"Hard\": 64000, \"Soft\": 64000}, \"nproc\": {\"Name\": \"nproc\", \"Hard\": 4096, \"Soft\": 4096}}}' /etc/docker/daemon.json > /tmp/daemon.json.tmp
sudo mv /tmp/daemon.json.tmp /etc/docker/daemon.json
sudo systemctl restart docker
# Verify: docker info --format '{{.SecurityOptions}}'"
    fi
}

# --- Check 2.10 ---
check_2_10() {
    local id="2.10"
    local desc="Enable user namespace support (Manual)"

    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Docker chưa được cài đặt
sudo apt-get update && sudo apt-get install -y docker.io
sudo systemctl enable docker && sudo systemctl start docker"
        return
    fi

    # Self-contained command (Corrected PDF template)
    local userns=$(docker info --format '{{ .SecurityOptions }}' 2>/dev/null | grep 'userns')

    if [ -n "$userns" ]; then
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "⚠️ CẢNH BÁO: Sẽ ảnh hưởng containers hiện có, cần recreate tất cả containers
# Cài đặt jq nếu chưa có
sudo apt-get install -y jq
# Tạo daemon.json nếu chưa tồn tại
sudo mkdir -p /etc/docker
[ ! -f /etc/docker/daemon.json ] && echo '{}' | sudo tee /etc/docker/daemon.json
# Enable user namespace
sudo jq '. + {\"userns-remap\": \"default\"}' /etc/docker/daemon.json > /tmp/daemon.json.tmp
sudo mv /tmp/daemon.json.tmp /etc/docker/daemon.json
# Tạo subuid và subgid mapping
echo 'dockremap:100000:65536' | sudo tee -a /etc/subuid
echo 'dockremap:100000:65536' | sudo tee -a /etc/subgid
sudo systemctl restart docker
# Verify: docker info --format '{{.SecurityOptions}}' | grep userns"
    fi
}

# --- Check 2.11 ---
check_2_11() {
    local id="2.11"
    local desc="Ensure the default cgroup usage has been confirmed (Manual)"
    
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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
        add_summary "$id" "$desc" "INFO"
        echo "       Please confirm this is appropriate for your environment."
    elif [ "$json_cgroup_parent" != "null" ]; then
        add_summary "$id" "$desc" "INFO"
        echo "       Please confirm this is appropriate for your environment."
    else
        add_summary "$id" "$desc" "PASS"
    fi
}

# --- Check 2.12 ---
check_2_12() {
    local id="2.12"
    local desc="Ensure base device size is not changed until needed (Manual)"
    
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi

    # Self-contained setup
    local DAEMON_JSON_FILE="/etc/docker/daemon.json"
    local DOCKER_CMD_LINE=$(ps -ef | grep 'dockerd' | grep -v 'grep' || true)

    local driver=$(docker info --format '{{ .Driver }}' 2>/dev/null)
    if [ "$driver" != "devicemapper" ]; then
        add_summary "$id" "$desc" "PASS"
        return
    fi
    
    local cmd_base_size=$(echo "$DOCKER_CMD_LINE" | grep -o 'dm.basesize=[^ ]*')
    local json_base_size=""
    if [ -f "$DAEMON_JSON_FILE" ]; then
        json_base_size=$(jq -r '."storage-opts"[] | select(. | contains("dm.basesize"))' "$DAEMON_JSON_FILE" 2>/dev/null)
    fi

    if [ -n "$cmd_base_size" ]; then
        add_summary "$id" "$desc" "FAIL"
    elif [ -n "$json_base_size" ]; then
        add_summary "$id" "$desc" "FAIL"
    else
        add_summary "$id" "$desc" "PASS"
    fi
}

# --- Check 2.13 ---
check_2_13() {
    local id="2.13"
    local desc="Ensure that authorization for Docker client commands is enabled (Manual)"

    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Cài đặt jq
sudo apt-get update && sudo apt-get install -y jq"
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
        add_summary "$id" "$desc" "PASS"
    elif [ "$json_auth_plugin" != "null" ] && [ "$json_auth_plugin" != "[]" ]; then
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Bước 1: Cài đặt authorization plugin (ví dụ: opa-docker-authz)
# Download và cài đặt plugin (ví dụ):
# wget https://github.com/open-policy-agent/opa-docker-authz/releases/download/v0.4.4/opa-docker-authz_0.4.4_linux_amd64.tar.gz
# tar -xzf opa-docker-authz_0.4.4_linux_amd64.tar.gz
# sudo mv opa-docker-authz /usr/local/bin/
# Bước 2: Tạo systemd service cho plugin (xem docs của plugin)
# Bước 3: Update daemon.json
sudo apt-get install -y jq
sudo mkdir -p /etc/docker
[ ! -f /etc/docker/daemon.json ] && echo '{}' | sudo tee /etc/docker/daemon.json
sudo jq '. + {\"authorization-plugins\": [\"opa-docker-authz\"]}' /etc/docker/daemon.json > /tmp/daemon.json.tmp
sudo mv /tmp/daemon.json.tmp /etc/docker/daemon.json
sudo systemctl restart docker
# Note: Phải cài plugin authorization thực sự để check pass"
    fi
}

# --- Check 2.14 ---
check_2_14() {
    local id="2.14"
    local desc="Ensure centralized and remote logging is configured (Manual)"

    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Docker chưa được cài đặt
sudo apt-get update && sudo apt-get install -y docker.io
sudo systemctl enable docker && sudo systemctl start docker"
        return
    fi

    # Self-contained command (Corrected PDF template)
    local log_driver=$(docker info --format '{{ .LoggingDriver }}' 2>/dev/null)

    if [ "$log_driver" = "json-file" ]; then
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Cài đặt jq nếu chưa có
sudo apt-get install -y jq
# Tạo daemon.json nếu chưa tồn tại
sudo mkdir -p /etc/docker
[ ! -f /etc/docker/daemon.json ] && echo '{}' | sudo tee /etc/docker/daemon.json
# Option 1: Sử dụng journald (Recommended)
sudo jq '. + {\"log-driver\": \"journald\"}' /etc/docker/daemon.json > /tmp/daemon.json.tmp
sudo mv /tmp/daemon.json.tmp /etc/docker/daemon.json
# Option 2: Sử dụng syslog (uncomment nếu muốn dùng)
# sudo jq '. + {\"log-driver\": \"syslog\", \"log-opts\": {\"syslog-address\": \"tcp://127.0.0.1:514\"}}' /etc/docker/daemon.json > /tmp/daemon.json.tmp
# sudo mv /tmp/daemon.json.tmp /etc/docker/daemon.json
sudo systemctl restart docker
# Verify: docker info --format '{{.LoggingDriver}}'"
    else
        add_summary "$id" "$desc" "PASS"
    fi
}

# --- Check 2.15 ---
check_2_15() {
    local id="2.15"
    local desc="Ensure containers are restricted from acquiring new privileges (Manual)"
    
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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
        add_summary "$id" "$desc" "PASS"
    elif [ "$json_no_new_priv" = "true" ]; then
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
    fi
}

# --- Check 2.16 ---
check_2_16() {
    local id="2.16"
    local desc="Ensure live restore is enabled (Manual)"
    
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
    fi
}

# --- Check 2.17 ---
check_2_17() {
    local id="2.17"
    local desc="Ensure Userland Proxy is Disabled (Manual)"
    
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
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
        add_summary "$id" "$desc" "PASS"
    elif [ "$json_userland_proxy" = "false" ]; then
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
    fi
}

# --- Check 2.18 ---
check_2_18() {
    local id="2.18"
    local desc="Ensure that a daemon-wide custom seccomp profile is applied if appropriate (Manual)"

    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Docker chưa được cài đặt
sudo apt-get update && sudo apt-get install -y docker.io
sudo systemctl enable docker && sudo systemctl start docker"
        return
    fi
    if ! command -v jq &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Cài đặt jq
sudo apt-get update && sudo apt-get install -y jq"
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
        add_summary "$id" "$desc" "INFO"
        echo "       Please confirm this is appropriate for your environment."
    elif [ "$json_seccomp" != "null" ]; then
         add_summary "$id" "$desc" "INFO"
         echo "       Please confirm this is appropriate for your environment."
    elif echo "$info_seccomp" | grep -q 'default'; then
        add_summary "$id" "$desc" "PASS"
    else
        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Tạo custom seccomp profile
sudo mkdir -p /etc/docker/seccomp
# Tạo file seccomp profile (ví dụ minimal)
sudo tee /etc/docker/seccomp/default.json > /dev/null <<'EOF'
{
  \"defaultAction\": \"SCMP_ACT_ERRNO\",
  \"architectures\": [\"SCMP_ARCH_X86_64\", \"SCMP_ARCH_X86\", \"SCMP_ARCH_X32\"],
  \"syscalls\": [
    {\"names\": [\"accept\", \"accept4\", \"access\", \"bind\", \"brk\", \"clone\", \"close\", \"connect\", \"dup\", \"dup2\", \"dup3\", \"epoll_create\", \"epoll_ctl\", \"epoll_wait\", \"execve\", \"exit\", \"exit_group\", \"fcntl\", \"fstat\", \"futex\", \"getcwd\", \"getdents\", \"getegid\", \"geteuid\", \"getgid\", \"getpid\", \"getppid\", \"getuid\", \"listen\", \"lseek\", \"mmap\", \"mprotect\", \"munmap\", \"open\", \"openat\", \"pipe\", \"poll\", \"prctl\", \"read\", \"readlink\", \"recvfrom\", \"recvmsg\", \"rt_sigaction\", \"rt_sigprocmask\", \"rt_sigreturn\", \"sendmsg\", \"sendto\", \"setgid\", \"setgroups\", \"setsockopt\", \"setuid\", \"socket\", \"stat\", \"uname\", \"wait4\", \"write\"], \"action\": \"SCMP_ACT_ALLOW\"}
  ]
}
EOF
# Update daemon.json
sudo apt-get install -y jq
sudo mkdir -p /etc/docker
[ ! -f /etc/docker/daemon.json ] && echo '{}' | sudo tee /etc/docker/daemon.json
sudo jq '. + {\"seccomp-profile\": \"/etc/docker/seccomp/default.json\"}' /etc/docker/daemon.json > /tmp/daemon.json.tmp
sudo mv /tmp/daemon.json.tmp /etc/docker/daemon.json
sudo systemctl restart docker
# Verify: docker info | grep seccomp"
    fi
}

# --- Check 2.19 ---
check_2_19() {
    local id="2.19"
    local desc="Ensure that experimental features are not implemented in production (Manual)"
    
    if ! command -v docker &> /dev/null; then
        add_summary "$id" "$desc" "FAIL"
        return
    fi
    
    # Self-contained command (Corrected PDF template)
    local experimental=$(docker version --format '{{ .Server.Experimental }}' 2>/dev/null)
    
    if [ "$experimental" = "true" ]; then
        add_summary "$id" "$desc" "FAIL"
    else
        add_summary "$id" "$desc" "PASS"
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
    check_2_2
    check_2_3
    check_2_4
    check_2_5
    check_2_6
    check_2_7
    check_2_8
    check_2_9
    check_2_10
    check_2_11
    check_2_12
    check_2_13
    check_2_14
    check_2_15
    check_2_16
    check_2_17
    check_2_18
    check_2_19
    
    echo "================================================================="
    echo "                  Section 2 Checks Complete                    "
    echo "================================================================="

    PASS_COUNT=0
    FAIL_COUNT=0
    INFO_COUNT=0
    log_info "2 - Docker Daemon Configuration"
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
    echo -e "${C_BLUE}===== SUMMARY REPORT =====${NC}"
    echo -e "${C_GREEN}PASS: $PASS_COUNT${NC}"
    echo -e "${C_RED}FAIL: $FAIL_COUNT${NC}"
    echo -e "${C_BLUE}INFO: $INFO_COUNT${NC}"
    echo -e "${C_YELLOW}TOTAL: $((PASS_COUNT + FAIL_COUNT + INFO_COUNT))${NC}"
    echo ""
    echo "=========================================="
    echo "Remediation script for Section 2 finished."
    echo "=========================================="
}

# Execute main function
main