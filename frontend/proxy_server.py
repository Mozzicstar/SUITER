#!/usr/bin/env python3
"""
Frontend server with API proxy support.
Serves static files from the current directory and proxies /api/* requests to the API server.
"""

from http.server import HTTPServer, SimpleHTTPRequestHandler
import sys
import json
from urllib.parse import urlparse
import urllib.request
import urllib.error

class ProxyHandler(SimpleHTTPRequestHandler):
    """HTTP request handler with API proxy support"""
    
    API_SERVER = "http://127.0.0.1:3000"
    
    def do_GET(self):
        """Handle GET requests - serve static files"""
        if self.path.startswith('/api/'):
            self.proxy_request('GET')
        else:
            super().do_GET()
    
    def do_POST(self):
        """Handle POST requests - proxy to API"""
        if self.path.startswith('/api/'):
            self.proxy_request('POST')
        else:
            self.send_error(404)
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def proxy_request(self, method):
        """Proxy API requests to the backend server"""
        url = f"{self.API_SERVER}{self.path}"
        
        try:
            # Read request body if present
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else None
            
            # Create request
            req = urllib.request.Request(url, data=body, method=method)
            
            # Add content-type header if present
            if 'Content-Type' in self.headers:
                req.add_header('Content-Type', self.headers['Content-Type'])
            
            # Make request
            with urllib.request.urlopen(req) as response:
                status = response.status
                headers = dict(response.headers)
                content = response.read()
            
            # Send response
            self.send_response(status)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Content-Type', headers.get('Content-Type', 'application/json'))
            self.send_header('Content-Length', len(content))
            self.end_headers()
            
            self.wfile.write(content)
            
        except urllib.error.HTTPError as e:
            # Forward the error response from the API
            self.send_response(e.code)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            error_content = json.dumps({'error': f'API error: {e.reason}'}).encode()
            self.wfile.write(error_content)
        except Exception as e:
            self.send_response(500)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            error_content = json.dumps({'error': f'Proxy error: {str(e)}'}).encode()
            self.wfile.write(error_content)
    
    def log_message(self, format, *args):
        """Custom logging"""
        # Log API requests differently
        if self.path.startswith('/api/'):
            print(f"{self.client_address[0]} - - [{self.log_date_time_string()}] \"{self.command} {self.path} {self.request_version}\" (proxied)")
        else:
            super().log_message(format, *args)

def run_server(port=8080):
    """Start the proxy server"""
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, ProxyHandler)
    
    print(f"✓ SUITER Frontend Server started on http://localhost:{port}")
    print(f"✓ Serving static files and proxying to API at {ProxyHandler.API_SERVER}")
    print(f"✓ Ready to accept requests")
    print()
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n✗ Server stopped")
        httpd.server_close()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    run_server(port)
