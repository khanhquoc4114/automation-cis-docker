#!/bin/bash

# Thay đổi thư mục làm việc thành thư mục chứa tập lệnh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "$SCRIPT_DIR" >/dev/null


# Lấy nguồn tệp cis_log.sh từ cùng thư mục
source "./cis_log.sh"

check_5() {
  echo ""
  local id="5"
  local desc="Container Runtime"
  checkHeader="$id - $desc"
  log_info "$checkHeader"
}

check_running_containers() {
  containers=$(docker ps -q 2>/dev/null)
  
  if [ -z "$containers" ]; then
    log_info "  * No containers running, skipping Section 5"
    return 1
  fi
  return 0
}

check_5_1() {
  local id="5.1"
  local desc="Ensure swarm mode is not Enabled, if not needed (Automated)"

  if docker info 2>/dev/null | grep -e "Swarm:.*inactive" >/dev/null 2>&1; then
    add_summary "$id" "$desc" "PASS"
    return
  fi
  add_summary "$id" "$desc" "FAIL"
}

check_5_2() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.2"
  local desc="Ensure that, if applicable, an AppArmor Profile is enabled (Automated)"

  fail=0
  no_apparmor_containers=""
  for c in $containers; do
    policy=$(docker inspect --format 'AppArmorProfile={{ .AppArmorProfile }}' "$c" 2>/dev/null)

    if [ "$policy" = "AppArmorProfile=" ] || [ "$policy" = "AppArmorProfile=[]" ] || [ "$policy" = "AppArmorProfile=<no value>" ] || [ "$policy" = "AppArmorProfile=unconfined" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "     * No AppArmorProfile Found: $c"
      no_apparmor_containers="$no_apparmor_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_4() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.4"
  local desc="Ensure that Linux kernel capabilities are restricted within containers (Automated)"

  fail=0
  caps_containers=""
  for c in $containers; do
    container_caps=$(docker inspect --format 'CapAdd={{ .HostConfig.CapAdd }}' "$c" 2>/dev/null)
    caps=$(echo "$container_caps" | tr "[:lower:]" "[:upper:]" | \
      sed 's/CAPADD/CapAdd/' | \
      sed -r "s/CAP_AUDIT_WRITE|CAP_CHOWN|CAP_DAC_OVERRIDE|CAP_FOWNER|CAP_FSETID|CAP_KILL|CAP_MKNOD|CAP_NET_BIND_SERVICE|CAP_NET_RAW|CAP_SETFCAP|CAP_SETGID|CAP_SETPCAP|CAP_SETUID|CAP_SYS_CHROOT|\s//g" | \
      sed -r "s/AUDIT_WRITE|CHOWN|DAC_OVERRIDE|FOWNER|FSETID|KILL|MKNOD|NET_BIND_SERVICE|NET_RAW|SETFCAP|SETGID|SETPCAP|SETUID|SYS_CHROOT|\s//g")

    if [ "$caps" != 'CapAdd=' ] && [ "$caps" != 'CapAdd=[]' ] && [ "$caps" != 'CapAdd=<no value>' ] && [ "$caps" != 'CapAdd=<nil>' ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "     * Capabilities added: $caps to $c"
      caps_containers="$caps_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_5() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.5"
  local desc="Ensure that privileged containers are not used (Automated)"

  fail=0
  privileged_containers=""
  for c in $containers; do
    privileged=$(docker inspect --format '{{ .HostConfig.Privileged }}' "$c" 2>/dev/null)

    if [ "$privileged" = "true" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "     * Container running in Privileged mode: $c"
      privileged_containers="$privileged_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_6() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.6"
  local desc="Ensure sensitive host system directories are not mounted on containers (Automated)"

  sensitive_dirs='/
/boot
/dev
/etc
/lib
/proc
/sys
/usr'
  fail=0
  sensitive_mount_containers=""
  for c in $containers; do
    volumes=$(docker inspect --format '{{ .Mounts }}' "$c" 2>/dev/null)
    if docker inspect --format '{{ .VolumesRW }}' "$c" 2>/dev/null 1>&2; then
      volumes=$(docker inspect --format '{{ .VolumesRW }}' "$c" 2>/dev/null)
    fi

    for v in $sensitive_dirs; do
      sensitive=0
      if echo "$volumes" | grep -e "{.*\s$v\s.*true\s.*}" 2>/dev/null 1>&2; then
        sensitive=1
      fi
      if [ $sensitive -eq 1 ]; then
        if [ $fail -eq 0 ]; then
          add_summary "$id" "$desc" "FAIL"
          fail=1
        fi
        echo "     * Sensitive directory $v mounted in: $c"
        sensitive_mount_containers="$sensitive_mount_containers $c:$v"
      fi
    done
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_7() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.7"
  local desc="Ensure sshd is not run within containers (Automated)"

  fail=0
  ssh_exec_containers=""
  for c in $containers; do
    processes=$(docker exec "$c" ps -el 2>/dev/null | grep -c sshd | awk '{print $1}')
    if [ "$processes" -ge 1 ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "     * Container running sshd: $c"
      ssh_exec_containers="$ssh_exec_containers $c"
    fi

    docker exec "$c" ps -el 2>/dev/null >/dev/null
    if [ $? -eq 255 ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "     * Docker exec fails: $c"
      ssh_exec_containers="$ssh_exec_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_8() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.8"
  local desc="Ensure privileged ports are not mapped within containers (Automated)"

  fail=0
  privileged_port_containers=""
  for c in $containers; do
    ports=$(docker port "$c" 2>/dev/null | awk '{print $3}' | cut -d ':' -f2)

    for port in $ports; do
      if [ -n "$port" ] && [ "$port" -lt 1025 ]; then
        if [ $fail -eq 0 ]; then
          add_summary "$id" "$desc" "FAIL"
          fail=1
        fi
        echo "     * Privileged Port in use: $port in $c"
        privileged_port_containers="$privileged_port_containers $c:$port"
      fi
    done
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_9() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.9"
  local desc="Ensure that only needed ports are open on the container (Manual)"

  fail=0
  open_port_containers=""
  for c in $containers; do
    ports=$(docker port "$c" 2>/dev/null | awk '{print $3}' | cut -d ':' -f2)

    for port in $ports; do
      if [ -n "$port" ]; then
        if [ $fail -eq 0 ]; then
          add_summary "$id" "$desc" "INFO"
          fail=1
        fi
        echo "     * Port in use: $port in $c"
        open_port_containers="$open_port_containers $c:$port"
      fi
    done
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_10() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.10"
  local desc="Ensure that the host's network namespace is not shared (Automated)"

  fail=0
  net_host_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'NetworkMode={{ .HostConfig.NetworkMode }}' "$c" 2>/dev/null)

    if [ "$mode" = "NetworkMode=host" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "     * Container running with networking mode 'host': $c"
      net_host_containers="$net_host_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_11() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.11"
  local desc="Ensure that the memory usage for containers is limited (Automated)"

  fail=0
  mem_unlimited_containers=""
  for c in $containers; do
    memory=$(docker inspect --format '{{ .HostConfig.Memory }}' "$c" 2>/dev/null)
    if docker inspect --format '{{ .Config.Memory }}' "$c" 2>/dev/null 1>&2; then
      memory=$(docker inspect --format '{{ .Config.Memory }}' "$c" 2>/dev/null)
    fi

    if [ "$memory" = "0" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Container running without memory restrictions: $c"
      mem_unlimited_containers="$mem_unlimited_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_12() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.12"
  local desc="Ensure that CPU priority is set appropriately on containers (Automated)"

  fail=0
  cpu_unlimited_containers=""
  for c in $containers; do
    cpushares=$(docker inspect --format '{{ .HostConfig.CpuShares }}' "$c" 2>/dev/null)
    nanocpus=$(docker inspect --format '{{ .HostConfig.NanoCpus }}' "$c" 2>/dev/null)

    if docker inspect --format '{{ .Config.CpuShares }}' "$c" 2>/dev/null 1>&2; then
      cpushares=$(docker inspect --format '{{ .Config.CpuShares }}' "$c" 2>/dev/null)
      nanocpus=$(docker inspect --format '{{ .Config.NanoCpus }}' "$c" 2>/dev/null)
    fi

    if [ "$cpushares" = "0" ] && [ "$nanocpus" = "0" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Container running without CPU restrictions: $c"
      cpu_unlimited_containers="$cpu_unlimited_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_13() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.13"
  local desc="Ensure that the container's root filesystem is mounted as read only (Automated)"

  fail=0
  fsroot_mount_containers=""
  for c in $containers; do
    read_status=$(docker inspect --format '{{ .HostConfig.ReadonlyRootfs }}' "$c" 2>/dev/null)

    if [ "$read_status" = "false" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Container running with root FS mounted R/W: $c"
      fsroot_mount_containers="$fsroot_mount_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_14() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.14"
  local desc="Ensure that incoming container traffic is bound to a specific host interface (Automated)"

  fail=0
  incoming_unbound_containers=""
  for c in $containers; do
    for ip in $(docker port "$c" 2>/dev/null | awk '{print $3}' | cut -d ':' -f1); do
      if [ "$ip" = "0.0.0.0" ]; then
        if [ $fail -eq 0 ]; then
          add_summary "$id" "$desc" "FAIL"
          fail=1
        fi
        echo "      * Port being bound to wildcard IP: $ip in $c"
        incoming_unbound_containers="$incoming_unbound_containers $c:$ip"
      fi
    done
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_15() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.15"
  local desc="Ensure that the 'on-failure' container restart policy is set to '5' (Automated)"

  fail=0
  maxretry_unset_containers=""
  for c in $containers; do
    container_name=$(docker inspect "$c" --format '{{.Name}}' 2>/dev/null)
    restart_policy=""
    
    if [ "$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)" = "active" ]; then
      for s in $(docker service ls --format '{{.Name}}' 2>/dev/null); do
        if echo "$container_name" | grep -q "$s"; then
          task_id=$(docker inspect "$c" --format '{{.Name}}' 2>/dev/null | awk -F '.' '{print $NF}')
          if docker service ps --no-trunc "$s" --format '{{.ID}}' 2>/dev/null | grep -q "$task_id"; then
            restart_policy=$(docker inspect --format '{{ .Spec.TaskTemplate.RestartPolicy.MaxAttempts }}' "$s" 2>/dev/null)
            break
          fi
        fi
      done
    fi
    
    if [ -z "$restart_policy" ] && docker inspect --format '{{ .HostConfig.RestartPolicy.MaximumRetryCount }}' "$c" &>/dev/null; then
      restart_policy=$(docker inspect --format '{{ .HostConfig.RestartPolicy.MaximumRetryCount }}' "$c" 2>/dev/null)
    fi

    if [ -n "$restart_policy" ] && [ "$restart_policy" -gt "5" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * MaximumRetryCount is not set to 5 or less: $c"
      maxretry_unset_containers="$maxretry_unset_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_16() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.16"
  local desc="Ensure that the host's process namespace is not shared (Automated)"

  fail=0
  pidns_shared_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'PidMode={{.HostConfig.PidMode }}' "$c" 2>/dev/null)

    if [ "$mode" = "PidMode=host" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Host PID namespace being shared with: $c"
      pidns_shared_containers="$pidns_shared_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_17() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.17"
  local desc="Ensure that the host's IPC namespace is not shared (Automated)"

  fail=0
  ipcns_shared_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'IpcMode={{.HostConfig.IpcMode }}' "$c" 2>/dev/null)

    if [ "$mode" = "IpcMode=host" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Host IPC namespace being shared with: $c"
      ipcns_shared_containers="$ipcns_shared_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_18() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.18"
  local desc="Ensure that host devices are not directly exposed to containers (Manual)"

  fail=0
  hostdev_exposed_containers=""
  for c in $containers; do
    devices=$(docker inspect --format 'Devices={{ .HostConfig.Devices }}' "$c" 2>/dev/null)

    if [ "$devices" != "Devices=" ] && [ "$devices" != "Devices=[]" ] && [ "$devices" != "Devices=<no value>" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "INFO"
        fail=1
      fi
      echo "      * Container has devices exposed directly: $c"
      hostdev_exposed_containers="$hostdev_exposed_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_19() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.19"
  local desc="Ensure that the default ulimit is overwritten at runtime if needed (Manual)"

  fail=0
  no_ulimit_containers=""
  for c in $containers; do
    ulimits=$(docker inspect --format 'Ulimits={{ .HostConfig.Ulimits }}' "$c" 2>/dev/null)

    if [ "$ulimits" = "Ulimits=" ] || [ "$ulimits" = "Ulimits=[]" ] || [ "$ulimits" = "Ulimits=<no value>" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "INFO"
        fail=1
      fi
      echo "      * Container no default ulimit override: $c"
      no_ulimit_containers="$no_ulimit_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_20() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.20"
  local desc="Ensure mount propagation mode is not set to shared (Automated)"

  fail=0
  mountprop_shared_containers=""
  for c in $containers; do
    if docker inspect --format 'Propagation={{range $mnt := .Mounts}} {{json $mnt.Propagation}} {{end}}' "$c" 2>/dev/null | \
       grep shared >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Mount propagation mode is shared: $c"
      mountprop_shared_containers="$mountprop_shared_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_21() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.21"
  local desc="Ensure that the host's UTS namespace is not shared (Automated)"

  fail=0
  utcns_shared_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'UTSMode={{.HostConfig.UTSMode }}' "$c" 2>/dev/null)

    if [ "$mode" = "UTSMode=host" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Host UTS namespace being shared with: $c"
      utcns_shared_containers="$utcns_shared_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_22() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.22"
  local desc="Ensure the default seccomp profile is not Disabled (Automated)"

  fail=0
  seccomp_disabled_containers=""
  for c in $containers; do
    if docker inspect --format 'SecurityOpt={{.HostConfig.SecurityOpt }}' "$c" 2>/dev/null | \
      grep -E 'seccomp:unconfined|seccomp=unconfined' >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Default seccomp profile disabled: $c"
      seccomp_disabled_containers="$seccomp_disabled_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_25() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.25"
  local desc="Ensure that cgroup usage is confirmed (Automated)"

  fail=0
  unexpected_cgroup_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'CgroupParent={{.HostConfig.CgroupParent }}x' "$c" 2>/dev/null)

    if [ "$mode" != "CgroupParent=x" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Confirm cgroup usage: $c"
      unexpected_cgroup_containers="$unexpected_cgroup_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_26() {
  if [ -z "$containers" ]; then
    return
  fi
  
  local id="5.26"
  local desc="Ensure that the container is restricted from acquiring additional privileges (Automated)"

  fail=0
  addprivs_containers=""

  for c in $containers; do
    if ! docker inspect --format 'SecurityOpt={{.HostConfig.SecurityOpt }}' "$c" 2>/dev/null | grep 'no-new-privileges' >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Privileges not restricted: $c"
      addprivs_containers="$addprivs_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_27() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.27"
  local desc="Ensure that container health is checked at runtime (Automated)"

  fail=0
  nohealthcheck_containers=""
  for c in $containers; do
    if ! docker inspect --format '{{ .Id }}: Health={{ .State.Health.Status }}' "$c" 2>/dev/null 1>&2; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Health check not set: $c"
      nohealthcheck_containers="$nohealthcheck_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_28() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.28"
  local desc="Ensure that Docker commands always make use of the latest version of their image (Manual)"

  add_summary "$id" "$desc" "INFO"
}

check_5_29() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.29"
  local desc="Ensure that the PIDs cgroup limit is used (Automated)"

  fail=0
  nopids_limit_containers=""
  for c in $containers; do
    pidslimit="$(docker inspect --format '{{.HostConfig.PidsLimit }}' "$c" 2>/dev/null)"

    if [ "$pidslimit" = "0" ] || [ "$pidslimit" = "<nil>" ] || [ "$pidslimit" = "-1" ]; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * PIDs limit not set: $c"
      nopids_limit_containers="$nopids_limit_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_30() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.30"
  local desc="Ensure that Docker's default bridge 'docker0' is not used (Manual)"

  fail=0
  docker_network_containers=""
  networks=$(docker network ls -q 2>/dev/null)
  
  for net in $networks; do
    if docker network inspect --format '{{ .Options }}' "$net" 2>/dev/null | grep "com.docker.network.bridge.name:docker0" >/dev/null 2>&1; then
      docker0Containers=$(docker network inspect --format='{{ range $k, $v := .Containers }} {{ $k }} {{ end }}' "$net" 2>/dev/null | \
        sed -e 's/^ //' -e 's/  /\n/g')

      if [ -n "$docker0Containers" ]; then
        if [ $fail -eq 0 ]; then
          add_summary "$id" "$desc" "INFO"
          fail=1
        fi
        for c in $docker0Containers; do
          cName=$(docker inspect --format '{{.Name}}' "$c" 2>/dev/null | sed 's/\///g')
          if [ -n "$cName" ]; then
            echo "      * Container in docker0 network: $cName"
            docker_network_containers="$docker_network_containers $c:$cName"
          fi
        done
      fi
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_31() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.31"
  local desc="Ensure that the host's user namespaces are not shared (Automated)"

  fail=0
  hostns_shared_containers=""
  for c in $containers; do
    if docker inspect --format '{{ .HostConfig.UsernsMode }}' "$c" 2>/dev/null | grep -i 'host' >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Namespace shared: $c"
      hostns_shared_containers="$hostns_shared_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

check_5_32() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.32"
  local desc="Ensure that the Docker socket is not mounted inside any containers (Automated)"

  fail=0
  docker_sock_containers=""
  for c in $containers; do
    if docker inspect --format '{{ .Mounts }}' "$c" 2>/dev/null | grep 'docker.sock' >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        add_summary "$id" "$desc" "FAIL"
        fail=1
      fi
      echo "      * Docker socket shared: $c"
      docker_sock_containers="$docker_sock_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    add_summary "$id" "$desc" "PASS"
  fi
}

main() {
  echo "================================================================="
  echo "  Running CIS Docker v1.8.0 - Section 5 Checks (Unaltered Mode) "
  echo "================================================================="

  check_running_containers
  if [ $? -eq 0 ]; then
    check_5
    check_5_1
    check_5_2
    check_5_4
    check_5_5
    check_5_6
    check_5_7
    check_5_8
    check_5_9
    check_5_10
    check_5_11
    check_5_12
    check_5_13
    check_5_14
    check_5_15
    check_5_16
    check_5_17
    check_5_18
    check_5_19
    check_5_20
    check_5_21
    check_5_22
    check_5_25
    check_5_26
    check_5_27
    check_5_28
    check_5_29
    check_5_30
    check_5_31
    check_5_32
  fi

  echo "================================================================="
  echo "                  Section 5 Checks Complete                    "
  echo "================================================================="

    PASS_COUNT=0
    FAIL_COUNT=0
    INFO_COUNT=0
    log_info "5 - Container Runtime"
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
    echo "Remediation script for Section 5 finished."
    echo "=========================================="
}

main
