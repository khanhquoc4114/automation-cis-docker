#!/bin/bash

# Thay đổi thư mục làm việc thành thư mục chứa tập lệnh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "$SCRIPT_DIR" >/dev/null

# Lấy nguồn tệp cis_log.sh từ cùng thư mục
source "./cis_log.sh"

check_4() {
    log_info "4 - Container Images and Build File"
}

check_4_1() {
    local id="4.1"
    local desc="Ensure that a user for the container has been created"
    
    if [ -z "$containers" ]; then
        add_summary "$id" "$desc" "INFO"
        echo "     * No containers running"
        return
    fi
    
    local fail=0
    for c in $containers; do
        user=$(docker inspect --format 'User={{.Config.User}}' "$c")
        if [ "$user" = "User=0" ] || [ "$user" = "User=root" ] || [ "$user" = "User=" ] || [ "$user" = "User=[]" ]; then
            [ $fail -eq 0 ] && add_summary "$id" "$desc" "FAIL"
            echo "  * Running as root: $c"
            fail=1
        fi
    done
    
    [ $fail -eq 0 ] && add_summary "$id" "$desc" "PASS"
}

check_4_2() {

  add_summary "4.2" "Ensure that containers use only trusted base images (Manual)" "INFO"

}



check_4_3() {

  add_summary "4.3" "Ensure that unnecessary packages are not installed in the container (Manual)" "INFO"

}



check_4_4() {

  add_summary "4.4" "Ensure images are scanned and rebuilt to include security patches (Manual)" "INFO"

}



check_4_5() {

    local id="4.5"

    local desc="Ensure Content trust for Docker is Enabled"



    if [ "$DOCKER_CONTENT_TRUST" = "1" ]; then

        add_summary "$id" "$desc" "PASS"

    else

        add_summary "$id" "$desc" "FAIL"
        add_remediation "$id" "# Thêm DOCKER_CONTENT_TRUST vào /etc/environment
grep -q 'DOCKER_CONTENT_TRUST=1' /etc/environment || echo 'DOCKER_CONTENT_TRUST=1' | sudo tee -a /etc/environment
# Tạo profile.d script
echo 'export DOCKER_CONTENT_TRUST=1' | sudo tee /etc/profile.d/docker-content-trust.sh
sudo chmod 644 /etc/profile.d/docker-content-trust.sh
# Áp dụng cho session hiện tại
export DOCKER_CONTENT_TRUST=1
# Verify (sau khi logout/login hoặc source):
# echo \$DOCKER_CONTENT_TRUST"

    fi

}



check_4_6() {

    local id="4.6"

    local desc="Ensure that HEALTHCHECK instructions have been added to container images"

    local fail=0

    

    for img in $images; do

        if docker inspect --format='{{.Config.Healthcheck}}' "$img" 2>/dev/null | grep -e "<nil>" >/dev/null 2>&1; then

            [ $fail -eq 0 ] && add_summary "$id" "$desc" "FAIL"

            imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)

            [ "$imgName" = '[]' ] && imgName="$img"

            echo "  * No Healthcheck found: $imgName"

            fail=1

        fi

    done

    

    [ $fail -eq 0 ] && add_summary "$id" "$desc" "PASS"

}



check_4_7() {

    local id="4.7"

    local desc="Ensure update instructions are not used alone in the Dockerfile"

    local fail=0

    

    for img in $images; do

        if docker history "$img" 2>/dev/null | grep -e "update" >/dev/null 2>&1; then

            [ $fail -eq 0 ] && add_summary "$id" "$desc" "INFO"

            imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)

            [ "$imgName" != '[]' ] && echo "  * Update instruction found: $imgName"

            fail=1

        fi

    done

    

    [ $fail -eq 0 ] && add_summary "$id" "$desc" "PASS"

}



check_4_8() {

  add_summary "4.8" "Ensure setuid and setgid permissions are removed (Manual)" "INFO"

}



check_4_9() {

    local id="4.9"

    local desc="Ensure that COPY is used instead of ADD in Dockerfiles"

    local fail=0

    

    for img in $images; do

        if docker history --format "{{ .CreatedBy }}" --no-trunc "$img" | sed '$d' | grep -q 'ADD'; then

            [ $fail -eq 0 ] && add_summary "$id" "$desc" "INFO"

            imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)

            [ "$imgName" != '[]' ] && echo "  * ADD in image history: $imgName"

            fail=1

        fi

    done

    

    [ $fail -eq 0 ] && add_summary "$id" "$desc" "PASS"

}



check_4_10() {

  add_summary "4.10" "Ensure secrets are not stored in Dockerfiles (Manual)" "INFO"

}



check_4_11() {

    add_summary "4.11" "Ensure only verified packages are installed (Manual)" "INFO"

}



check_4_12() {

  add_summary "4.12" "Ensure all signed artifacts are validated (Manual)" "INFO"

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



    PASS_COUNT=0

    FAIL_COUNT=0

    INFO_COUNT=0

    log_info "4 - Container Images and Build File"

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

    echo "Remediation script for Section 4 finished."

    echo "=========================================="

}



main
