#!/usr/bin/env python3
"""
Railway Auto Config API
این سرویس در پس‌زمینه اجرا می‌شود و کانفیگ‌های بهینه برای Railway تولید می‌کند
"""
import http.server
import json
import uuid
import random
import string
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler

class RailwayConfigHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/api/railway-auto':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                protocol = data.get('protocol', 'vless-ws')  # vless-ws, vless-reality, vless-xhttp
                domain = data.get('domain', '')
                
                # تولید مقادیر اتوماتیک
                config_uuid = str(uuid.uuid4())
                random_path = '/' + ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
                
                # تنظیمات بر اساس پروتکل انتخابی
                if protocol == 'vless-ws':
                    config = {
                        'uuid': config_uuid,
                        'port': 1080,
                        'protocol': 'vless',
                        'network': 'ws',
                        'security': 'none',
                        'path': random_path,
                        'host': domain,
                        'client_config': {
                            'port': 443,
                            'security': 'tls',
                            'sni': domain,
                            'fp': 'chrome',
                            'type': 'ws',
                            'host': domain,
                            'path': random_path
                        }
                    }
                elif protocol == 'vless-reality':
                    # برای Reality نیاز به public key داریم که از xray تولید می‌شود
                    config = {
                        'uuid': config_uuid,
                        'port': 1080,
                        'protocol': 'vless',
                        'network': 'tcp',
                        'security': 'reality',
                        'reality_settings': {
                            'dest': 'www.microsoft.com:443',
                            'serverNames': ['www.microsoft.com', 'microsoft.com'],
                            'privateKey': 'PLACEHOLDER_PRIVATE_KEY',
                            'shortIds': ['']
                        },
                        'client_config': {
                            'port': 443,
                            'security': 'reality',
                            'sni': 'www.microsoft.com',
                            'fp': 'chrome',
                            'pbk': 'PLACEHOLDER_PUBLIC_KEY',
                            'sid': '',
                            'type': 'tcp'
                        }
                    }
                elif protocol == 'vless-xhttp':
                    config = {
                        'uuid': config_uuid,
                        'port': 1080,
                        'protocol': 'vless',
                        'network': 'xhttp',
                        'security': 'none',
                        'path': random_path,
                        'host': domain,
                        'client_config': {
                            'port': 443,
                            'security': 'tls',
                            'sni': domain,
                            'fp': 'chrome',
                            'type': 'xhttp',
                            'host': domain,
                            'path': random_path,
                            'mode': 'auto'
                        }
                    }
                else:
                    config = {'error': 'Unsupported protocol'}
                
                # ارسال پاسخ
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({'success': True, 'obj': config}).encode('utf-8'))
                
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'success': False, 'error': str(e)}).encode('utf-8'))
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def log_message(self, format, *args):
        pass  # غیرفعال کردن لاگ‌های اضافی

if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', 2054), RailwayConfigHandler)
    print('🤖 Railway Auto Config API running on port 2054')
    server.serve_forever()
