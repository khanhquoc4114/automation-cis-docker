#!/bin/bash
NODES=2
BASE_PORT=2221

echo "[INFO] Tạo $NODES container..."
for i in $(seq 1 $NODES); do
    NODE_NAME="node0$i"
    SSH_PORT=$((BASE_PORT + i - 1))
    
    echo "[INFO] Tạo container: $NODE_NAME (SSH port: $SSH_PORT)"
    docker run -d --name ${NODE_NAME} -p ${SSH_PORT}:22 alpine:latest sleep infinity
    
    echo "[INFO] Cài đặt SSH và Python..."
    docker exec ${NODE_NAME} sh -c "
        apk update &&
        apk add --no-cache openssh openssh-sftp-server python3 bash &&
        ssh-keygen -A &&
        echo 'root:123123' | chpasswd &&
        sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        mkdir -p /run/sshd
    "
    
    echo "[INFO] Khởi động SSH..."
    docker exec -d ${NODE_NAME} /usr/sbin/sshd -D
    sleep 2
    
    echo "[SUCCESS] Container ${NODE_NAME} sẵn sàng ở port ${SSH_PORT}"
done

echo ""
echo "====================================="
echo "[INFO] DONE! $NODES containers ready."
echo "====================================="
echo "Test SSH: ssh root@127.0.0.1 -p $BASE_PORT (password: 123123)"