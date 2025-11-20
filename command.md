You are a senior DevSecOps engineer specialized in CIS Docker Benchmark automation.
Please generate a fully completed Bash script named 3.sh containing all remediation functions for:

Section 3 – Docker Daemon Configuration Files

Follow these rules strictly:

1. Scope

Implement remediation functions for:

3.1 → 3.16

3.23 → 3.24

Skip entirely (do NOT generate any function or text for):

3.17 → 3.22

2. Style requirements

Each function must strictly follow the same structure and behavior as my existing functions remediate_3_1() and remediate_3_2():

Mandatory behavior per function:

Use log_info and log_warn exactly like the examples.

Detect non-compliance first (using stat, grep, etc.)

Show warning before remediation.

Ask for user confirmation:

read -p "Do you want to apply automated remediation? (yes/no): " confirm


If user says yes, apply the correct chmod, chown, or config changes.

If no, skip cleanly.

All paths must follow CIS Benchmark recommended defaults.

Every function name must follow this exact pattern:

remediate_3_X() {
    ...
}


Ensure 100% mapping of all required items.

3. Provided functions (use as template)

Here are the exact reference implementations you MUST mimic:

# 3.1 Ensure that the docker.service file ownership is set to root:root 
```bash
remediate_3_1() {
    log_info "3.1 - Checking docker.service file ownership is set to root:root ..."
    
    ownership=$(stat -c %U:%G /usr/lib/systemd/system/docker.service | grep -v root:root 2>/dev/null)
    
    if [ "$ownership" = "" ]; then
        log_info "docker.service file ownership root:root - compliant"
    else
        log_warn "docker.service file ownership not root:root."
        log_warn "This is an automated remediation step - please confirm before executing"
        read -p "Do you want to use sudo for chmod root:root? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chown root:root /usr/lib/systemd/system/docker.service
            log_info "docker.service file ownership root:root - compliant"
        else
            log_info "Skipping docker.service file ownership is set to root:root "
        fi
    fi
}

# 3.2 Ensure that docker.service file permissions are appropriately set
remediate_3_2() {
    log_info "3.2 - Checking docker.service file permissions are appropriately ..."
    
    ownership=$(stat -c %a /usr/lib/systemd/system/docker.service 2>/dev/null)
    
    if [ "$ownership" = "644" ]; then
        log_info "docker.service file permissions are appropriately - compliant"
    else
        log_warn "docker.service file permissions not 644."
        log_warn "This is an automated remediation step - please confirm before executing"
        read -p "Do you want to use sudo for chmod 644 ? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            chmod 644 /usr/lib/systemd/system/docker.service
            log_info "docker.service file permissions are appropriately - compliant"
        else
            log_info "Skipping docker.service file permissions is set to 644 "
        fi
    fi
}
```
4. Output requirements

Your output must be:

A single script file content for 3.sh

Fully ready to run

Containing:

All remediation functions from 3.1 → 3.16 & 3.23 → 3.26

No missing items

No placeholder text

No explanation text outside code

Must follow CIS Benchmark for Docker 1.6+ or latest stable version

5. Important: mapping details

You must correctly map each item to:

its correct file

expected owner

expected permission

configuration file path

systemd unit files

docker daemon.json settings

socket file permissions

TLS cert file ownership and permission

etc.

Deliver the final answer as a complete Bash script only.