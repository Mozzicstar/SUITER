#!/usr/bin/env python3
"""
Simple frontend server with no-cache headers
"""
from http.server import HTTPServer, SimpleHTTPRequestHandler, BaseHTTPRequestHandler
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
import io
import os
import sys

class NoCacheHandler(SimpleHTTPRequestHandler):
    API_BASE = 'http://127.0.0.1:3000'

    def end_headers(self):
        # Force no cache
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def do_GET(self):
        # Proxy API calls to backend
        if self.path.startswith('/api/'):
            self._proxy_request('GET')
            return
        return super().do_GET()

    def do_POST(self):
        if self.path.startswith('/api/'):
            self._proxy_request('POST')
            return
        return super().do_POST()

    def do_OPTIONS(self):
        if self.path.startswith('/api/'):
            # Respond to preflight
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type')
            self.end_headers()
            return
        return super().do_OPTIONS()

    def do_HEAD(self):
        # Proxy HEAD requests to API to avoid 404s from health checks
        if self.path.startswith('/api/'):
            try:
                target_url = f"{self.API_BASE}{self.path}"
                req = Request(target_url, method='HEAD')
                resp = urlopen(req, timeout=5)
                self.send_response(resp.getcode())
                for k, v in resp.getheaders():
                    if k.lower() in ('transfer-encoding', 'connection', 'keep-alive'):
                        continue
                    self.send_header(k, v)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
            except Exception:
                self.send_response(502)
                self.end_headers()
            return
        return super().do_HEAD()

    def _proxy_request(self, method):
        target_url = f"{self.API_BASE}{self.path}"
        try:
            headers = {k: v for k, v in self.headers.items()}
            data = None
            if method == 'POST':
                length = int(self.headers.get('Content-Length', 0))
                data = self.rfile.read(length) if length > 0 else None

            req = Request(target_url, data=data, headers=headers, method=method)
            resp = urlopen(req, timeout=10)

            self.send_response(resp.getcode())
            for k, v in resp.getheaders():
                if k.lower() in ('transfer-encoding', 'connection', 'keep-alive'):
                    continue
                self.send_header(k, v)
            # Ensure CORS for frontend
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            body = resp.read()
            self.wfile.write(body)
        except HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            try:
                self.wfile.write(e.read())
            except Exception:
                pass
        except URLError as e:
            self.send_response(502)
            self.end_headers()
            self.wfile.write(b'')




if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    os.chdir('/workspaces/SUITER/frontend')
    server = HTTPServer(('0.0.0.0', port), NoCacheHandler)
    print(f"✓ Frontend Server running on http://localhost:{port}")
    print(f"✓ No-cache headers enabled")
    print(f"✓ API: http://localhost:3000")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n✗ Server stopped")
        server.server_close()
