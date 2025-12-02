# 🚀 Automation CIS Docker Benchmark

Bộ script tự động **kiểm tra CIS Docker Benchmark (Docker 1.8+)**, hỗ trợ chạy trực tiếp trên máy đích, mô phỏng môi trường Docker‑in‑Docker và triển khai tự động qua **Ansible** trên 2 VM.

---

## 🎯 Mục tiêu chính

- **Audit đầy đủ** các mục CIS Docker Benchmark (Sections 1–7) với trạng thái `PASS / FAIL / INFO`.
- **Tự động hoá hạ tầng**:  
  - Tạo lab Docker‑in‑Docker 2 node.  
  - Chạy benchmark qua Ansible và thu log tự động.  
  - Hỗ trợ mô hình 2 VM thực tế.

---

## 📁 Cấu trúc thư mục

```
automation-cis-docker/
│
├── tests/                     # Bộ kiểm tra CIS + run_all_tests.sh tổng hợp kết quả
├── config/                    # Các hàm khắc phục mẫu + logger cis_log.sh
├── main-bench.sh              # Chuẩn hoá & chạy toàn bộ test
│
├── setup-docker-in-docker/    # Môi trường 2 node DIND + playbook run-cis.yml
│   └── logs/
│
├── setup-2vm/                 # Playbook chạy CIS trên 2 VM thực
│   ├── docker_install.yml
│   ├── docker_container_setup.yml
│   ├── docker_bench.yml
│   └── logs/
│
├── CIS_Docker_Benchmark_v1.8.0.pdf  # Tài liệu chuẩn CIS
└── command.md                # Mô tả yêu cầu xây script remediation
```

---

## 🔧 Yêu cầu hệ thống

- Linux Shell (bash)
- Docker đã cài đặt cho mô hình lab
- Ansible ≥ 2.9, Python3
- `sshpass`, `dos2unix`, `jq` (nếu dùng remediation)
- Quyền `sudo` trên máy điều khiển

---

## ⚡ Hướng dẫn chạy nhanh

### 1️⃣ Chạy kiểm tra CIS trên chính máy hiện tại

```bash
bash main-bench.sh
```

Script sẽ chuẩn hoá file, sau đó chạy toàn bộ test trong `tests/` và in kết quả **PASS / FAIL / INFO**.

---

### 2️⃣ Mô hình Docker-in-Docker (2 Node Lab)

```bash
cd setup-docker-in-docker
bash run.sh
```

- Tự động cài sshpass + ansible-core  
- Tạo 2 node `node01` / `node02` (root/123123)
- SSH port: **2221**, **2222**
- Chạy playbook `run-cis.yml`
- Log trả về tại:

```
setup-docker-in-docker/logs/node0*.log
```

---

### 3️⃣ Mô hình 2 VM thực

#### ➤ Cập nhật host vào `setup-2vm/inventory.ini`

#### ➤ Cài Docker + đẩy script:

```bash
cd setup-2vm
ansible-playbook docker_install.yml
```

#### ➤ Tạo container lab (tùy chọn):

```bash
ansible-playbook docker_container_setup.yml
```

#### ➤ Chạy kiểm tra CIS và thu log:

```bash
ansible-playbook docker_bench.yml
```

Log được lưu tại:

```
setup-2vm/logs/main-bench/<timestamp>/
```

## 📌 Tài liệu tham khảo
- CIS Docker Benchmark v1.8.0  
- Docker security best practices  
- Ansible automation workflows

