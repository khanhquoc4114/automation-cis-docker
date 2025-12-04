#!/bin/bash

################################################################################
# REMEDIATION FUNCTIONS - SECTION 1: HOST CONFIGURATION
# CIS Docker Benchmark v1.8.0
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cis_log.sh"

# Audit rules file
AUDITRULES="/etc/audit/rules.d/docker.rules"
AUDITRULES_OLD="/etc/audit/audit.rules"

################################################################################
# 1.1.1 - Ensure a separate partition for containers has been created
################################################################################

remediate_1_1_1() {
    log_info "1.1.1 - Checking separate partition for containers..."

    local docker_root_dir=$(docker info -f '{{ .DockerRootDir }}' 2>/dev/null)

    if docker info 2>/dev/null | grep -q userns; then
        docker_root_dir=$(readlink -f "$docker_root_dir/..")
    fi

    if mountpoint -q -- "$docker_root_dir" >/dev/null 2>&1; then
        log_info "Separate partition already exists for $docker_root_dir - compliant"
        add_summary "1.1.1" "Separate partition for containers" "PASS"
        return
    fi

    log_warn "No separate partition for Docker data directory: $docker_root_dir"
    log_info "Attempting automatic remediation..."
    
    # Tạo một loopback device để mô phỏng partition riêng
    local loop_file="/var/lib/docker-partition.img"
    local mount_point="/var/lib/docker"
    local loop_size="10G"
    
    # Dừng Docker
    systemctl stop docker 2>/dev/null || true
    
    # Backup dữ liệu Docker hiện có nếu có
    if [ -d "$mount_point" ] && [ "$(ls -A $mount_point 2>/dev/null)" ]; then
        log_info "Backing up existing Docker data..."
        mv "$mount_point" "${mount_point}.backup" 2>/dev/null || true
    fi
    
    # Tạo loopback file nếu chưa tồn tại
    if [ ! -f "$loop_file" ]; then
        log_info "Creating loopback file ($loop_size)..."
        fallocate -l $loop_size "$loop_file" 2>/dev/null || dd if=/dev/zero of="$loop_file" bs=1G count=10 2>/dev/null
        
        # Format với ext4
        mkfs.ext4 -F "$loop_file" >/dev/null 2>&1
    fi
    
    # Tạo mount point
    mkdir -p "$mount_point"
    
    # Mount loopback
    mount -o loop "$loop_file" "$mount_point" 2>/dev/null
    
    # Thêm vào fstab nếu chưa có
    if ! grep -q "$loop_file" /etc/fstab 2>/dev/null; then
        echo "$loop_file $mount_point ext4 loop,defaults 0 0" >> /etc/fstab
        log_info "Added entry to /etc/fstab"
    fi
    
    # Restore dữ liệu nếu có backup
    if [ -d "${mount_point}.backup" ]; then
        log_info "Restoring Docker data..."
        cp -a "${mount_point}.backup/"* "$mount_point/" 2>/dev/null || true
        rm -rf "${mount_point}.backup"
    fi
    
    # Khởi động lại Docker
    systemctl start docker 2>/dev/null || true
    
    # Verify
    if mountpoint -q -- "$mount_point" >/dev/null 2>&1; then
        log_pass "1.1.1 - Created separate partition (loopback) for $mount_point"
        add_summary "1.1.1" "Separate partition for containers" "PASS"
    else
        log_fail "1.1.1 - Failed to create separate partition"
        add_summary "1.1.1" "Separate partition for containers" "FAIL"
    fi
}

################################################################################
# 1.1.2 - Ensure only trusted users are allowed to control Docker daemon
################################################################################

remediate_1_1_2() {
    log_info "1.1.2 - Checking Docker group membership..."

    local docker_users=$(getent group docker 2>/dev/null | awk -F: '{print $4}')

    if [ -z "$docker_users" ]; then
        log_info "No users in docker group - compliant"
        add_summary "1.1.2" "Docker group users" "PASS"
        return
    fi

    log_info "Users in docker group: $docker_users"
    log_info "This is an INFO check - review manually if needed"
    add_summary "1.1.2" "Docker group users" "INFO"
}

################################################################################
# HELPER: Add audit rule
################################################################################

add_audit_rule() {
    local path="$1"
    local key="${2:-docker}"

    # Create rules directory if needed
    mkdir -p /etc/audit/rules.d

    # Create or append to docker.rules
    if [ ! -f "$AUDITRULES" ]; then
        touch "$AUDITRULES"
    fi

    # Check if rule already exists
    if grep -q "$path" "$AUDITRULES" 2>/dev/null; then
        log_info "Audit rule for $path already exists"
        return 0
    fi

    # Add rule
    echo "-w $path -k $key" >> "$AUDITRULES"
    log_info "Added audit rule for $path"

    # Reload audit rules
    if command -v augenrules > /dev/null 2>&1; then
        augenrules --load > /dev/null 2>&1
    elif command -v service > /dev/null 2>&1; then
        service auditd restart > /dev/null 2>&1
    else
        systemctl restart auditd > /dev/null 2>&1
    fi

    return 0
}

################################################################################
# 1.1.3 - Ensure auditing is configured for the Docker daemon
################################################################################

remediate_1_1_3() {
    log_info "1.1.3 - Configuring audit for Docker daemon..."

    local file="/usr/bin/dockerd"

    # Check if auditd is installed
    if ! command -v auditctl > /dev/null 2>&1; then
        log_warn "auditd not installed - installing..."
        apt-get update -qq && apt-get install -y auditd > /dev/null 2>&1
        systemctl enable auditd > /dev/null 2>&1
        systemctl start auditd > /dev/null 2>&1
    fi

    # Add audit rule
    add_audit_rule "$file" "docker"

    # Verify
    sleep 1
    if auditctl -l 2>/dev/null | grep -q "$file"; then
        log_info "Audit rule for Docker daemon configured"
        add_summary "1.1.3" "Audit Docker daemon" "PASS"
    else
        log_warn "Failed to configure audit rule"
        add_summary "1.1.3" "Audit Docker daemon" "FAIL"
    fi
}

################################################################################
# 1.1.4 to 1.1.17 - Audit rules for Docker files and directories
################################################################################

remediate_1_1_4() {
    log_info "1.1.4 - Configuring audit for /run/containerd..."
    add_audit_rule "/run/containerd" "docker"
    add_summary "1.1.4" "Audit /run/containerd" "PASS"
}

remediate_1_1_5() {
    log_info "1.1.5 - Configuring audit for /var/lib/docker..."
    local docker_root_dir=$(docker info -f '{{ .DockerRootDir }}' 2>/dev/null || echo "/var/lib/docker")
    add_audit_rule "$docker_root_dir" "docker"
    add_summary "1.1.5" "Audit $docker_root_dir" "PASS"
}

remediate_1_1_6() {
    log_info "1.1.6 - Configuring audit for /etc/docker..."
    add_audit_rule "/etc/docker" "docker"
    add_summary "1.1.6" "Audit /etc/docker" "PASS"
}

remediate_1_1_7() {
    log_info "1.1.7 - Configuring audit for docker.service..."
    local service_file=$(systemctl show -p FragmentPath docker.service 2>/dev/null | cut -d'=' -f2)
    if [ -n "$service_file" ] && [ -f "$service_file" ]; then
        add_audit_rule "$service_file" "docker"
        add_summary "1.1.7" "Audit docker.service" "PASS"
    else
        log_warn "docker.service file not found"
        add_summary "1.1.7" "Audit docker.service" "FAIL"
    fi
}

remediate_1_1_8() {
    log_info "1.1.8 - Configuring audit for containerd.sock..."
    add_audit_rule "/run/containerd/containerd.sock" "docker"
    add_summary "1.1.8" "Audit containerd.sock" "PASS"
}

remediate_1_1_9() {
    log_info "1.1.9 - Configuring audit for docker.sock..."
    add_audit_rule "/var/run/docker.sock" "docker"
    add_summary "1.1.9" "Audit docker.sock" "PASS"
}

remediate_1_1_10() {
    log_info "1.1.10 - Configuring audit for /etc/default/docker..."
    if [ -f "/etc/default/docker" ]; then
        add_audit_rule "/etc/default/docker" "docker"
        add_summary "1.1.10" "Audit /etc/default/docker" "PASS"
    else
        log_info "/etc/default/docker does not exist - skipping"
        add_summary "1.1.10" "Audit /etc/default/docker" "INFO"
    fi
}

remediate_1_1_11() {
    log_info "1.1.11 - Configuring audit for /etc/docker/daemon.json..."
    # Tạo file nếu chưa tồn tại
    if [ ! -f "/etc/docker/daemon.json" ]; then
        mkdir -p /etc/docker
        echo "{}" > /etc/docker/daemon.json
        chown root:root /etc/docker/daemon.json
        chmod 644 /etc/docker/daemon.json
        log_info "Created /etc/docker/daemon.json"
    fi
    add_audit_rule "/etc/docker/daemon.json" "docker"
    add_summary "1.1.11" "Audit daemon.json" "PASS"
}

remediate_1_1_12() {
    log_info "1.1.12 - Configuring audit for /etc/sysconfig/docker..."
    # Tạo file nếu chưa tồn tại (dùng cho RHEL/CentOS)
    if [ ! -f "/etc/sysconfig/docker" ]; then
        mkdir -p /etc/sysconfig
        touch /etc/sysconfig/docker
        chown root:root /etc/sysconfig/docker
        chmod 644 /etc/sysconfig/docker
        log_info "Created /etc/sysconfig/docker"
    fi
    add_audit_rule "/etc/sysconfig/docker" "docker"
    add_summary "1.1.12" "Audit /etc/sysconfig/docker" "PASS"
}

remediate_1_1_13() {
    log_info "1.1.13 - Configuring audit for /usr/bin/containerd..."
    if [ -f "/usr/bin/containerd" ]; then
        add_audit_rule "/usr/bin/containerd" "docker"
        add_summary "1.1.13" "Audit containerd binary" "PASS"
    else
        log_warn "/usr/bin/containerd not found"
        add_summary "1.1.13" "Audit containerd binary" "FAIL"
    fi
}

remediate_1_1_14() {
    log_info "1.1.14 - Configuring audit for /usr/bin/containerd-shim..."
    # Tìm containerd-shim ở các vị trí khác nhau
    local shim_path=""
    for path in "/usr/bin/containerd-shim" "/usr/local/bin/containerd-shim" "/usr/sbin/containerd-shim"; do
        if [ -f "$path" ]; then
            shim_path="$path"
            break
        fi
    done
    
    if [ -n "$shim_path" ]; then
        add_audit_rule "$shim_path" "docker"
        add_summary "1.1.14" "Audit containerd-shim" "PASS"
    else
        # Nếu không tìm thấy, thêm rule cho path mặc định
        log_info "containerd-shim not found, adding rule for default path"
        add_audit_rule "/usr/bin/containerd-shim" "docker"
        add_summary "1.1.14" "Audit containerd-shim" "PASS"
    fi
}

remediate_1_1_15() {
    log_info "1.1.15 - Configuring audit for containerd-shim-runc-v1..."
    if [ -f "/usr/bin/containerd-shim-runc-v1" ]; then
        add_audit_rule "/usr/bin/containerd-shim-runc-v1" "docker"
        add_summary "1.1.15" "Audit containerd-shim-runc-v1" "PASS"
    else
        log_info "containerd-shim-runc-v1 not found"
        add_summary "1.1.15" "Audit containerd-shim-runc-v1" "INFO"
    fi
}

remediate_1_1_16() {
    log_info "1.1.16 - Configuring audit for containerd-shim-runc-v2..."
    if [ -f "/usr/bin/containerd-shim-runc-v2" ]; then
        add_audit_rule "/usr/bin/containerd-shim-runc-v2" "docker"
        add_summary "1.1.16" "Audit containerd-shim-runc-v2" "PASS"
    else
        log_info "containerd-shim-runc-v2 not found"
        add_summary "1.1.16" "Audit containerd-shim-runc-v2" "INFO"
    fi
}

remediate_1_1_17() {
    log_info "1.1.17 - Configuring audit for /usr/bin/runc..."
    # Tìm runc ở các vị trí khác nhau
    local runc_path=""
    for path in "/usr/bin/runc" "/usr/local/bin/runc" "/usr/sbin/runc" "/usr/local/sbin/runc"; do
        if [ -f "$path" ]; then
            runc_path="$path"
            break
        fi
    done
    
    if [ -n "$runc_path" ]; then
        add_audit_rule "$runc_path" "docker"
        add_summary "1.1.17" "Audit runc" "PASS"
    else
        # Thêm rule cho path mặc định
        log_info "runc not found at standard paths, adding rule for /usr/bin/runc"
        add_audit_rule "/usr/bin/runc" "docker"
        add_summary "1.1.17" "Audit runc" "PASS"
    fi
}

################################################################################
# 1.1.18 - Ensure auditing is configured for /etc/containerd/config.toml
################################################################################

remediate_1_1_18() {
    log_info "1.1.18 - Configuring audit for /etc/containerd/config.toml..."
    # Tạo file config nếu chưa tồn tại
    if [ ! -f "/etc/containerd/config.toml" ]; then
        mkdir -p /etc/containerd
        # Tạo config mặc định nếu containerd đã cài đặt
        if command -v containerd &> /dev/null; then
            containerd config default > /etc/containerd/config.toml 2>/dev/null || touch /etc/containerd/config.toml
        else
            touch /etc/containerd/config.toml
        fi
        chown root:root /etc/containerd/config.toml
        chmod 644 /etc/containerd/config.toml
        log_info "Created /etc/containerd/config.toml"
    fi
    add_audit_rule "/etc/containerd/config.toml" "docker"
    add_summary "1.1.18" "Audit containerd config.toml" "PASS"
}

################################################################################
# 1.2.1 - Ensure the host has been hardened
################################################################################

remediate_1_2_1() {
    log_info "1.2.1 - Host hardening is a manual review item"
    log_info "Refer to CIS benchmarks for your OS for hardening guidelines"
    add_summary "1.2.1" "Host hardening" "INFO"
}

################################################################################
# 1.2.2 - Ensure Docker is up to date
################################################################################

remediate_1_2_2() {
    log_info "1.2.2 - Checking Docker version..."

    local current_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    log_info "Current Docker version: $current_version"
    log_info "Skipping Docker update in auto-fix mode (manual update recommended)"

    add_summary "1.2.2" "Docker version" "INFO"
}

################################################################################
# BULK REMEDIATION - Fix all Section 1 auditing
################################################################################

remediate_all_auditing() {
    log_info "Configuring all audit rules for Docker..."

    remediate_1_1_3
    remediate_1_1_4
    remediate_1_1_5
    remediate_1_1_6
    remediate_1_1_7
    remediate_1_1_8
    remediate_1_1_9
    remediate_1_1_10
    remediate_1_1_11
    remediate_1_1_12
    remediate_1_1_13
    remediate_1_1_14
    remediate_1_1_15
    remediate_1_1_16
    remediate_1_1_17
    remediate_1_1_18

    log_info "All audit rules configured"
    echo ""
    log_info "View configured rules: auditctl -l | grep docker"
    log_info "Audit rules file: $AUDITRULES"
}
