# 🔧 HƯỚNG DẪN AUTO-FIX CIS DOCKER BENCHMARK

Hướng dẫn tự động fix các FAIL items khi chạy CIS Docker Benchmark.

---

## 🎯 Mục đích

Khi chạy `main-bench.sh` và thấy **FAIL**, script này sẽ:
1. ✅ Phát hiện các FAIL items
2. ✅ Tự động gọi remediation functions tương ứng
3. ✅ Chạy lại tests để verify
4. ✅ Báo cáo kết quả

---

## 🚀 CÁCH SỬ DỤNG

### Phương pháp 1: Auto-Fix Hoàn Toàn (KHUYẾN NGHỊ)

```bash
cd /home/tainh/Documents/automation-cis-docker

# Chạy auto-fix (cần sudo)
sudo bash main-bench-autofix.sh
```

**Quy trình:**
1. Script chạy test ban đầu
2. Phát hiện các FAIL (ví dụ: 22 FAIL)
3. Hỏi xác nhận có muốn fix không
4. Tự động fix từng item
5. Chạy lại test
6. Hiển thị kết quả: trước vs sau

**Output mẫu:**
```
════════════════════════════════════════════════════════════
                         TỔNG KẾT
════════════════════════════════════════════════════════════

Trước khi fix:
  PASS: 85
  FAIL: 22

Sau khi fix:
  PASS: 107
  FAIL: 0

✓ Đã fix thành công: 22 items

🎉 HOÀN HẢO! Không còn FAIL nào!
```

---

### Phương pháp 2: Fix Thủ Công Từng Section

Nếu bạn muốn kiểm soát chi tiết hơn:

#### Bước 1: Xem các FAIL

```bash
cd /home/tainh/Documents/automation-cis-docker
sudo bash main-bench.sh | grep FAIL
```

#### Bước 2: Fix từng section

```bash
cd config

# Fix Section 2 (Docker Daemon Configuration)
source 2.sh
remediate_2_2   # Fix specific item
remediate_2_3
# ...

# Fix Section 3 (Docker Daemon Files)
source 3.sh
remediate_3_1   # Fix docker.service ownership
remediate_3_2   # Fix docker.service permissions
remediate_3_5   # Fix /etc/docker ownership
# ...

# Fix Section 5 (Container Runtime)
source 5.sh
remediate_5_28  # Fix PIDs limit
# ...
```

#### Bước 3: Chạy lại test

```bash
cd /home/tainh/Documents/automation-cis-docker
sudo bash main-bench.sh
```

---

## 📊 Remediation Functions Có Sẵn

### Section 2: Docker Daemon Configuration (10 functions)
- `remediate_2_2` - Restrict network traffic
- `remediate_2_3` - Set logging level to 'info'
- `remediate_2_4` - Allow Docker to make iptables changes
- `remediate_2_15` - Enable live restore
- `remediate_2_16` - Disable userland proxy
- `remediate_2_17` - Apply seccomp profile
- `remediate_2_18` - Disable experimental features
- `remediate_2_19` - Restrict new privileges

### Section 3: Docker Daemon Configuration Files (24 functions)
- `remediate_3_1` - Fix docker.service ownership (root:root)
- `remediate_3_2` - Fix docker.service permissions (644)
- `remediate_3_3` - Fix docker.socket ownership
- `remediate_3_4` - Fix docker.socket permissions
- `remediate_3_5` - Fix /etc/docker ownership
- `remediate_3_6` - Fix /etc/docker permissions (755)
- `remediate_3_7` đến `3_24` - Fix các TLS certificates, daemon.json, containerd socket...

### Section 5: Container Runtime Configuration (32 functions)
- `remediate_5_1` - Disable Swarm mode if not needed
- `remediate_5_2` - Enable AppArmor profile
- `remediate_5_3` - Verify SELinux security options
- `remediate_5_4` - Do not use privileged containers
- `remediate_5_5` - Do not mount sensitive host directories
- `remediate_5_6` - Do not run SSH in containers
- `remediate_5_7` - Only open needed ports
- `remediate_5_8` đến `5_32` - Namespace isolation, resource limits...

### Section 7: Docker Swarm Configuration (1 function)
- `remediate_7_7` - Rotate node certificates

**Tổng cộng: 57 remediation functions**

---

## 🔍 Chi tiết Auto-Fix Process

### Quy trình hoạt động:

1. **Detect FAIL**
   ```bash
   # Parse output để tìm các dòng [FAIL]
   # Extract check ID (e.g., "3.2", "5.4")
   ```

2. **Map to Remediation Function**
   ```
   FAIL: 3.2 → remediate_3_2 (trong config/3.sh)
   FAIL: 5.4 → remediate_5_4 (trong config/5.sh)
   ```

3. **Execute Remediation**
   ```bash
   # Source config file
   source config/3.sh

   # Run function with auto-confirm
   echo "yes" | remediate_3_2
   ```

4. **Verify**
   ```bash
   # Run test lại
   bash main-bench.sh

   # Compare before vs after
   ```

---

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Cần quyền root
```bash
# ĐÚNG
sudo bash main-bench-autofix.sh

# SAI
bash main-bench-autofix.sh  # Sẽ bị lỗi
```

### 2. Backup trước khi fix

**KHUYẾN NGHỊ:**
```bash
# Backup các file quan trọng
sudo cp /usr/lib/systemd/system/docker.service /tmp/docker.service.bak
sudo cp /etc/docker/daemon.json /tmp/daemon.json.bak 2>/dev/null || true

# Chạy auto-fix
sudo bash main-bench-autofix.sh
```

### 3. Một số FAIL không thể auto-fix

**FAIL không fix được tự động:**
- Section 1: Auditing rules (cần cấu hình auditd)
- Section 4: Container images (cần rebuild images)
- Section 6: Sprawl management (cần cleanup thủ công)

**Cần fix thủ công cho:**
- Partition riêng cho `/var/lib/docker`
- TLS certificates (nếu chưa có)
- User namespace (cần restart Docker daemon)

### 4. Section 5 yêu cầu có containers

Nhiều checks trong Section 5 kiểm tra **containers đang chạy**:
```bash
# Nếu không có containers → không có gì để check/fix
# Tạo test containers trước:
docker run -d --name test-nginx nginx
docker run -d --name test-redis redis

# Rồi mới chạy auto-fix
sudo bash main-bench-autofix.sh
```

---

## 📝 Logs và Troubleshooting

### Xem logs chi tiết

```bash
# Logs được lưu trong temp/
cat temp/autofix.log

# Kết quả before/after
cat temp/before_fix.txt
cat temp/after_fix.txt
```

### Nếu auto-fix không hoạt động

1. **Kiểm tra quyền:**
   ```bash
   whoami  # Phải là root
   sudo -v  # Verify sudo access
   ```

2. **Kiểm tra config/ tồn tại:**
   ```bash
   ls -lh config/*.sh
   ```

3. **Test một remediation function:**
   ```bash
   cd config
   source 3.sh
   remediate_3_2  # Test thủ công
   ```

4. **Xem function có tồn tại không:**
   ```bash
   cd config
   grep "^remediate_" *.sh | grep "3_2"
   ```

### Rollback nếu có vấn đề

```bash
# Restore từ backup
sudo cp /tmp/docker.service.bak /usr/lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## 🎯 Kịch bản Sử Dụng

### Kịch bản 1: Demo/Testing

```bash
# Chạy test ban đầu
sudo bash main-bench.sh | grep -E "(PASS|FAIL|INFO)" | tail -5

# Auto-fix
sudo bash main-bench-autofix.sh

# Verify
sudo bash main-bench.sh | grep -E "(PASS|FAIL)" | tail -5
```

### Kịch bản 2: Production Hardening

```bash
# 1. Backup
sudo mkdir -p /backup/docker-config
sudo cp -r /etc/docker /backup/docker-config/
sudo cp /usr/lib/systemd/system/docker.* /backup/docker-config/

# 2. Run initial test
sudo bash main-bench.sh > /tmp/before.txt

# 3. Review FAIL items
grep FAIL /tmp/before.txt

# 4. Auto-fix (với xác nhận)
sudo bash main-bench-autofix.sh

# 5. Verify services
sudo systemctl status docker
docker ps

# 6. Run final test
sudo bash main-bench.sh > /tmp/after.txt

# 7. Compare
diff /tmp/before.txt /tmp/after.txt
```

### Kịch bản 3: CI/CD Integration

```bash
#!/bin/bash
# ci-security-check.sh

set -e

# Run CIS benchmark
sudo bash main-bench.sh > results.txt

# Check for FAIL
FAIL_COUNT=$(grep -c "^\[FAIL\]" results.txt || true)

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "Found $FAIL_COUNT security issues"

    # Auto-fix
    echo "yes" | sudo bash main-bench-autofix.sh

    # Re-test
    sudo bash main-bench.sh > results_after.txt

    # Verify all fixed
    FAIL_AFTER=$(grep -c "^\[FAIL\]" results_after.txt || true)

    if [ "$FAIL_AFTER" -gt 0 ]; then
        echo "ERROR: Still have $FAIL_AFTER failures after auto-fix"
        exit 1
    fi
fi

echo "All CIS checks PASSED"
```

---

## 📚 Tham khảo

- **CIS Docker Benchmark v1.8.0**: `CIS_Docker_Benchmark_v1.8.0.pdf`
- **Test scripts**: `tests/1.sh` - `tests/7.sh`
- **Remediation scripts**: `config/2.sh`, `config/3.sh`, `config/5.sh`, `config/7.sh`
- **Main benchmark**: `main-bench.sh`

---

## ✅ Checklist

Trước khi chạy auto-fix:
- [ ] Đã backup cấu hình quan trọng
- [ ] Đang chạy với sudo/root
- [ ] Docker đang hoạt động: `docker ps`
- [ ] Có test containers (cho Section 5)
- [ ] Đã đọc kỹ các FAIL items cần fix

Sau khi auto-fix:
- [ ] Verify Docker vẫn hoạt động: `docker ps`
- [ ] Check logs: `cat temp/autofix.log`
- [ ] Compare before/after results
- [ ] Test applications vẫn chạy bình thường

---

## 🎉 Kết quả Mong Đợi

**Trước:**
```
TOTAL PASS: 85
TOTAL FAIL: 22
TOTAL INFO: 15
```

**Sau khi auto-fix:**
```
TOTAL PASS: 107
TOTAL FAIL: 0
TOTAL INFO: 15

🎉 HOÀN HẢO! Không còn FAIL nào!
```

---

**Last Updated:** 2025-12-04
**Version:** 1.0
