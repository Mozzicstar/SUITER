#!/usr/bin/env python3
"""
Real API server for SUITER with sample data
This provides the API endpoints needed for the frontend to function
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
import os
from datetime import datetime, timedelta
import random
import sqlite3
from pathlib import Path
import uuid
import hashlib

# Database setup
DB_PATH = "/tmp/suiter.db"
DATA_DIR = Path(DB_PATH).parent

# Sample data — slightly richer content and realistic timestamps
SAMPLE_POSTS = [
    {"author": "Alice", "content": "Just discovered the future of decentralized social networks! #Web3 #SUITER"},
    {"author": "Bob", "content": "Truth and transparency should be the foundation of all digital platforms. Excited about this project!"},
    {"author": "Charlie", "content": "The ability to verify information authenticity is game-changing. SUITER is onto something big."},
    {"author": "Diana", "content": "Love how SUITER combines blockchain with social impact. The attention mechanism is brilliant! 🚀"},
    {"author": "Eve", "content": "Finally a platform where quality content is rewarded. No more algorithmic manipulation!"},
    {"author": "Frank", "content": "The Move smart contracts powering SUITER are incredibly elegant. Impressive engineering!"},
    {"author": "Grace", "content": "This is what decentralized social media should look like. Count me in! 💪"},
    {"author": "Henry", "content": "The reputation system is fair and transparent. Finally platforms care about truth!"},
    {"author": "Ivy", "content": "Joined SUITER today and I'm already seeing high-quality discussions. This is refreshing!"},
    {"author": "Jack", "content": "The UI is clean, the performance is snappy. Great work on making Web3 UX actually usable!"},
]

def init_db():
    """Initialize the database with schema and sample data"""
    # Delete existing DB to start fresh
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Create tables
    cursor.execute('''
        CREATE TABLE posts (
            id TEXT PRIMARY KEY,
            author TEXT,
            content TEXT,
            content_hash TEXT,
            created_at TIMESTAMP,
            updated_at TIMESTAMP,
            attention_accumulated INTEGER DEFAULT 0,
            level INTEGER DEFAULT 1,
            likes INTEGER DEFAULT 0,
            comments INTEGER DEFAULT 0,
            reposts INTEGER DEFAULT 0
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            author TEXT UNIQUE,
            reputation INTEGER DEFAULT 0,
            attention INTEGER DEFAULT 0,
            created_at TIMESTAMP
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE rankings (
            id TEXT PRIMARY KEY,
            author TEXT,
            profile_name TEXT,
            score INTEGER,
            created_at TIMESTAMP
        )
    ''')
    
    # Insert sample posts (compute attention based on recency and content quality)
    now = datetime.now()
    for i, sample in enumerate(SAMPLE_POSTS):
        post_id = str(uuid.uuid4())
        author = sample["author"]
        content = sample["content"]
        content_hash = hashlib.md5(content.encode()).hexdigest()[:16]
        # space posts across the last 24 hours
        minutes_ago = (i * 60) + random.randint(5, 120)
        created_at_dt = now - timedelta(minutes=minutes_ago)
        created_at = created_at_dt.isoformat()
        # attention decreases with age but increases with content length
        length_factor = max(1, min(3, len(content) // 40))
        age_factor = max(1, 24*60 / (minutes_ago + 1))
        attention = int(50 * length_factor * min(age_factor, 10))
        attention = max(1, min(attention, 1000))
        level = 1 + min(4, length_factor)

        # Simple engagement metrics derived from attention
        likes = int(attention * random.uniform(0.1, 0.6))
        comments = random.randint(0, max(0, likes // 4))
        reposts = random.randint(0, max(0, likes // 6))

        cursor.execute('''
            INSERT INTO posts (id, author, content, content_hash, created_at, updated_at, attention_accumulated, level, likes, comments, reposts)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (post_id, author, content, content_hash, created_at, created_at, attention, level, likes, comments, reposts))

        # Create or update profile
        profile_id = str(uuid.uuid4())
        reputation = 100 + attention * random.randint(1, 5)
        profile_attention = attention * random.randint(2, 6)

        cursor.execute('''
            INSERT OR IGNORE INTO profiles (id, author, reputation, attention, created_at)
            VALUES (?, ?, ?, ?, ?)
        ''', (profile_id, author, reputation, profile_attention, created_at))
    
    # Compute rankings from profiles (score by reputation + attention)
    cursor.execute('SELECT author, reputation, attention FROM profiles')
    rows = cursor.fetchall()
    authors_data = []
    for row in rows:
        authors_data.append({
            'author': row[0],
            'score': (row[1] or 0) + (row[2] or 0)
        })

    authors_data.sort(key=lambda x: x['score'], reverse=True)

    for i, author_data in enumerate(authors_data[:20]):
        ranking_id = str(uuid.uuid4())
        cursor.execute('''
            INSERT INTO rankings (id, author, profile_name, score, created_at)
            VALUES (?, ?, ?, ?, ?)
        ''', (ranking_id, author_data['author'], author_data['author'], author_data['score'], now.isoformat()))
    
    conn.commit()
    conn.close()
    print(f"✓ Database initialized at {DB_PATH}")
    print(f"✓ Loaded {len(SAMPLE_POSTS)} sample posts")
    print(f"✓ Created profiles and rankings")

class APIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        try:
            if path == '/api/posts' or path == '/api/posts/feed':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.handle_get_posts()
            elif path.startswith('/api/posts/'):
                post_id = path.split('/')[-1]
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.handle_get_post(post_id)
            elif path == '/api/rankings':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.handle_get_rankings()
            elif path == '/api/profiles':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.handle_get_profiles()
            else:
                self.send_response(404)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Not found'}).encode())
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())
    
    def do_POST(self):
        """Handle POST requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # Read request body
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        
        try:
            if path == '/api/posts':
                data = json.loads(body.decode()) if body else {}
                self.send_response(201)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.handle_create_post(data)
            elif path == '/api/profiles':
                data = json.loads(body.decode()) if body else {}
                self.send_response(201)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.handle_create_profile(data)
            else:
                self.send_response(404)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Not found'}).encode())
        except json.JSONDecodeError as e:
            self.send_response(400)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'error': f'Invalid JSON: {str(e)}'}).encode())
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())
    
    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Access-Control-Allow-Credentials', 'true')
        self.end_headers()
    
    def handle_get_posts(self):
        """Get all posts"""
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, author, content, content_hash, created_at, 
                   attention_accumulated, level, likes, comments, reposts
            FROM posts
            ORDER BY created_at DESC
            LIMIT 100
        ''')
        
        rows = cursor.fetchall()
        posts = [dict(row) for row in rows]
        conn.close()
        
        self.wfile.write(json.dumps(posts).encode())
    
    def handle_get_post(self, post_id):
        """Get a single post"""
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, author, content, content_hash, created_at,
                   attention_accumulated, level, likes, comments, reposts
            FROM posts
            WHERE id = ?
        ''', (post_id,))
        
        row = cursor.fetchone()
        conn.close()
        
        if row:
            self.wfile.write(json.dumps(dict(row)).encode())
        else:
            self.wfile.write(json.dumps({'error': 'Post not found'}).encode())
    
    def handle_create_post(self, data):
        """Create a new post"""
        author = data.get('author', 'anonymous').strip() or 'anonymous'
        content = data.get('content', '').strip()
        
        if not content:
            self.wfile.write(json.dumps({'error': 'Content cannot be empty'}).encode())
            return
        
        post_id = str(uuid.uuid4())
        content_hash = hashlib.md5(content.encode()).hexdigest()[:16]
        now_dt = datetime.now()
        now = now_dt.isoformat()

        # Compute sensible attention and derived metrics from content quality
        length_factor = max(1, min(3, len(content) // 40))
        attention = int(20 * length_factor * random.uniform(1.0, 2.5))
        attention = max(1, attention)
        level = 1 + min(4, length_factor)
        likes = int(attention * random.uniform(0.1, 0.6))
        comments = random.randint(0, max(0, likes // 4))
        reposts = random.randint(0, max(0, likes // 6))

        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        try:
            cursor.execute('''
                INSERT INTO posts (id, author, content, content_hash, created_at, updated_at, attention_accumulated, level, likes, comments, reposts)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (post_id, author, content, content_hash, now, now, attention, level, likes, comments, reposts))
            
            # Update or create profile: make reputation change meaningful
            cursor.execute('SELECT id, reputation, attention FROM profiles WHERE author = ?', (author,))
            row = cursor.fetchone()
            if row:
                # row is tuple (id, reputation, attention)
                new_reputation = (row[1] or 0) + random.randint(1, 10)
                new_attention = (row[2] or 0) + attention
                cursor.execute('UPDATE profiles SET reputation = ?, attention = ? WHERE author = ?', (new_reputation, new_attention, author))
            else:
                cursor.execute('INSERT INTO profiles (id, author, reputation, attention, created_at) VALUES (?, ?, ?, ?, ?)',
                               (str(uuid.uuid4()), author, 50 + random.randint(0, 100), attention, now))
            
            conn.commit()
            
            self.wfile.write(json.dumps({
                'id': post_id,
                'author': author,
                'content': content,
                'content_hash': content_hash,
                'created_at': now,
                'attention_accumulated': attention,
                'level': level,
                'likes': likes,
                'comments': comments,
                'reposts': reposts
            }).encode())
        except Exception as e:
            conn.rollback()
            self.wfile.write(json.dumps({'error': f'Failed to create post: {str(e)}'}).encode())
        finally:
            conn.close()
    
    def handle_get_rankings(self):
        """Get rankings"""
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, author, profile_name, score, created_at
            FROM rankings
            ORDER BY score DESC
            LIMIT 20
        ''')
        
        rows = cursor.fetchall()
        rankings = [dict(row) for row in rows]
        
        # If no rankings in DB, generate some sample data
        if not rankings:
            sample_authors = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve']
            for i, author in enumerate(sample_authors[:3], 1):
                rankings.append({
                    'id': str(i),
                    'author': author,
                    'profile_name': author,
                    'score': 1000 - (i * 100),
                    'created_at': datetime.now().isoformat()
                })
        
        conn.close()
        self.wfile.write(json.dumps(rankings).encode())
    
    def handle_get_profiles(self):
        """Get profiles"""
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, author, reputation, attention, created_at
            FROM profiles
            ORDER BY reputation DESC
            LIMIT 50
        ''')
        
        rows = cursor.fetchall()
        profiles = [dict(row) for row in rows]
        conn.close()
        
        self.wfile.write(json.dumps(profiles).encode())
    
    def handle_create_profile(self, data):
        """Create a new profile"""
        author = data.get('author', 'anonymous').strip() or 'anonymous'
        now = datetime.now().isoformat()
        profile_id = str(uuid.uuid4())
        
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        try:
            cursor.execute('''
                INSERT OR IGNORE INTO profiles (id, author, reputation, attention, created_at)
                VALUES (?, ?, ?, ?, ?)
            ''', (profile_id, author, random.randint(10, 100), random.randint(0, 200), now))
            conn.commit()
        except sqlite3.IntegrityError:
            pass  # Profile already exists
        finally:
            conn.close()
        
        self.wfile.write(json.dumps({
            'id': profile_id,
            'author': author,
            'reputation': random.randint(10, 100),
            'attention': random.randint(0, 200),
            'created_at': now
        }).encode())
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

def run_server(port=3000):
    """Run the API server"""
    init_db()
    
    server_address = ('', port)
    httpd = HTTPServer(server_address, APIHandler)
    
    print(f"✓ SUITER API Server started on http://localhost:{port}")
    print(f"✓ Database: {DB_PATH}")
    print(f"✓ Ready to accept requests")
    print()
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n✗ Server stopped")
        httpd.server_close()

if __name__ == '__main__':
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
    run_server(port)
