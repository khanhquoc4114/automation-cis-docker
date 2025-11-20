#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/cis_log.sh"

check_4() {
    log_info "4 - Container Images and Build File"
}

check_4_1() {
    local check="4.1 - Ensure that a user for the container has been created"
    
    if [ -z "$containers" ]; then
        log_info "$check - No containers running"
        return
    fi
    
    local fail=0
    for c in $containers; do
        user=$(docker inspect --format 'User={{.Config.User}}' "$c")
        if [ "$user" = "User=0" ] || [ "$user" = "User=root" ] || [ "$user" = "User=" ] || [ "$user" = "User=[]" ]; then
            [ $fail -eq 0 ] && log_warn "$check"
            log_warn "  * Running as root: $c"
            fail=1
        fi
    done
    
    [ $fail -eq 0 ] && log_pass "$check"
}

check_4_2() {
  log_note "4.2 - Ensure that containers use only trusted base images (Manual)"
}

check_4_3() {
  log_note "4.3 - Ensure that unnecessary packages are not installed in the container (Manual)"
}

check_4_4() {
  log_note "4.4 - Ensure images are scanned and rebuilt to include security patches (Manual)"
}

check_4_5() {
    local check="4.5 - Ensure Content trust for Docker is Enabled"
    
    if [ "$DOCKER_CONTENT_TRUST" = "1" ]; then
        log_pass "$check"
    else
        log_warn "$check"
    fi
}

check_4_6() {
    local check="4.6 - Ensure that HEALTHCHECK instructions have been added to container images"
    local fail=0
    
    for img in $images; do
        if docker inspect --format='{{.Config.Healthcheck}}' "$img" 2>/dev/null | grep -e "<nil>" >/dev/null 2>&1; then
            [ $fail -eq 0 ] && log_warn "$check"
            imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
            [ "$imgName" = '[]' ] && imgName="$img"
            log_warn "  * No Healthcheck found: $imgName"
            fail=1
        fi
    done
    
    [ $fail -eq 0 ] && log_pass "$check"
}

check_4_7() {
    local check="4.7 - Ensure update instructions are not used alone in the Dockerfile"
    local fail=0
    
    for img in $images; do
        if docker history "$img" 2>/dev/null | grep -e "update" >/dev/null 2>&1; then
            [ $fail -eq 0 ] && log_info "$check"
            imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
            [ "$imgName" != '[]' ] && log_info "  * Update instruction found: $imgName"
            fail=1
        fi
    done
    
    [ $fail -eq 0 ] && log_pass "$check"
}

check_4_8() {
    log_note "4.8 - Ensure setuid and setgid permissions are removed (Manual)"
}

check_4_9() {
    local check="4.9 - Ensure that COPY is used instead of ADD in Dockerfiles"
    local fail=0
    
    for img in $images; do
        if docker history --format "{{ .CreatedBy }}" --no-trunc "$img" | sed '$d' | grep -q 'ADD'; then
            [ $fail -eq 0 ] && log_info "$check"
            imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
            [ "$imgName" != '[]' ] && log_info "  * ADD in image history: $imgName"
            fail=1
        fi
    done
    
    [ $fail -eq 0 ] && log_pass "$check"
}

check_4_10() {
  log_note "4.10 - Ensure secrets are not stored in Dockerfiles (Manual)"
}

check_4_11() {
    log_note "4.11 - Ensure only verified packages are installed (Manual)"
}

check_4_12() {
  log_note "4.12 - Ensure all signed artifacts are validated (Manual)"
}

check_4_end() {
  echo ""
}

main (){
  echo "================================================================="
  echo "  Running CIS Docker v1.8.0 - Section 4 Checks (Unaltered Mode) "
  echo "================================================================="
  check_4
  check_4_1
  check_4_2
  check_4_3
  check_4_4
  check_4_5
  check_4_6
  check_4_7
  check_4_8
  check_4_9
  check_4_10
  check_4_11
  check_4_12
  echo "================================================================="
  echo "                  Section 4 Checks Complete                    "
  echo "================================================================="
}

main