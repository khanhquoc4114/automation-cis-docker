#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cis_log.sh"
# This script provides remediation functions for CIS Docker Benchmark Section 3.
# It is designed to be sourced and used by a larger compliance script.

# Logging functions


# Variables for TLS file paths, please adjust if your paths are different.
# These are often environment-specific.
TLS_CA_CERT_FILE="/etc/docker/ca.pem"
TLS_SERVER_CERT_FILE="/etc/docker/server-cert.pem"
TLS_SERVER_KEY_FILE="/etc/docker/server-key.pem"

# 3.1 Ensure that the docker.service file ownership is set to root:root
remediate_3_1() {
    log_info "3.1 - Checking docker.service file ownership is set to root:root ..."
    local file_path="/usr/lib/systemd/system/docker.service"
    if [ ! -f "$file_path" ]; then
        log_info "docker.service file not found at $file_path. Skipping."
        return
    fi
    
    ownership=$(stat -c %U:%G "$file_path" 2>/dev/null)
    
    if [ "$ownership" = "root:root" ]; then
        log_info "docker.service file ownership is root:root - compliant"
        add_summary "3.1" "Containerd socket permissions" "PASS"
    else
        log_warn "docker.service file ownership is not root:root (currently $ownership)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:root "$file_path"
            log_info "Set docker.service file ownership to root:root."
            add_summary "3.1" "Containerd socket permissions" "PASS"
        else
            log_info "Skipping docker.service file ownership remediation."
            add_summary "3.1" "Containerd socket permissions" "FAIL"
        fi
    fi
}

# 3.2 Ensure that docker.service file permissions are appropriately set
remediate_3_2() {
    log_info "3.2 - Checking docker.service file permissions are 644 or more restrictive..."
    local file_path="/usr/lib/systemd/system/docker.service"
    if [ ! -f "$file_path" ]; then
        log_info "docker.service file not found at $file_path. Skipping."
        add_summary "3.2" "Ensure that docker.service file permissions are appropriately set" "FAIL"
        return
    fi

    permissions=$(stat -c %a "$file_path" 2>/dev/null)
    
    if [ "$permissions" = "644" ]; then
        log_info "docker.service file permissions are 644 - compliant"
        add_summary "3.2" "Ensure that docker.service file permissions are appropriately set" "PASS"
    else
        log_warn "docker.service file permissions are not 644 (currently $permissions)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 644 "$file_path"
            log_info "Set docker.service file permissions to 644."
            add_summary "3.2" "Ensure that docker.service file permissions are appropriately set" "PASS"
        else
            log_info "Skipping docker.service file permissions remediation."
            add_summary "3.2" "Ensure that docker.service file permissions are appropriately set" "FAIL"
        fi
    fi
}

# 3.3 Ensure that docker.socket file ownership is set to root:root
remediate_3_3() {
    log_info "3.3 - Checking docker.socket file ownership is set to root:root..."
    local file_path="/usr/lib/systemd/system/docker.socket"
    if [ ! -e "$file_path" ]; then
        log_info "docker.socket file not found at $file_path. Skipping."
        return
    fi

    ownership=$(stat -c %U:%G "$file_path" 2>/dev/null)

    if [ "$ownership" = "root:root" ]; then
        log_info "docker.socket file ownership is root:root - compliant"
        add_summary "3.3" "Ensure that docker.socket file ownership is set to root:root" "PASS"
    else
        log_warn "docker.socket file ownership is not root:root (currently $ownership)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:root "$file_path"
            log_info "Set docker.socket file ownership to root:root."
            add_summary "3.3" "Ensure that docker.socket file ownership is set to root:root" "PASS"
        else
            log_info "Skipping docker.socket file ownership remediation."
            add_summary "3.3" "Ensure that docker.socket file ownership is set to root:root" "FAIL"
        fi
    fi
}

# 3.4 Ensure that docker.socket file permissions are set to 644 or more restrictive
remediate_3_4() {
    log_info "3.4 - Checking docker.socket file permissions are 644 or more restrictive..."
    local file_path="/usr/lib/systemd/system/docker.socket"
    if [ ! -e "$file_path" ]; then
        log_info "docker.socket file not found at $file_path. Skipping."
        add_summary "3.4" "Ensure that docker.socket file permissions are set to 644 or more restrictive" "FAIL"
        return
    fi

    permissions=$(stat -c %a "$file_path" 2>/dev/null)

    if [ "$permissions" = "644" ]; then
        log_info "docker.socket file permissions are 644 - compliant"
        add_summary "3.4" "Ensure that docker.socket file permissions are set to 644 or more restrictive" "PASS"
    else
        log_warn "docker.socket file permissions are not 644 (currently $permissions)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 644 "$file_path"
            log_info "Set docker.socket file permissions to 644."
            add_summary "3.4" "Ensure that docker.socket file permissions are set to 644 or more restrictive" "PASS"
        else
            log_info "Skipping docker.socket file permissions remediation."
            add_summary "3.4" "Ensure that docker.socket file permissions are set to 644 or more restrictive" "FAIL"
        fi
    fi
}

# 3.5 Ensure that the /etc/docker directory ownership is set to root:root
remediate_3_5() {
    log_info "3.5 - Checking /etc/docker directory ownership is set to root:root..."
    local dir_path="/etc/docker"
    if [ ! -d "$dir_path" ]; then
        log_info "/etc/docker directory not found. Skipping."
        add_summary "3.5" "Ensure that the /etc/docker directory ownership is set to root:root" "FAIL"
        return
    fi

    ownership=$(stat -c %U:%G "$dir_path" 2>/dev/null)

    if [ "$ownership" = "root:root" ]; then
        log_info "/etc/docker directory ownership is root:root - compliant"
        add_summary "3.5" "Ensure that the /etc/docker directory ownership is set to root:root" "PASS"
    else
        log_warn "/etc/docker directory ownership is not root:root (currently $ownership)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:root "$dir_path"
            log_info "Set /etc/docker directory ownership to root:root."
            add_summary "3.5" "Ensure that the /etc/docker directory ownership is set to root:root" "PASS"
        else
            log_info "Skipping /etc/docker directory ownership remediation."
            add_summary "3.5" "Ensure that the /etc/docker directory ownership is set to root:root" "FAIL"
        fi
    fi
}

# 3.6 Ensure that /etc/docker directory permissions are set to 755 or more restrictively
remediate_3_6() {
    log_info "3.6 - Checking /etc/docker directory permissions are 755 or more restrictive..."
    local dir_path="/etc/docker"
    if [ ! -d "$dir_path" ]; then
        log_info "/etc/docker directory not found. Skipping."
        add_summary "3.6" "Ensure that /etc/docker directory permissions are set to 755 or more restrictively" "FAIL"
        return
    fi

    permissions=$(stat -c %a "$dir_path" 2>/dev/null)

    if [ "$permissions" = "755" ]; then
        log_info "/etc/docker directory permissions are 755 - compliant"
        add_summary "3.6" "Ensure that /etc/docker directory permissions are set to 755 or more restrictively" "PASS"
    else
        log_warn "/etc/docker directory permissions are not 755 (currently $permissions)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 755 "$dir_path"
            log_info "Set /etc/docker directory permissions to 755."
            add_summary "3.6" "Ensure that /etc/docker directory permissions are set to 755 or more restrictively" "PASS"
        else
            log_info "Skipping /etc/docker directory permissions remediation."
            add_summary "3.6" "Ensure that /etc/docker directory permissions are set to 755 or more restrictively" "FAIL"
        fi
    fi
}

# 3.7 Ensure that registry certificate file ownership is set to root:root
remediate_3_7() {
    log_info "3.7 - Checking registry certificate file ownership..."
    local certs_dir="/etc/docker/certs.d"
    if [ ! -d "$certs_dir" ]; then
        log_info "Registry certificates directory not found at $certs_dir. Skipping."
        add_summary "3.7" "Ensure that registry certificate file ownership is set to root:root" "FAIL"
        return
    fi

    non_compliant_files=$(find "$certs_dir" -type f -not -user root -o -not -group root 2>/dev/null)

    if [ -z "$non_compliant_files" ]; then
        log_info "All registry certificate files are owned by root:root - compliant."
        add_summary "3.7" "Ensure that registry certificate file ownership is set to root:root" "PASS"
    else
        log_warn "Found registry certificate files not owned by root:root:"
        log_warn "$non_compliant_files"
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown -R root:root "$certs_dir"
            log_info "Set ownership of all files in $certs_dir to root:root."
            add_summary "3.7" "Ensure that registry certificate file ownership is set to root:root" "PASS"
        else
            log_info "Skipping registry certificate files ownership remediation."
            add_summary "3.7" "Ensure that registry certificate file ownership is set to root:root" "FAIL"
        fi
    fi
}

# 3.8 Ensure that registry certificate file permissions are set to 444 or more restrictively
remediate_3_8() {
    log_info "3.8 - Checking registry certificate file permissions are 444 or more restrictive..."
    local certs_dir="/etc/docker/certs.d"
    if [ ! -d "$certs_dir" ]; then
        log_info "Registry certificates directory not found at $certs_dir. Skipping."
        add_summary "3.8" "Ensure that registry certificate file permissions are set to 444 or more restrictively" "FAIL"
        return
    fi

    non_compliant_files=$(find "$certs_dir" -type f ! -perm 444 2>/dev/null)

    if [ -z "$non_compliant_files" ]; then
        log_info "All registry certificate file permissions are 444 - compliant."
        add_summary "3.8" "Ensure that registry certificate file permissions are set to 444 or more restrictively" "PASS"
    else
        log_warn "Found registry certificate files with permissions other than 444:"
        log_warn "$non_compliant_files"
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            find "$certs_dir" -type f -exec chmod 444 {} +
            log_info "Set permissions of all files in $certs_dir to 444."
            add_summary "3.8" "Ensure that registry certificate file permissions are set to 444 or more restrictively" "PASS"
        else
            log_info "Skipping registry certificate files permissions remediation."
            add_summary "3.8" "Ensure that registry certificate file permissions are set to 444 or more restrictively" "FAIL"
        fi
    fi
}

# 3.9 Ensure that TLS CA certificate file ownership is set to root:root
remediate_3_9() {
    log_info "3.9 - Checking TLS CA certificate file ownership is set to root:root..."
    if [ ! -f "$TLS_CA_CERT_FILE" ]; then
        log_warn "TLS CA certificate file not found at $TLS_CA_CERT_FILE. Skipping."
        add_summary "3.9" "Ensure that TLS CA certificate file ownership is set to root:root" "FAIL"
        return
    fi

    ownership=$(stat -c %U:%G "$TLS_CA_CERT_FILE" 2>/dev/null)

    if [ "$ownership" = "root:root" ]; then
        log_info "TLS CA certificate file ownership is root:root - compliant."
        add_summary "3.9" "Ensure that TLS CA certificate file ownership is set to root:root" "PASS"
    else
        log_warn "TLS CA certificate file ownership is not root:root (currently $ownership)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:root "$TLS_CA_CERT_FILE"
            log_info "Set TLS CA certificate file ownership to root:root."
            add_summary "3.9" "Ensure that TLS CA certificate file ownership is set to root:root" "PASS"
        else
            log_info "Skipping TLS CA certificate file ownership remediation."
            add_summary "3.9" "Ensure that TLS CA certificate file ownership is set to root:root" "FAIL"
        fi
    fi
}

# 3.10 Ensure that TLS CA certificate file permissions are set to 444 or more restrictively
remediate_3_10() {
    log_info "3.10 - Checking TLS CA certificate file permissions are 444 or more restrictive..."
    if [ ! -f "$TLS_CA_CERT_FILE" ]; then
        log_warn "TLS CA certificate file not found at $TLS_CA_CERT_FILE. Skipping."
        add_summary "3.10" "Ensure that TLS CA certificate file permissions are set to 444 or more restrictively" "FAIL"
        return
    fi

    permissions=$(stat -c %a "$TLS_CA_CERT_FILE" 2>/dev/null)

    if [ "$permissions" = "444" ]; then
        log_info "TLS CA certificate file permissions are 444 - compliant."
        add_summary "3.10" "Ensure that TLS CA certificate file permissions are set to 444 or more restrictively" "PASS"
    else
        log_warn "TLS CA certificate file permissions are not 444 (currently $permissions)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 444 "$TLS_CA_CERT_FILE"
            log_info "Set TLS CA certificate file permissions to 444."
            add_summary "3.10" "Ensure that TLS CA certificate file permissions are set to 444 or more restrictively" "PASS"
        else
            log_info "Skipping TLS CA certificate file permissions remediation."
            add_summary "3.10" "Ensure that TLS CA certificate file permissions are set to 444 or more restrictively" "FAIL"
        fi
    fi
}

# 3.11 Ensure that Docker server certificate file ownership is set to root:root
remediate_3_11() {
    log_info "3.11 - Checking Docker server certificate file ownership is set to root:root..."
    if [ ! -f "$TLS_SERVER_CERT_FILE" ]; then
        log_warn "TLS server certificate file not found at $TLS_SERVER_CERT_FILE. Skipping."
        add_summary "3.11" "Ensure that Docker server certificate file ownership is set to root:root" "FAIL"
        return
    fi

    ownership=$(stat -c %U:%G "$TLS_SERVER_CERT_FILE" 2>/dev/null)

    if [ "$ownership" = "root:root" ]; then
        log_info "Docker server certificate file ownership is root:root - compliant."
        add_summary "3.11" "Ensure that Docker server certificate file ownership is set to root:root" "PASS"
    else
        log_warn "Docker server certificate file ownership is not root:root (currently $ownership)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:root "$TLS_SERVER_CERT_FILE"
            log_info "Set Docker server certificate file ownership to root:root."
            add_summary "3.11" "Ensure that Docker server certificate file ownership is set to root:root" "PASS"
        else
            log_info "Skipping Docker server certificate file ownership remediation."
            add_summary "3.11" "Ensure that Docker server certificate file ownership is set to root:root" "FAIL"
        fi
    fi
}

# 3.12 Ensure that the Docker server certificate file permissions are set to 444 or more restrictively
remediate_3_12() {
    log_info "3.12 - Checking Docker server certificate file permissions are 444 or more restrictive..."
    if [ ! -f "$TLS_SERVER_CERT_FILE" ]; then
        log_warn "TLS server certificate file not found at $TLS_SERVER_CERT_FILE. Skipping."
        add_summary "3.12" "Ensure that the Docker server certificate file permissions are set to 444 or more restrictively" "FAIL"
        return
    fi

    permissions=$(stat -c %a "$TLS_SERVER_CERT_FILE" 2>/dev/null)

    if [ "$permissions" = "444" ]; then
        log_info "Docker server certificate file permissions are 444 - compliant."
        add_summary "3.12" "Ensure that the Docker server certificate file permissions are set to 444 or more restrictively" "PASS"
    else
        log_warn "Docker server certificate file permissions are not 444 (currently $permissions)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 444 "$TLS_SERVER_CERT_FILE"
            log_info "Set Docker server certificate file permissions to 444."
            add_summary "3.12" "Ensure that the Docker server certificate file permissions are set to 444 or more restrictively" "PASS"
        else
            log_info "Skipping Docker server certificate file permissions remediation."
            add_summary "3.12" "Ensure that the Docker server certificate file permissions are set to 444 or more restrictively" "FAIL"
        fi
    fi
}

# 3.13 Ensure that the Docker server certificate key file ownership is set to root:root
remediate_3_13() {
    log_info "3.13 - Checking Docker server certificate key file ownership is set to root:root..."
    if [ ! -f "$TLS_SERVER_KEY_FILE" ]; then
        log_warn "TLS server certificate key file not found at $TLS_SERVER_KEY_FILE. Skipping."
        add_summary "3.13" "Ensure that the Docker server certificate key file ownership is set to root:root" "FAIL"
        return
    fi

    ownership=$(stat -c %U:%G "$TLS_SERVER_KEY_FILE" 2>/dev/null)

    if [ "$ownership" = "root:root" ]; then
        log_info "Docker server certificate key file ownership is root:root - compliant."
        add_summary "3.13" "Ensure that the Docker server certificate key file ownership is set to root:root" "PASS"
    else
        log_warn "Docker server certificate key file ownership is not root:root (currently $ownership)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:root "$TLS_SERVER_KEY_FILE"
            log_info "Set Docker server certificate key file ownership to root:root."
            add_summary "3.13" "Ensure that the Docker server certificate key file ownership is set to root:root" "PASS"
        else
            log_info "Skipping Docker server certificate key file ownership remediation."
            add_summary "3.13" "Ensure that the Docker server certificate key file ownership is set to root:root" "FAIL"
        fi
    fi
}

# 3.14 Ensure that the Docker server certificate key file permissions are set to 400
remediate_3_14() {
    log_info "3.14 - Checking Docker server certificate key file permissions are set to 400..."
    if [ ! -f "$TLS_SERVER_KEY_FILE" ]; then
        log_warn "TLS server certificate key file not found at $TLS_SERVER_KEY_FILE. Skipping."
        add_summary "3.14" "Ensure that the Docker server certificate key file permissions are set to 400" "FAIL"
        return
    fi

    permissions=$(stat -c %a "$TLS_SERVER_KEY_FILE" 2>/dev/null)

    if [ "$permissions" = "400" ]; then
        log_info "Docker server certificate key file permissions are 400 - compliant."
        add_summary "3.14" "Ensure that the Docker server certificate key file permissions are set to 400" "PASS"
    else
        log_warn "Docker server certificate key file permissions are not 400 (currently $permissions)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 400 "$TLS_SERVER_KEY_FILE"
            log_info "Set Docker server certificate key file permissions to 400."
            add_summary "3.14" "Ensure that the Docker server certificate key file permissions are set to 400" "PASS"
        else
            log_info "Skipping Docker server certificate key file permissions remediation."
            add_summary "3.14" "Ensure that the Docker server certificate key file permissions are set to 400" "FAIL"
        fi
    fi
}

# 3.15 Ensure that the Docker socket file ownership is set to root:docker
remediate_3_15() {
    log_info "3.15 - Checking Docker socket file ownership is set to root:docker..."
    local file_path="/var/run/docker.sock"
    if [ ! -e "$file_path" ]; then
        log_info "Docker socket file not found at $file_path. Skipping."
        add_summary "3.15" "Ensure that the Docker socket file ownership is set to root:docker" "FAIL"
        return
    fi

    ownership=$(stat -c %U:%G "$file_path" 2>/dev/null)

    if [ "$ownership" = "root:docker" ]; then
        log_info "Docker socket file ownership is root:docker - compliant."
        add_summary "3.15" "Ensure that the Docker socket file ownership is set to root:docker" "PASS"
    else
        log_warn "Docker socket file ownership is not root:docker (currently $ownership)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:docker "$file_path"
            log_info "Set Docker socket file ownership to root:docker."
            add_summary "3.15" "Ensure that the Docker socket file ownership is set to root:docker" "PASS"
        else
            log_info "Skipping Docker socket file ownership remediation."
            add_summary "3.15" "Ensure that the Docker socket file ownership is set to root:docker" "FAIL"
        fi
    fi
}

# 3.16 Ensure that the Docker socket file permissions are set to 660 or more restrictively
remediate_3_16() {
    log_info "3.16 - Checking Docker socket file permissions are 660 or more restrictive..."
    local file_path="/var/run/docker.sock"
    if [ ! -e "$file_path" ]; then
        log_info "Docker socket file not found at $file_path. Skipping."
        add_summary "3.16" "Ensure that the Docker socket file permissions are set to 660 or more restrictively" "FAIL"
        return
    fi

    permissions=$(stat -c %a "$file_path" 2>/dev/null)

    if [ "$permissions" = "660" ]; then
        log_info "Docker socket file permissions are 660 - compliant."
        add_summary "3.16" "Ensure that the Docker socket file permissions are set to 660 or more restrictively" "PASS"
    else
        log_warn "Docker socket file permissions are not 660 (currently $permissions)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 660 "$file_path"
            log_info "Set Docker socket file permissions to 660."
            add_summary "3.16" "Ensure that the Docker socket file permissions are set to 660 or more restrictively" "PASS"
        else
            log_info "Skipping Docker socket file permissions remediation."
            add_summary "3.16" "Ensure that the Docker socket file permissions are set to 660 or more restrictively" "FAIL"
        fi
    fi
}

# 3.23 Ensure that the Containerd socket file ownership is set to root:root
remediate_3_23() {
    log_info "3.23 - Checking Containerd socket file ownership is set to root:root..."
    local file_path="/run/containerd/containerd.sock"
    if [ ! -e "$file_path" ]; then
        log_info "Containerd socket file not found at $file_path. Skipping."
        add_summary "3.23" "Ensure that the Containerd socket file ownership is set to root:root" "FAIL"
        return
    fi

    ownership=$(stat -c %U:%G "$file_path" 2>/dev/null)

    if [ "$ownership" = "root:root" ]; then
        log_info "Containerd socket file ownership is root:root - compliant."
        add_summary "3.23" "Ensure that the Containerd socket file ownership is set to root:root" "PASS"
    else
        log_warn "Containerd socket file ownership is not root:root (currently $ownership)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:root "$file_path"
            log_info "Set Containerd socket file ownership to root:root."
            add_summary "3.23" "Ensure that the Containerd socket file ownership is set to root:root" "PASS"
        else
            log_info "Skipping Containerd socket file ownership remediation."
            add_summary "3.23" "Ensure that the Containerd socket file ownership is set to root:root" "FAIL"
        fi
    fi
}

# 3.24 Ensure that the Containerd socket file permissions are set to 660 or more restrictively
remediate_3_24() {
    log_info "3.24 - Checking Containerd socket file permissions are 660 or more restrictive..."
    local file_path="/run/containerd/containerd.sock"
    if [ ! -e "$file_path" ]; then
        log_info "Containerd socket file not found at $file_path. Skipping."
        add_summary "3.24" "Ensure that the Containerd socket file permissions are set to 660 or more restrictively" "FAIL"
        return
    fi

    permissions=$(stat -c %a "$file_path" 2>/dev/null)

    if [ "$permissions" = "660" ]; then
        log_info "Containerd socket file permissions are 660 - compliant."
        add_summary "3.24" "Ensure that the Containerd socket file permissions are set to 660 or more restrictively" "PASS"
    else
        log_warn "Containerd socket file permissions are not 660 (currently $permissions)."
        read -p "Do you want to apply automated remediation? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 660 "$file_path"
            log_info "Set Containerd socket file permissions to 660."
            add_summary "3.24" "Ensure that the Containerd socket file permissions are set to 660 or more restrictively" "PASS"
        else
            log_info "Skipping Containerd socket file permissions remediation."
            add_summary "3.24" "Ensure that the Containerd socket file permissions are set to 660 or more restrictively" "FAIL"
        fi
    fi
}

run_all_remediations() {
    remediate_3_1; echo ""
    remediate_3_2; echo ""
    remediate_3_3; echo ""
    remediate_3_4; echo ""
    remediate_3_5; echo ""
    remediate_3_6; echo ""
    remediate_3_7; echo ""
    remediate_3_8; echo ""
    remediate_3_9; echo ""
    remediate_3_10; echo ""
    remediate_3_11; echo ""
    remediate_3_12; echo ""
    remediate_3_13; echo ""
    remediate_3_14; echo ""
    remediate_3_15; echo ""
    remediate_3_16; echo ""
    remediate_3_23; echo ""
    remediate_3_24; echo ""
}

main() {
    echo "=============================================="
    echo "CIS Docker Benchmark Section 3 Remediation"
    echo "Docker Daemon Configuration Files"
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

    # Menu for selective remediation
    if [ "$1" == "--all" ]; then
        log_info "Running all remediations for Section 3..."
        run_all_remediations
    elif [ -n "$1" ]; then
        # Run specific remediation
        func_name="remediate_3_$1"
        if [ "$(type -t "$func_name")" = "function" ]; then
            eval "$func_name"
        else
            log_error "Invalid remediation number: $1. Use a valid number (e.g., 1 for 3.1) or --all"
            exit 1
        fi
    else
        log_info "Usage: $0 [--all|<remediation_number>]"
        log_info "  --all    : Run all remediations for Section 3"
        log_info "  e.g., 1  : Run specific remediation for 3.1"
        log_info "Valid numbers are: 1-16, 23-24"
        exit 0
    fi
    
    PASS_COUNT=0
    FAIL_COUNT=0
    log_info "3 - Docker Daemon Configuration Files"
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
        esac
    done
    echo -e "${C_BLUE}===== SUMMARY REPORT =====${NC}"
    echo -e "${C_GREEN}PASS: $PASS_COUNT${NC}"
    echo -e "${C_RED}FAIL: $FAIL_COUNT${NC}"
    echo -e "${C_YELLOW}TOTAL: $((PASS_COUNT + FAIL_COUNT))${NC}"
    echo ""
    echo "=========================================="
    echo "Remediation script for Section 3 finished."
    echo "=========================================="
}

# Chỉ chạy main khi file được thực thi trực tiếp, không phải khi được source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi