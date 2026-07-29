#!/usr/bin/env python3
"""
Railway Auto Config API
این سرویس در پسزمینه اجرا میشود و کانفیگهای بهینه برای Railway تولید میکند
"""
import http.server
import json
import uuid
import random
import string
import urllib.parse
import signal
import sys
import time
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger("railway-auto-api")

class RailwayConfigHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/api/railway-auto':
            content_length = int(self.headers.get('Content-Length', 0))
            try:
                post_data = self.rfile.read(content_length)
            except Exception as e:
                logger.error("Failed to read request body: %s", e)
                self._json_response(400, {'success': False, 'error': 'invalid request body'})
                return
            
            try:
                data = json.loads(post_data.decode('utf-8'))
            except Exception as e:
                logger.error("Invalid JSON: %s", e)
                self._json_response(400, {'success': False, 'error': 'invalid JSON'})
                return
            
            protocol = data.get('protocol', 'vless-ws')
            domain = data.get('domain', '')
            
            # Basic validation
            if not domain or not isinstance(domain, str) or '.' not in domain:
                self._json_response(400, {'success': False, 'error': 'valid domain is required'})
                return
            
            protocol = protocol.strip().lower()
            if protocol not in ('vless-ws', 'vless-reality', 'vless-xhttp'):
                self._json_response(400, {'success': False, 'error': f'unsupported protocol: {protocol}'})
                return
            
            try:
                config = self._build_config(domain, protocol)
                self._json_response(200, {
                    'success': True,
                    'obj': config,
                    'meta': {
                        'generated_at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                        'protocol': protocol,
                        'domain': domain,
                    }
                })
            except Exception as e:
                logger.error("Config generation failed: %s", e)
                self._json_response(500, {'success': False, 'error': 'internal server error'})
            return
        
        self._json_response(404, {'success': False, 'error': 'not found'})
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def _json_response(self, status, data):
        payload = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)
    
    def log_message(self, format, *args):
        logger.debug(format, *args)
    
    def _build_config(self, domain, protocol):
        config_uuid = str(uuid.uuid4())
        random_path = '/' + ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
        
        if protocol == 'vless-ws':
            return {
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
            return {
                'uuid': config_uuid,
                'port': 1080,
                'protocol': 'vless',
                'network': 'tcp',
                'security': 'reality',
                'path': random_path,
                'host': domain,
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
            return {
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
        raise ValueError(f"Unsupported protocol: {protocol}")

def run():
    server = HTTPServer(('127.0.0.1', 2054), RailwayConfigHandler)
    logger.info('Railway Auto Config API running on 127.0.0.1:2054')
    
    def handle_signal(signum, frame):
        logger.info('Received signal %s, shutting down...', signum)
        server.shutdown()
        sys.exit(0)
    
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        logger.info('Server stopped')

if __name__ == '__main__':
    run()
