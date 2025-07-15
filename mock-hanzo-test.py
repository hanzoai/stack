#!/usr/bin/env python3
"""
Mock Hanzo Stack Test
Simulates Hanzo services for testing the stack architecture
"""

import os
import sys
import time
import json
import threading
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Colors
GREEN = '\033[0;32m'
RED = '\033[0;31m'
BLUE = '\033[0;34m'
NC = '\033[0m'

def log(msg, color=GREEN):
    print(f"{color}[{time.strftime('%H:%M:%S')}]{NC} {msg}")

def error(msg):
    log(msg, RED)

def info(msg):
    log(msg, BLUE)

class HanzoLLMHandler(BaseHTTPRequestHandler):
    """Mock Hanzo LLM Router"""
    
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "healthy",
                "service": "hanzo-llm-router",
                "version": "1.0.0"
            }).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        if self.path == '/v1/chat/completions':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            request = json.loads(post_data)
            
            # Mock response
            response = {
                "id": "chatcmpl-hanzo-" + str(int(time.time())),
                "object": "chat.completion",
                "created": int(time.time()),
                "model": request.get("model", "gpt-3.5-turbo"),
                "choices": [{
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "This is a response from Hanzo LLM Router (mock mode)"
                    },
                    "finish_reason": "stop"
                }],
                "usage": {
                    "prompt_tokens": 10,
                    "completion_tokens": 15,
                    "total_tokens": 25
                }
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # Suppress logs

class HanzoAPIHandler(BaseHTTPRequestHandler):
    """Mock Hanzo API"""
    
    projects = {}
    traces = {}
    
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "healthy",
                "service": "hanzo-api",
                "version": "1.0.0",
                "database": "connected",
                "redis": "connected"
            }).encode())
        elif self.path == '/docs':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(b"<html><body><h1>Hanzo API Documentation</h1></body></html>")
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        if self.path == '/api/v1/projects':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            project = json.loads(post_data)
            
            project_id = f"proj_{int(time.time())}"
            project['id'] = project_id
            project['created_at'] = time.time()
            
            HanzoAPIHandler.projects[project_id] = project
            
            self.send_response(201)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(project).encode())
            
        elif self.path == '/api/v1/traces':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            trace = json.loads(post_data)
            
            trace_id = f"trace_{int(time.time())}"
            trace['id'] = trace_id
            trace['created_at'] = time.time()
            
            HanzoAPIHandler.traces[trace_id] = trace
            
            self.send_response(201)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(trace).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass

def start_mock_server(handler_class, port, name):
    """Start a mock server in a thread"""
    server = HTTPServer(('localhost', port), handler_class)
    thread = threading.Thread(target=server.serve_forever)
    thread.daemon = True
    thread.start()
    log(f"Started mock {name} on port {port}")
    return server

def start_infrastructure():
    """Start infrastructure services"""
    log("Starting infrastructure services...")
    
    # PostgreSQL
    subprocess.run([
        'docker', 'run', '-d', '--name', 'test-postgres',
        '-e', 'POSTGRES_USER=hanzo',
        '-e', 'POSTGRES_PASSWORD=hanzo123',
        '-e', 'POSTGRES_DB=hanzo',
        '-p', '5432:5432',
        'postgres:16-alpine'
    ], capture_output=True)
    
    # Redis
    subprocess.run([
        'docker', 'run', '-d', '--name', 'test-redis',
        '-p', '6379:6379',
        'redis:7-alpine', 'redis-server', '--requirepass', 'hanzo123'
    ], capture_output=True)
    
    time.sleep(5)
    log("✓ Infrastructure started")

def run_tests():
    """Run integration tests"""
    log("Running integration tests...")
    
    # Test 1: Health checks
    info("Test 1: Health checks")
    
    import requests
    
    # LLM Router health
    try:
        resp = requests.get('http://localhost:4000/health')
        if resp.status_code == 200:
            log("✓ LLM Router health check passed")
        else:
            error("✗ LLM Router health check failed")
    except Exception as e:
        error(f"✗ LLM Router error: {e}")
    
    # API health
    try:
        resp = requests.get('http://localhost:8000/health')
        if resp.status_code == 200:
            log("✓ API health check passed")
        else:
            error("✗ API health check failed")
    except Exception as e:
        error(f"✗ API error: {e}")
    
    # Test 2: Create project
    info("Test 2: Project creation")
    try:
        resp = requests.post('http://localhost:8000/api/v1/projects',
                           json={
                               "name": "Test Project",
                               "description": "Integration test"
                           },
                           headers={"Authorization": "Bearer test"})
        if resp.status_code == 201:
            project = resp.json()
            log(f"✓ Created project: {project['id']}")
            
            # Test 3: Create trace
            info("Test 3: Trace creation")
            resp = requests.post('http://localhost:8000/api/v1/traces',
                               json={
                                   "project_id": project['id'],
                                   "name": "test-trace",
                                   "input": {"test": True}
                               },
                               headers={"Authorization": "Bearer test"})
            if resp.status_code == 201:
                trace = resp.json()
                log(f"✓ Created trace: {trace['id']}")
            else:
                error("✗ Trace creation failed")
        else:
            error("✗ Project creation failed")
    except Exception as e:
        error(f"✗ Test error: {e}")
    
    # Test 4: LLM chat completion
    info("Test 4: LLM chat completion")
    try:
        resp = requests.post('http://localhost:4000/v1/chat/completions',
                           json={
                               "model": "gpt-3.5-turbo",
                               "messages": [{"role": "user", "content": "Hello"}]
                           },
                           headers={"Authorization": "Bearer sk-test"})
        if resp.status_code == 200:
            completion = resp.json()
            log(f"✓ LLM response: {completion['choices'][0]['message']['content']}")
        else:
            error("✗ LLM chat completion failed")
    except Exception as e:
        error(f"✗ LLM error: {e}")

def cleanup():
    """Clean up services"""
    log("Cleaning up...")
    subprocess.run(['docker', 'stop', 'test-postgres', 'test-redis'], 
                   capture_output=True)
    subprocess.run(['docker', 'rm', 'test-postgres', 'test-redis'], 
                   capture_output=True)

def main():
    log("Hanzo Stack Mock Test")
    log("====================")
    
    try:
        # Start infrastructure
        start_infrastructure()
        
        # Start mock services
        llm_server = start_mock_server(HanzoLLMHandler, 4000, "LLM Router")
        api_server = start_mock_server(HanzoAPIHandler, 8000, "API")
        
        time.sleep(2)
        
        # Run tests
        run_tests()
        
        # Summary
        print("\n" + "="*50)
        log("Mock services are running!")
        print("="*50)
        print("\nService URLs:")
        print("  LLM Router: http://localhost:4000")
        print("  API:        http://localhost:8000")
        print("  API Docs:   http://localhost:8000/docs")
        print("\nPress Enter to stop...")
        
        input()
        
    finally:
        cleanup()
        log("Test complete")

if __name__ == "__main__":
    main()