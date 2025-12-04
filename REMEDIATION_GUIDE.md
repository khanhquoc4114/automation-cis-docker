# 🔧 REMEDIATION GUIDE - CIS DOCKER BENCHMARK

Danh sách đầy đủ các remediation functions có sẵn và cách sử dụng.

---

## 📊 TỔNG QUAN

**Tổng số remediation functions: 74**

- **Section 1** (17 functions): Host Configuration & Auditing
- **Section 2** (10 functions): Docker Daemon Configuration
- **Section 3** (24 functions): Docker Daemon Configuration Files
- **Section 4** (0 functions): Container Images (Manual)
- **Section 5** (32 functions): Container Runtime Configuration
- **Section 6** (0 functions): Security Operations (Manual)
- **Section 7** (1 function): Docker Swarm Configuration

---

## 📋 SECTION 1: HOST CONFIGURATION (17 functions)

### Partition & Users
- `remediate_1_1_1` - Separate partition for containers (MANUAL guide)
- `remediate_1_1_2` - Review Docker group users (INFO)

### Auditing (15 functions)
- `remediate_1_1_3` - Audit Docker daemon (/usr/bin/dockerd)
- `remediate_1_1_4` - Audit /run/containerd
- `remediate_1_1_5` - Audit /var/lib/docker
- `remediate_1_1_6` - Audit /etc/docker
- `remediate_1_1_7` - Audit docker.service
- `remediate_1_1_8` - Audit containerd.sock
- `remediate_1_1_9` - Audit docker.sock
- `remediate_1_1_10` - Audit /etc/default/docker
- `remediate_1_1_11` - Audit /etc/docker/daemon.json
- `remediate_1_1_12` - Audit /etc/sysconfig/docker
- `remediate_1_1_13` - Audit /usr/bin/containerd
- `remediate_1_1_14` - Audit /usr/bin/containerd-shim
- `remediate_1_1_15` - Audit containerd-shim-runc-v1
- `remediate_1_1_16` - Audit containerd-shim-runc-v2
- `remediate_1_1_17` - Audit /usr/bin/runc

### Host Hardening
- `remediate_1_2_1` - Host hardening checklist (INFO)
- `remediate_1_2_2` - Update Docker version

### Bulk Operation
- `remediate_all_auditing` - Configure all audit rules at once

**Usage:**
```bash
cd config
source 1.sh

# Fix specific item
remediate_1_1_3  # Configure audit for Docker daemon

# Or fix all auditing at once
remediate_all_auditing
```

---

## 📋 SECTION 2: DOCKER DAEMON CONFIGURATION (10 functions)

- `remediate_2_2` - Restrict network traffic between containers
- `remediate_2_3` - Set logging level to 'info'
- `remediate_2_4` - Allow Docker to make iptables changes
- `remediate_2_15` - Enable live restore
- `remediate_2_16` - Disable userland proxy
- `remediate_2_17` - Apply seccomp profile
- `remediate_2_18` - Disable experimental features
- `remediate_2_19` - Restrict containers from acquiring new privileges

**Usage:**
```bash
cd config
source 2.sh

remediate_2_15  # Enable live restore
remediate_2_16  # Disable userland proxy
```

---

## 📋 SECTION 3: DOCKER DAEMON FILES (24 functions)

### docker.service
- `remediate_3_1` - Fix ownership (root:root)
- `remediate_3_2` - Fix permissions (644)

### docker.socket
- `remediate_3_3` - Fix ownership (root:root)
- `remediate_3_4` - Fix permissions (644)

### /etc/docker
- `remediate_3_5` - Fix ownership (root:root)
- `remediate_3_6` - Fix permissions (755)

### Registry certificates
- `remediate_3_7` - Fix ownership (root:root)
- `remediate_3_8` - Fix permissions (444)

### TLS certificates
- `remediate_3_9` - Fix TLS CA cert ownership
- `remediate_3_10` - Fix TLS CA cert permissions
- `remediate_3_11` - Fix server cert ownership
- `remediate_3_12` - Fix server cert permissions
- `remediate_3_13` - Fix server key ownership
- `remediate_3_14` - Fix server key permissions (400)

### Docker socket
- `remediate_3_15` - Fix ownership (root:docker)
- `remediate_3_16` - Fix permissions (660)

### daemon.json
- `remediate_3_17` - Fix ownership (root:root)
- `remediate_3_18` - Fix permissions (644)

### Environment files
- `remediate_3_19` - Fix /etc/default/docker ownership
- `remediate_3_20` - Fix /etc/default/docker permissions
- `remediate_3_21` - Fix /etc/sysconfig/docker ownership
- `remediate_3_22` - Fix /etc/sysconfig/docker permissions

### containerd socket
- `remediate_3_23` - Fix ownership (root:root)
- `remediate_3_24` - Fix permissions (660)

**Usage:**
```bash
cd config
source 3.sh

remediate_3_2   # Fix docker.service permissions
remediate_3_5   # Fix /etc/docker ownership
```

---

## 📋 SECTION 4: CONTAINER IMAGES (0 functions)

**⚠️ MANUAL REMEDIATION REQUIRED**

Section 4 checks require manual actions:
- Building images with proper Dockerfile
- Scanning images with tools (trivy, grype, clair)
- Managing secrets properly
- Using trusted base images

**Cannot be automated** because it requires:
- Code changes to Dockerfiles
- Image rebuilding
- Registry configuration
- CI/CD pipeline integration

---

## 📋 SECTION 5: CONTAINER RUNTIME (32 functions)

### Swarm & Security
- `remediate_5_1` - Disable Swarm mode if not needed
- `remediate_5_2` - Enable AppArmor profile
- `remediate_5_3` - Verify SELinux security options

### Privileged & Mounts
- `remediate_5_4` - Don't use privileged containers
- `remediate_5_5` - Don't mount sensitive host directories
- `remediate_5_6` - Don't run SSH in containers
- `remediate_5_7` - Only open needed ports

### Namespace Isolation
- `remediate_5_8` - Don't share host network namespace
- `remediate_5_9` - Don't share host PID namespace
- `remediate_5_10` - Don't share host IPC namespace
- `remediate_5_11` - Don't share host UTS namespace
- `remediate_5_12` - Don't share host user namespace

### Security Options
- `remediate_5_13` - Don't mount Docker socket into container
- `remediate_5_14` - Set root filesystem to read-only
- `remediate_5_15` - Bind container to specific host interface
- `remediate_5_16` - Set 'on-failure' restart policy (max 5 times)
- `remediate_5_17` - Don't share host's process namespace
- `remediate_5_18` - Don't share host's IPC namespace
- `remediate_5_19` - Don't directly map privileged ports
- `remediate_5_20` - Only open needed host ports
- `remediate_5_21` - Don't disable health check
- `remediate_5_22` - Set health check for containers

### Resource Limits
- `remediate_5_23` - Ensure PIDs cgroup limit is set
- `remediate_5_24` - Configure memory limit
- `remediate_5_25` - Set CPU priority appropriately
- `remediate_5_26` - Set container CPU shares
- `remediate_5_27` - Set container rootfs mount as read-only

### Advanced Security
- `remediate_5_28` - Configure PIDs limit
- `remediate_5_29` - Don't use default bridge (docker0)
- `remediate_5_30` - Limit container acquiring additional privileges
- `remediate_5_31` - Don't share host user namespace
- `remediate_5_32` - Verify that Docker socket is not mounted

**Usage:**
```bash
cd config
source 5.sh

remediate_5_28  # Configure PIDs limit
remediate_5_4   # Check privileged containers
```

---

## 📋 SECTION 6: SECURITY OPERATIONS (0 functions)

**⚠️ MANUAL REMEDIATION REQUIRED**

Section 6 checks require manual cleanup:
- **6.1** - Avoid image sprawl (cleanup unused images)
- **6.2** - Avoid container sprawl (cleanup stopped containers)

**Commands:**
```bash
# Remove unused images
docker image prune -a

# Remove stopped containers
docker container prune

# Complete cleanup
docker system prune -a --volumes
```

---

## 📋 SECTION 7: DOCKER SWARM (1 function)

- `remediate_7_7` - Rotate node certificates

**Usage:**
```bash
cd config
source 7.sh

remediate_7_7  # Rotate Swarm node certificates
```

**Note:** Most Swarm checks require manual configuration of Swarm cluster.

---

## 🚀 CÁCH SỬ DỤNG

### Method 1: Auto-fix tất cả (Recommended)

```bash
cd /home/tainh/Documents/automation-cis-docker

# Quick fix (phổ biến nhất)
sudo bash quick-fix.sh

# Hoặc auto-fix hoàn chỉnh
sudo bash main-bench-autofix.sh
```

### Method 2: Fix từng section

```bash
cd config

# Section 1 - Auditing
source 1.sh
remediate_all_auditing  # Fix all at once

# Section 2 - Daemon config
source 2.sh
remediate_2_15

# Section 3 - Files
source 3.sh
remediate_3_2
remediate_3_5

# Section 5 - Runtime
source 5.sh
remediate_5_28
```

### Method 3: Fix specific item

```bash
cd config
source 3.sh

# Fix one specific check
remediate_3_2  # Will prompt for confirmation
```

---

## 📊 REMEDIATION COVERAGE

| Section | Total Checks | Auto Remediation | Manual | Coverage |
|---------|--------------|------------------|--------|----------|
| 1 | ~18 | 17 | 1 | 94% |
| 2 | ~18 | 10 | 8 | 56% |
| 3 | 24 | 24 | 0 | 100% |
| 4 | ~9 | 0 | 9 | 0% |
| 5 | ~32 | 32 | 0 | 100% |
| 6 | 2 | 0 | 2 | 0% |
| 7 | ~10 | 1 | 9 | 10% |
| **Total** | **~113** | **74** | **29** | **65%** |

---

## ⚠️ IMPORTANT NOTES

### 1. Backup trước khi remediate
```bash
sudo cp -r /etc/docker /backup/docker-config
sudo cp /usr/lib/systemd/system/docker.* /backup/
```

### 2. Test trong môi trường dev trước

Không chạy trực tiếp trên production!

### 3. Một số remediations cần restart Docker

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
docker ps  # Verify containers still running
```

### 4. Section 1 auditing cần auditd installed

```bash
sudo apt-get install -y auditd
sudo systemctl enable auditd
sudo systemctl start auditd
```

### 5. Section 5 checks cần có containers running

```bash
# Tạo test containers
docker run -d --name test-nginx nginx
docker run -d --name test-redis redis
```

---

## 🎯 RECOMMENDED WORKFLOW

```bash
# 1. Backup
sudo cp -r /etc/docker /backup/docker-$(date +%Y%m%d)

# 2. Run initial test
sudo bash main-bench.sh > before.txt

# 3. Quick fix (most common issues)
sudo bash quick-fix.sh

# 4. Check results
sudo bash main-bench.sh > after.txt

# 5. If still have FAIL, run full auto-fix
sudo bash main-bench-autofix.sh

# 6. Verify Docker still works
docker ps
docker run hello-world

# 7. Review remaining FAIL (manual fixes needed)
grep FAIL after.txt
```

---

## 📚 FILES REFERENCE

- **Tests**: `tests/1.sh` - `tests/7.sh`
- **Remediation**: `config/1.sh`, `config/2.sh`, `config/3.sh`, `config/5.sh`, `config/7.sh`
- **Auto-fix**: `main-bench-autofix.sh`, `quick-fix.sh`
- **Guides**: `AUTO_FIX_GUIDE.md`, `REMEDIATION_GUIDE.md` (this file)

---

**Last Updated:** 2025-12-04
**Version:** 1.1 (Added Section 1 remediation functions)
