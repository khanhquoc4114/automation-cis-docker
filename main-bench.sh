#!/bin/bash

# 1. Đảm bảo có dos2unix
if ! command -v dos2unix &> /dev/null; then
    echo "[INFO] dos2unix chưa có → tiến hành cài đặt..."
    sudo apt install dos2unix -y
fi

# 2. Chạy dos2unix cho toàn bộ file .sh trong thư mục tests
echo "============== CHUẨN HÓA DÒNG (dos2unix) =============="
for f in ./tests/*.sh; do
    [[ -f "$f" ]] || continue
    echo "[dos2unix] $f"
    dos2unix "$f"
done

# 3. Chỉ chạy file run_all_tests.sh
TARGET_SCRIPT="./tests/run_all_tests.sh"

echo ""
echo "============== BẮT ĐẦU CHẠY $TARGET_SCRIPT =============="

if [[ ! -f "$TARGET_SCRIPT" ]]; then
    echo "[ERROR] Không tìm thấy file: $TARGET_SCRIPT"
    exit 1
fi

# Đảm bảo file có quyền thực thi
chmod +x "$TARGET_SCRIPT"

bash "$TARGET_SCRIPT"
status=$?

if [[ $status -ne 0 ]]; then
    echo "[ERROR] Chạy $TARGET_SCRIPT thất bại (exit code: $status)"
    exit $status
else
    echo "[OK] Chạy $TARGET_SCRIPT thành công!"
fi

echo "============== HOÀN TẤT =============="
