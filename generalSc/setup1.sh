
#!/bin/bash

set -e  # 遇到错误立即停止，避免后面的命令继续执行

echo "开始安装软件"

# 更新软件源
apt update

apt install vim -y
apt install curl -y
apt install open-vm-tools-desktop -y
apt install ssh -y

echo "软件安装完成，开始配置 SSH"

systemctl start ssh
systemctl enable ssh
systemctl status ssh --no-pager

echo "OK"
