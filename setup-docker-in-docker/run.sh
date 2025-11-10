#!/bin/bash

# Chuẩn bị
sudo apt update
sudo apt install -y sshpass
sudo apt install ansible-core
./setup.sh

# Chay playbook
ansible docker_nodes -i inventory.ini -m ping
ansible-playbook -i inventory.ini run-cis.yml

# Xoá toàn bộ node*
#docker rm -f $(docker ps -aq -f name=node0)

# Kết nối vào node0
#ssh root@127.0.0.1 -p 2221
