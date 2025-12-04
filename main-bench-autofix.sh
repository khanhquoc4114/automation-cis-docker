#!/bin/bash

################################################################################
# AUTO-FIX SCRIPT - CIS DOCKER BENCHMARK
# Mục đích: Chạy test → Phát hiện FAIL → Auto remediation → Test lại
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"
CONFIG_DIR="$SCRIPT_DIR/config"
TEMP_DIR="$SCRIPT_DIR/temp"
LOG_FILE="$TEMP_DIR/autofix.log"

# Create temp directory
mkdir -p "$TEMP_DIR"

################################################################################
# HELPER FUNCTIONS
################################################################################

print_banner() {
    echo -e "\n${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${YELLOW}$1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

################################################################################
# MAIN FUNCTIONS
################################################################################

run_tests() {
    local output_file="$1"
    print_info "Chạy CIS Docker Benchmark tests..."

    cd "$SCRIPT_DIR"
    bash main-bench.sh > "$output_file" 2>&1

    print_success "Hoàn thành tests"
}

parse_failures() {
    local output_file="$1"
    local fail_list="$TEMP_DIR/fail_list.txt"

    print_info "Phân tích kết quả FAIL..."

    # Extract FAIL items with their IDs (e.g., "3.2", "5.4")
    grep -E "^\[FAIL\]" "$output_file" | \
        grep -oE "[0-9]+\.[0-9]+(\.[0-9]+)?" | \
        sort -u > "$fail_list"

    local fail_count=$(wc -l < "$fail_list")

    if [ "$fail_count" -eq 0 ]; then
        print_success "Không có FAIL nào!"
        return 0
    fi

    print_warning "Tìm thấy $fail_count FAIL items"
    echo ""

    return 1
}

apply_remediations() {
    local fail_list="$TEMP_DIR/fail_list.txt"
    local fixed_count=0
    local skipped_count=0

    print_banner "BẮT ĐẦU AUTO-REMEDIATION"

    while IFS= read -r fail_id; do
        # Convert fail_id to function name (e.g., "3.2" -> "remediate_3_2")
        local func_name="remediate_${fail_id//./_}"

        # Determine which config file to source
        local section=$(echo "$fail_id" | cut -d'.' -f1)
        local config_file="$CONFIG_DIR/${section}.sh"

        if [ ! -f "$config_file" ]; then
            print_warning "Bỏ qua $fail_id: Không tìm thấy $config_file"
            ((skipped_count++))
            continue
        fi

        # Source the config file
        source "$config_file"

        # Check if remediation function exists
        if ! declare -f "$func_name" > /dev/null; then
            print_warning "Bỏ qua $fail_id: Không có function $func_name"
            ((skipped_count++))
            continue
        fi

        print_info "Đang fix: $fail_id với $func_name"

        # Run remediation - call function directly
        $func_name 2>&1 | tee -a "$LOG_FILE"

        ((fixed_count++))
        echo ""

    done < "$fail_list"

    echo ""
    print_success "Đã chạy remediation cho $fixed_count items"

    if [ "$skipped_count" -gt 0 ]; then
        print_warning "Bỏ qua $skipped_count items (không có remediation function)"
    fi

    echo ""
}

show_summary() {
    local before_file="$1"
    local after_file="$2"

    print_banner "TỔNG KẾT"

    # Parse before results
    local before_fail=$(grep -E "^TOTAL FAIL:" "$before_file" | grep -oE "[0-9]+" || echo "0")
    local before_pass=$(grep -E "^TOTAL PASS:" "$before_file" | grep -oE "[0-9]+" || echo "0")

    # Parse after results
    local after_fail=$(grep -E "^TOTAL FAIL:" "$after_file" | grep -oE "[0-9]+" || echo "0")
    local after_pass=$(grep -E "^TOTAL PASS:" "$after_file" | grep -oE "[0-9]+" || echo "0")

    # Calculate improvements
    local fixed=$((before_fail - after_fail))
    local improved_pass=$((after_pass - before_pass))

    echo -e "${BOLD}Trước khi fix:${NC}"
    echo -e "  PASS: ${GREEN}$before_pass${NC}"
    echo -e "  FAIL: ${RED}$before_fail${NC}"
    echo ""

    echo -e "${BOLD}Sau khi fix:${NC}"
    echo -e "  PASS: ${GREEN}$after_pass${NC}"
    echo -e "  FAIL: ${RED}$after_fail${NC}"
    echo ""

    if [ "$fixed" -gt 0 ]; then
        echo -e "${BOLD}${GREEN}✓ Đã fix thành công: $fixed items${NC}"
    fi

    if [ "$after_fail" -eq 0 ]; then
        echo -e "\n${BOLD}${GREEN}🎉 HOÀN HẢO! Không còn FAIL nào!${NC}\n"
    elif [ "$after_fail" -lt "$before_fail" ]; then
        echo -e "\n${BOLD}${YELLOW}⚠ Còn lại $after_fail FAIL items chưa được fix${NC}"
        echo -e "${YELLOW}Một số items có thể cần fix thủ công hoặc không có remediation${NC}\n"
    else
        echo -e "\n${BOLD}${RED}⚠ Không có cải thiện. Có thể cần kiểm tra lại.${NC}\n"
    fi
}

show_remaining_fails() {
    local after_file="$1"

    local remaining=$(grep -E "^\[FAIL\]" "$after_file" | wc -l)

    if [ "$remaining" -gt 0 ]; then
        print_warning "Các FAIL items còn lại:"
        echo ""
        grep -E "^\[FAIL\]" "$after_file" | head -20
        echo ""

        if [ "$remaining" -gt 20 ]; then
            print_info "... và $((remaining - 20)) items khác"
        fi
    fi
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    clear
    print_banner "🔧 AUTO-FIX CIS DOCKER BENCHMARK"

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Script cần quyền root để thực hiện remediation"
        print_info "Vui lòng chạy: sudo bash $0"
        exit 1
    fi

    # Check if config directory exists
    if [ ! -d "$CONFIG_DIR" ]; then
        print_error "Không tìm thấy thư mục config/"
        exit 1
    fi

    log "=========================================="
    log "Bắt đầu auto-fix process"
    log "=========================================="

    # Step 1: Run initial tests
    print_banner "BƯỚC 1: KIỂM TRA BAN ĐẦU"
    local before_file="$TEMP_DIR/before_fix.txt"
    run_tests "$before_file"

    # Step 2: Parse failures
    if ! parse_failures "$before_file"; then
        echo ""

        # Show preview of failures
        print_info "Preview các FAIL items:"
        head -20 "$TEMP_DIR/fail_list.txt" | nl

        local total_fails=$(wc -l < "$TEMP_DIR/fail_list.txt")
        if [ "$total_fails" -gt 20 ]; then
            echo "  ... và $((total_fails - 20)) items khác"
        fi

        echo ""
        read -p "Bạn có muốn tiếp tục auto-fix? (yes/no): " confirm

        if [ "$confirm" != "yes" ]; then
            print_info "Đã hủy auto-fix"
            exit 0
        fi

        # Step 3: Apply remediations
        apply_remediations

        # Step 4: Run tests again
        print_banner "BƯỚC 2: KIỂM TRA LẠI SAU KHI FIX"
        local after_file="$TEMP_DIR/after_fix.txt"
        run_tests "$after_file"

        # Step 5: Show summary
        show_summary "$before_file" "$after_file"

        # Step 6: Show remaining fails
        show_remaining_fails "$after_file"

    else
        print_success "Tất cả tests đã PASS! Không cần remediation."
    fi

    # Cleanup and finish
    print_info "Log file: $LOG_FILE"
    print_info "Before results: $before_file"

    if [ -f "$TEMP_DIR/after_fix.txt" ]; then
        print_info "After results: $TEMP_DIR/after_fix.txt"
    fi

    log "Auto-fix process hoàn thành"

    echo ""
    print_success "Hoàn thành!"
}

# Run main
main "$@"
