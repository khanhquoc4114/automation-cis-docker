#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cis_log.sh"

# Script remediation cho CIS Docker Benchmark Section 5: Container Runtime Configuration
# Version: 1.8.0

# 5.1 Ensure swarm mode is not Enabled, if not needed (Manual)
remediate_5_1() {
    log_info "5.1 - Checking swarm mode status..."
    
    swarm_status=$(docker info --format '{{ .Swarm.LocalNodeState }}' 2>/dev/null)
    
    if [ "$swarm_status" = "active" ]; then
        log_warn "Swarm mode is enabled. If not needed, run: docker swarm leave"
        log_warn "This is a manual remediation step - please confirm before executing"
        read -p "Do you want to disable swarm mode? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            docker swarm leave --force
            log_info "Swarm mode disabled"
        else
            log_info "Skipping swarm mode disable"
        fi
    else
        log_info "Swarm mode is not enabled - compliant"
    fi
}

# 5.2 Ensure that, if applicable, an AppArmor Profile is enabled (Manual)
remediate_5_2() {
    log_info "5.2 - Checking AppArmor profiles for containers..."
    
    log_warn "This is a manual remediation step"
    log_info "To apply AppArmor profile to containers, use:"
    log_info "docker run --security-opt=\"apparmor:PROFILENAME\" <image>"
    log_info "Or use the default docker-default profile (applied by default)"
}

# 5.3 Ensure that, if applicable, SELinux security options are set (Manual)
remediate_5_3() {
    log_info "5.3 - Checking SELinux security options..."
    
    log_warn "This is a manual remediation step"
    log_info "To enable SELinux for Docker daemon, add to /etc/docker/daemon.json:"
    log_info '{ "selinux-enabled": true }'
    log_info "Then restart Docker daemon"
}

# 5.4 Ensure that Linux kernel capabilities are restricted within containers (Manual)
remediate_5_4() {
    log_info "5.4 - Checking Linux kernel capabilities..."
    
    log_warn "This is a manual remediation step"
    log_info "Drop all capabilities and add only required ones:"
    log_info "docker run --cap-drop=all --cap-add={CAP1,CAP2} <image>"
    log_info "Specifically, drop NET_RAW if not needed:"
    log_info "docker run --cap-drop=NET_RAW <image>"
}

# 5.5 Ensure that privileged containers are not used (Manual)
remediate_5_5() {
    log_info "5.5 - Checking for privileged containers..."
    
    privileged_containers=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Privileged={{ .HostConfig.Privileged }}' 2>/dev/null | grep "Privileged=true")
    
    if [ -n "$privileged_containers" ]; then
        log_error "Found privileged containers:"
        echo "$privileged_containers"
        log_warn "Do not use --privileged flag when running containers"
        log_warn "Recreate containers without --privileged flag"
    else
        log_info "No privileged containers found - compliant"
    fi
}

# 5.6 Ensure sensitive host system directories are not mounted on containers (Manual)
remediate_5_6() {
    log_info "5.6 - Checking for sensitive host directories mounted in containers..."
    
    sensitive_dirs=(/ /boot /dev /etc /lib /lib64 /proc /sys /usr)
    
    log_warn "This is a manual remediation step"
    log_info "Do not mount these sensitive directories: ${sensitive_dirs[*]}"
    log_info "Review container mounts with:"
    log_info "docker ps --quiet | xargs docker inspect --format '{{ .Id }}: Volumes={{ .Mounts }}'"
}

# 5.7 Ensure sshd is not run within containers (Manual)
remediate_5_7() {
    log_info "5.7 - Checking for sshd in containers..."
    
    log_warn "This is a manual remediation step"
    log_info "Use 'docker exec' instead of SSH to access containers"
    log_info "Check for sshd process in each container:"
    log_info "docker exec <container_id> ps -el | grep sshd"
}

# 5.8 Ensure privileged ports are not mapped within containers (Manual)
remediate_5_8() {
    log_info "5.8 - Checking for privileged port mappings..."
    
    privileged_ports=$(docker ps --quiet | xargs docker inspect --format '{{ .Id }}: Ports={{ .NetworkSettings.Ports }}' 2>/dev/null | grep -E ':[0-9]{1,3} ')
    
    log_warn "This is a manual remediation step"
    log_info "Do not map container ports to host ports below 1024"
    log_info "Review current port mappings and recreate containers if needed"
}

# 5.9 Ensure that only needed ports are open on the container (Manual)
remediate_5_9() {
    log_info "5.9 - Checking container port exposure..."
    
    log_warn "This is a manual remediation step"
    log_info "Only expose ports that are needed for the application"
    log_info "Use -p (lowercase) instead of -P flag to explicitly define ports"
    log_info "Example: docker run -p 5000 <image>"
}

# 5.10 Ensure that the host's network namespace is not shared (Manual)
remediate_5_10() {
    log_info "5.10 - Checking for shared host network namespace..."
    
    host_network=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: NetworkMode={{ .HostConfig.NetworkMode }}' 2>/dev/null | grep "NetworkMode=host")
    
    if [ -n "$host_network" ]; then
        log_error "Found containers sharing host network namespace:"
        echo "$host_network"
        log_warn "Do not use --net=host flag when running containers"
    else
        log_info "No containers sharing host network namespace - compliant"
    fi
}

# 5.11 Ensure that the memory usage for containers is limited (Manual)
remediate_5_11() {
    log_info "5.11 - Checking memory limits for containers..."
    
    no_memory_limit=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Memory={{ .HostConfig.Memory }}' 2>/dev/null | grep "Memory=0")
    
    if [ -n "$no_memory_limit" ]; then
        log_warn "Found containers without memory limits:"
        echo "$no_memory_limit"
        log_info "Set memory limits when running containers:"
        log_info "docker run --memory 256m <image>"
    else
        log_info "All containers have memory limits - compliant"
    fi
}

# 5.12 Ensure that CPU priority is set appropriately on containers (Manual)
remediate_5_12() {
    log_info "5.12 - Checking CPU shares for containers..."
    
    default_cpu=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: CpuShares={{ .HostConfig.CpuShares }}' 2>/dev/null | grep -E "CpuShares=(0|1024)")
    
    if [ -n "$default_cpu" ]; then
        log_warn "Found containers with default CPU shares"
        log_info "Set CPU shares based on priority:"
        log_info "docker run --cpu-shares 512 <image>"
    else
        log_info "CPU shares are configured - compliant"
    fi
}

# 5.13 Ensure that the container's root filesystem is mounted as read only (Manual)
remediate_5_13() {
    log_info "5.13 - Checking read-only root filesystem..."
    
    writable_root=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: ReadonlyRootfs={{ .HostConfig.ReadonlyRootfs }}' 2>/dev/null | grep "ReadonlyRootfs=false")
    
    if [ -n "$writable_root" ]; then
        log_warn "Found containers with writable root filesystem"
        log_info "Run containers with read-only root filesystem:"
        log_info "docker run --read-only <image>"
        log_info "Use --tmpfs for temporary writes:"
        log_info "docker run --read-only --tmpfs /tmp <image>"
    else
        log_info "All containers have read-only root filesystem - compliant"
    fi
}

# 5.14 Ensure that incoming container traffic is bound to a specific host interface (Manual)
remediate_5_14() {
    log_info "5.14 - Checking container traffic binding..."
    
    wildcard_binding=$(docker ps --quiet | xargs docker inspect --format '{{ .Id }}: Ports={{ .NetworkSettings.Ports }}' 2>/dev/null | grep "0.0.0.0")
    
    if [ -n "$wildcard_binding" ]; then
        log_warn "Found containers bound to all interfaces (0.0.0.0)"
        log_info "Bind container ports to specific interface:"
        log_info "docker run -p 10.2.3.4:49153:80 <image>"
    else
        log_info "Container traffic properly bound - compliant"
    fi
}

# 5.15 Ensure that the 'on-failure' container restart policy is set to '5' (Manual)
remediate_5_15() {
    log_info "5.15 - Checking container restart policies..."
    
    restart_policy=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: RestartPolicy={{ .HostConfig.RestartPolicy.Name }} MaxRetry={{ .HostConfig.RestartPolicy.MaximumRetryCount }}' 2>/dev/null)
    
    log_warn "Review restart policies for each container"
    log_info "Recommended: use on-failure with max 5 retries:"
    log_info "docker run --restart=on-failure:5 <image>"
}

# 5.16 Ensure that the host's process namespace is not shared (Manual)
remediate_5_16() {
    log_info "5.16 - Checking for shared host process namespace..."
    
    shared_pid=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: PidMode={{ .HostConfig.PidMode }}' 2>/dev/null | grep "PidMode=host")
    
    if [ -n "$shared_pid" ]; then
        log_error "Found containers sharing host process namespace:"
        echo "$shared_pid"
        log_warn "Do not use --pid=host flag when running containers"
    else
        log_info "No containers sharing host process namespace - compliant"
    fi
}

# 5.17 Ensure that the host's IPC namespace is not shared (Manual)
remediate_5_17() {
    log_info "5.17 - Checking for shared host IPC namespace..."
    
    shared_ipc=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: IpcMode={{ .HostConfig.IpcMode }}' 2>/dev/null | grep "IpcMode=host")
    
    if [ -n "$shared_ipc" ]; then
        log_error "Found containers sharing host IPC namespace:"
        echo "$shared_ipc"
        log_warn "Do not use --ipc=host flag when running containers"
    else
        log_info "No containers sharing host IPC namespace - compliant"
    fi
}

# 5.18 Ensure that host devices are not directly exposed to containers (Manual)
remediate_5_18() {
    log_info "5.18 - Checking for directly exposed host devices..."
    
    devices=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Devices={{ .HostConfig.Devices }}' 2>/dev/null | grep -v "Devices=\[\]")
    
    if [ -n "$devices" ]; then
        log_warn "Found containers with exposed host devices:"
        echo "$devices"
        log_info "Only expose devices with appropriate permissions (r, w, m)"
        log_info "Example: docker run --device=/dev/sda:/dev/xvdc:r <image>"
    else
        log_info "No containers with exposed host devices - compliant"
    fi
}

# 5.19 Ensure that the default ulimit is overwritten at runtime if needed (Manual)
remediate_5_19() {
    log_info "5.19 - Checking ulimit overrides..."
    
    ulimit_overrides=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Ulimits={{ .HostConfig.Ulimits }}' 2>/dev/null | grep -v "Ulimits=\[\]")
    
    log_info "Only override ulimits when specifically needed"
    log_info "Example: docker run --ulimit nofile=1024:1024 <image>"
    
    if [ -n "$ulimit_overrides" ]; then
        log_warn "Review ulimit overrides for necessity"
    else
        log_info "No ulimit overrides - using daemon defaults"
    fi
}

# 5.20 Ensure mount propagation mode is not set to shared (Manual)
remediate_5_20() {
    log_info "5.20 - Checking mount propagation modes..."
    
    shared_mounts=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Propagation={{range $mnt := .Mounts}} {{json $mnt.Propagation}} {{end}}' 2>/dev/null | grep "shared")
    
    if [ -n "$shared_mounts" ]; then
        log_warn "Found containers with shared mount propagation:"
        echo "$shared_mounts"
        log_warn "Do not use shared mount propagation mode unless required"
    else
        log_info "No shared mount propagation - compliant"
    fi
}

# 5.21 Ensure that the host's UTS namespace is not shared (Manual)
remediate_5_21() {
    log_info "5.21 - Checking for shared host UTS namespace..."
    
    shared_uts=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: UTSMode={{ .HostConfig.UTSMode }}' 2>/dev/null | grep "UTSMode=host")
    
    if [ -n "$shared_uts" ]; then
        log_error "Found containers sharing host UTS namespace:"
        echo "$shared_uts"
        log_warn "Do not use --uts=host flag when running containers"
    else
        log_info "No containers sharing host UTS namespace - compliant"
    fi
}

# 5.22 Ensure the default seccomp profile is not Disabled (Manual)
remediate_5_22() {
    log_info "5.22 - Checking seccomp profiles..."
    
    unconfined=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: SecurityOpt={{ .HostConfig.SecurityOpt }}' 2>/dev/null | grep "seccomp:unconfined")
    
    if [ -n "$unconfined" ]; then
        log_error "Found containers with disabled seccomp:"
        echo "$unconfined"
        log_warn "Do not use --security-opt=seccomp:unconfined"
        log_warn "Use default seccomp profile or custom profile"
    else
        log_info "Seccomp profiles are enabled - compliant"
    fi
}

# 5.23 Ensure that docker exec commands are not used with the privileged option (Manual)
remediate_5_23() {
    log_info "5.23 - Checking docker exec with privileged option..."
    
    log_warn "This is a manual audit check"
    log_info "If auditing is enabled, check with:"
    log_info "ausearch -k docker | grep exec | grep privileged"
    log_info "Do not use: docker exec --privileged <container> <command>"
}

# 5.24 Ensure that docker exec commands are not used with the user=root option (Manual)
remediate_5_24() {
    log_info "5.24 - Checking docker exec with user=root option..."
    
    log_warn "This is a manual audit check"
    log_info "If auditing is enabled, check with:"
    log_info "ausearch -k docker | grep exec | grep user"
    log_info "Do not use: docker exec --user=root <container> <command>"
}

# 5.25 Ensure that cgroup usage is confirmed (Manual)
remediate_5_25() {
    log_info "5.25 - Checking cgroup usage..."
    
    custom_cgroup=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: CgroupParent={{ .HostConfig.CgroupParent }}' 2>/dev/null | grep -v "CgroupParent=$")
    
    if [ -n "$custom_cgroup" ]; then
        log_warn "Found containers with custom cgroup:"
        echo "$custom_cgroup"
        log_info "Confirm this is intentional and follows security policy"
    else
        log_info "Containers using default cgroup - compliant"
    fi
}

# 5.26 Ensure that the container is restricted from acquiring additional privileges (Manual)
remediate_5_26() {
    log_info "5.26 - Checking no-new-privileges setting..."
    
    no_new_priv=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: SecurityOpt={{ .HostConfig.SecurityOpt }}' 2>/dev/null | grep "no-new-privileges")
    
    if [ -z "$no_new_priv" ]; then
        log_warn "Containers may acquire new privileges"
        log_info "Run containers with no-new-privileges:"
        log_info "docker run --security-opt=no-new-privileges <image>"
    else
        log_info "Containers restricted from acquiring privileges - compliant"
    fi
}

# 5.27 Ensure that container health is checked at runtime (Manual)
remediate_5_27() {
    log_info "5.27 - Checking container health checks..."
    
    no_health=$(docker ps --quiet | xargs docker inspect --format '{{ .Id }}: Health={{ .State.Health.Status }}' 2>/dev/null | grep "Health=<no value>")
    
    if [ -n "$no_health" ]; then
        log_warn "Found containers without health checks"
        log_info "Add health check when running container:"
        log_info "docker run --health-cmd='stat /etc/passwd || exit 1' <image>"
    else
        log_info "All running containers have health checks - compliant"
    fi
}

# 5.28 Ensure that Docker commands always make use of the latest version of their image (Manual)
remediate_5_28() {
    log_info "5.28 - Checking image version pinning..."
    
    log_warn "This is a manual remediation step"
    log_info "Use version pinning to avoid cached older versions:"
    log_info "- Tag specific versions instead of 'latest'"
    log_info "- Use digest pinning: image@sha256:digest"
    log_info "- Regularly pull fresh images: docker pull <image>"
}

# 5.29 Ensure that the PIDs cgroup limit is used (Manual)
remediate_5_29() {
    log_info "5.29 - Checking PIDs cgroup limits..."
    
    no_pids_limit=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: PidsLimit={{ .HostConfig.PidsLimit }}' 2>/dev/null | grep -E "PidsLimit=(0|-1)")
    
    if [ -n "$no_pids_limit" ]; then
        log_warn "Found containers without PIDs limit:"
        echo "$no_pids_limit"
        log_info "Set PIDs limit when running container:"
        log_info "docker run --pids-limit 100 <image>"
    else
        log_info "All containers have PIDs limit - compliant"
    fi
}

# 5.30 Ensure that Docker's default bridge "docker0" is not used (Manual)
remediate_5_30() {
    log_info "5.30 - Checking for default bridge usage..."
    
    default_bridge=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Network={{ .HostConfig.NetworkMode }}' 2>/dev/null | grep "Network=default\|Network=bridge")
    
    if [ -n "$default_bridge" ]; then
        log_warn "Found containers using default bridge:"
        echo "$default_bridge"
        log_info "Create and use user-defined networks:"
        log_info "docker network create --driver bridge custom_network"
        log_info "docker run --network=custom_network <image>"
    else
        log_info "No containers using default bridge - compliant"
    fi
}

# 5.31 Ensure that the host's user namespaces are not shared (Manual)
remediate_5_31() {
    log_info "5.31 - Checking for shared host user namespaces..."
    
    shared_userns=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: UsernsMode={{ .HostConfig.UsernsMode }}' 2>/dev/null | grep "UsernsMode=host")
    
    if [ -n "$shared_userns" ]; then
        log_error "Found containers sharing host user namespaces:"
        echo "$shared_userns"
        log_warn "Do not use --userns=host flag when running containers"
    else
        log_info "No containers sharing host user namespaces - compliant"
    fi
}

# 5.32 Ensure that the Docker socket is not mounted inside any containers (Manual)
remediate_5_32() {
    log_info "5.32 - Checking for mounted Docker socket..."
    
    mounted_socket=$(docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Volumes={{ .Mounts }}' 2>/dev/null | grep "docker.sock")
    
    if [ -n "$mounted_socket" ]; then
        log_error "Found containers with mounted Docker socket:"
        echo "$mounted_socket"
        log_warn "Do not mount /var/run/docker.sock inside containers"
        log_warn "This gives containers full control over the Docker daemon"
    else
        log_info "No containers with mounted Docker socket - compliant"
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "CIS Docker Benchmark Section 5 Remediation"
    echo "Container Runtime Configuration"
    echo "=========================================="
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
    
    # Menu for selective remediation
    if [ "$1" == "--all" ]; then
        for i in {1..32}; do
            eval "remediate_5_$i"
            echo ""
        done
    elif [ -n "$1" ]; then
        # Run specific remediation
        if [ "$1" -ge 1 ] && [ "$1" -le 32 ]; then
            eval "remediate_5_$1"
        else
            log_error "Invalid remediation number. Use 1-32 or --all"
            exit 1
        fi
    else
        log_info "Usage: $0 [--all|1-32]"
        log_info "  --all    : Run all remediations"
        log_info "  1-32     : Run specific remediation (e.g., 1 for 5.1)"
        exit 0
    fi
    
    echo ""
    echo "=========================================="
    echo "Remediation completed"
    echo "=========================================="
}

# Chỉ chạy main khi file được thực thi trực tiếp, không phải khi được source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi