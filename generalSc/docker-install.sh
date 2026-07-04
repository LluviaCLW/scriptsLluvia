#!/bin/bash

# 脚本名称：docker_install.sh
# 功能描述：安装Docker、配置镜像加速器及Docker Compose

# 输出带时间戳的日志信息
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 检查命令执行结果
check_status() {
    if [ $? -ne 0 ]; then
        log "错误：$1 执行失败"
        exit 1
    else
        log "$1 执行成功"
    fi
}

# 主函数
main() {
    log "开始执行Docker安装与配置脚本"
    
    # 关闭swap分区
    log "关闭swap分区"
    swapoff -a
    check_status "关闭swap分区"
    
    # 备份hosts文件
    log "备份hosts文件"
    cp /etc/hosts /etc/hosts.bak
    check_status "备份hosts文件"
    
    # 配置hosts文件
    log "配置hosts文件"
    echo "185.199.111.133 raw.githubusercontent.com">> /etc/hosts
    check_status "配置hosts文件"
    
    # 更新软件包索引
    log "更新软件包索引"
    apt update
    check_status "更新软件包索引"
    
    # 安装Docker
    log "安装Docker"
    apt install -y docker.io
    check_status "安装Docker"
    
    # 启动Docker服务
    log "启动Docker服务"
    systemctl start docker
    check_status "启动Docker服务"
    
    # 设置Docker服务开机自启
    log "设置Docker服务开机自启"
    systemctl enable docker
    check_status "设置Docker服务开机自启"
    
    # 创建Docker配置目录
    log "创建Docker配置目录"
    mkdir -p /etc/docker
    check_status "创建Docker配置目录"
    
    # 配置Docker镜像加速器
    log "配置Docker镜像加速器"
    tee /etc/docker/daemon.json <<EOF > /dev/null
{
    "registry-mirrors": [
        "https://docker.1ms.run",
        "https://docker.anyhub.us.kg",
        "https://dockerhub.jobcher.com",
        "https://dockerhub.icu"
    ]
}
EOF
    check_status "配置Docker镜像加速器"
    
    # 重新加载Docker配置
    log "重新加载Docker配置"
    systemctl daemon-reload
    check_status "重新加载Docker配置"
    
    # 重启Docker服务
    log "重启Docker服务"
    systemctl restart docker
    check_status "重启Docker服务"
    
    # 安装Docker Compose
    log "安装Docker Compose"
    curl -L "https://1ms.run/install/docker-compose/latest/$(uname -s)/$(uname -m)" -o /usr/local/bin/docker-compose
    check_status "下载Docker Compose"
    
    # 设置Docker Compose执行权限
    log "设置Docker Compose执行权限"
    chmod +x /usr/local/bin/docker-compose
    check_status "设置Docker Compose执行权限"
    
    # 创建Docker Compose软链接
    log "创建Docker Compose软链接"
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    check_status "创建Docker Compose软链接"
    
    log "Docker安装与配置脚本执行完成"
}

# 执行主函数
main


