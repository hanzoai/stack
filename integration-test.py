#!/usr/bin/env python3
"""
Hanzo Stack Integration Test
Tests the core functionality of the stack
"""

import os
import sys
import time
import json
import subprocess
import requests
from typing import Dict, Any, List

# Colors for output
GREEN = '\033[0;32m'
RED = '\033[0;31m'
YELLOW = '\033[0;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'

def log(message: str, color: str = GREEN):
    """Print colored log message"""
    print(f"{color}[{time.strftime('%H:%M:%S')}]{NC} {message}")

def error(message: str):
    """Print error message"""
    log(message, RED)

def info(message: str):
    """Print info message"""
    log(message, BLUE)

def warning(message: str):
    """Print warning message"""
    log(message, YELLOW)

class HanzoStackTest:
    """Main test class for Hanzo Stack"""
    
    def __init__(self):
        self.services = {}
        self.test_results = []
        
    def check_docker(self) -> bool:
        """Check if Docker is running"""
        try:
            result = subprocess.run(['docker', 'info'], 
                                  capture_output=True, 
                                  text=True)
            return result.returncode == 0
        except:
            return False
            
    def start_service(self, name: str, image: str, 
                     ports: Dict[str, str], 
                     env: Dict[str, str] = None,
                     command: List[str] = None) -> str:
        """Start a Docker container"""
        cmd = ['docker', 'run', '-d', f'--name={name}']
        
        # Add ports
        for host_port, container_port in ports.items():
            cmd.extend(['-p', f'{host_port}:{container_port}'])
            
        # Add environment variables
        if env:
            for key, value in env.items():
                cmd.extend(['-e', f'{key}={value}'])
                
        # Add image
        cmd.append(image)
        
        # Add command
        if command:
            cmd.extend(command)
            
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                container_id = result.stdout.strip()
                self.services[name] = container_id
                return container_id
            else:
                error(f"Failed to start {name}: {result.stderr}")
                return None
        except Exception as e:
            error(f"Error starting {name}: {e}")
            return None
            
    def wait_for_health(self, url: str, timeout: int = 30) -> bool:
        """Wait for a service to be healthy"""
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = requests.get(url, timeout=5)
                if response.status_code == 200:
                    return True
            except:
                pass
            time.sleep(1)
        return False
        
    def test_postgres(self):
        """Test PostgreSQL"""
        info("Testing PostgreSQL...")
        
        container_id = self.start_service(
            'test-postgres',
            'postgres:16-alpine',
            {'5432': '5432'},
            {
                'POSTGRES_USER': 'hanzo',
                'POSTGRES_PASSWORD': 'hanzo123',
                'POSTGRES_DB': 'hanzo_test'
            }
        )
        
        if not container_id:
            self.test_results.append(('PostgreSQL', False, 'Failed to start'))
            return
            
        time.sleep(5)
        
        # Test connection
        result = subprocess.run(
            ['docker', 'exec', 'test-postgres', 
             'pg_isready', '-U', 'hanzo'],
            capture_output=True
        )
        
        if result.returncode == 0:
            log("✓ PostgreSQL is healthy")
            self.test_results.append(('PostgreSQL', True, 'Healthy'))
        else:
            error("✗ PostgreSQL is not healthy")
            self.test_results.append(('PostgreSQL', False, 'Not healthy'))
            
    def test_redis(self):
        """Test Redis"""
        info("Testing Redis...")
        
        container_id = self.start_service(
            'test-redis',
            'redis:7-alpine',
            {'6379': '6379'},
            command=['redis-server', '--requirepass', 'hanzo123']
        )
        
        if not container_id:
            self.test_results.append(('Redis', False, 'Failed to start'))
            return
            
        time.sleep(3)
        
        # Test connection
        result = subprocess.run(
            ['docker', 'exec', 'test-redis', 
             'redis-cli', '-a', 'hanzo123', 'ping'],
            capture_output=True,
            text=True
        )
        
        if 'PONG' in result.stdout:
            log("✓ Redis is healthy")
            self.test_results.append(('Redis', True, 'Healthy'))
        else:
            error("✗ Redis is not healthy")
            self.test_results.append(('Redis', False, 'Not healthy'))
            
    def test_litellm(self):
        """Test LiteLLM Router"""
        info("Testing LiteLLM Router...")
        
        # Create config file
        config = {
            "model_list": [{
                "model_name": "gpt-3.5-turbo",
                "litellm_params": {
                    "model": "gpt-3.5-turbo",
                    "mock_response": "This is a test response from the Hanzo Stack"
                }
            }]
        }
        
        with open('/tmp/litellm-config.json', 'w') as f:
            json.dump(config, f)
            
        container_id = self.start_service(
            'test-litellm',
            'ghcr.io/berriai/litellm:main-stable',
            {'4000': '4000'},
            {
                'LITELLM_MASTER_KEY': 'sk-test',
                'DATABASE_URL': 'postgresql://hanzo:hanzo123@host.docker.internal:5432/hanzo_test'
            },
            command=['--config', '/tmp/config.json', '--port', '4000']
        )
        
        if not container_id:
            self.test_results.append(('LiteLLM', False, 'Failed to start'))
            return
            
        # Copy config
        subprocess.run([
            'docker', 'cp', '/tmp/litellm-config.json', 
            'test-litellm:/tmp/config.json'
        ])
        
        # Restart to load config
        subprocess.run(['docker', 'restart', 'test-litellm'])
        time.sleep(10)
        
        # Test health
        if self.wait_for_health('http://localhost:4000/health'):
            log("✓ LiteLLM is healthy")
            
            # Test chat completion
            try:
                response = requests.post(
                    'http://localhost:4000/v1/chat/completions',
                    headers={
                        'Authorization': 'Bearer sk-test',
                        'Content-Type': 'application/json'
                    },
                    json={
                        'model': 'gpt-3.5-turbo',
                        'messages': [{'role': 'user', 'content': 'Hello'}]
                    }
                )
                
                if response.status_code == 200:
                    data = response.json()
                    if 'choices' in data:
                        log("✓ LiteLLM chat completion works")
                        self.test_results.append(('LiteLLM', True, 'Fully functional'))
                    else:
                        error("✗ LiteLLM response missing choices")
                        self.test_results.append(('LiteLLM', False, 'Invalid response'))
                else:
                    error(f"✗ LiteLLM returned {response.status_code}")
                    self.test_results.append(('LiteLLM', False, f'HTTP {response.status_code}'))
            except Exception as e:
                error(f"✗ LiteLLM test failed: {e}")
                self.test_results.append(('LiteLLM', False, str(e)))
        else:
            error("✗ LiteLLM health check failed")
            subprocess.run(['docker', 'logs', 'test-litellm'])
            self.test_results.append(('LiteLLM', False, 'Health check failed'))
            
    def cleanup(self):
        """Clean up all containers"""
        info("Cleaning up...")
        for name, container_id in self.services.items():
            subprocess.run(['docker', 'stop', name], capture_output=True)
            subprocess.run(['docker', 'rm', name], capture_output=True)
            
    def print_summary(self):
        """Print test summary"""
        print("\n" + "="*50)
        print("Test Summary")
        print("="*50)
        
        passed = 0
        failed = 0
        
        for service, success, message in self.test_results:
            status = f"{GREEN}✓ PASS{NC}" if success else f"{RED}✗ FAIL{NC}"
            print(f"{service:.<20} {status} ({message})")
            if success:
                passed += 1
            else:
                failed += 1
                
        print("="*50)
        print(f"Total: {passed + failed} | Passed: {passed} | Failed: {failed}")
        
        if failed == 0:
            log("\nAll tests passed! 🎉")
        else:
            error(f"\n{failed} tests failed")
            
        return failed == 0
        
    def run(self):
        """Run all tests"""
        log("Starting Hanzo Stack Integration Tests")
        
        # Check Docker
        if not self.check_docker():
            error("Docker is not running!")
            sys.exit(1)
            
        log("✓ Docker is running")
        
        try:
            # Run tests
            self.test_postgres()
            self.test_redis()
            self.test_litellm()
            
            # Print summary
            success = self.print_summary()
            
            # Exit code
            sys.exit(0 if success else 1)
            
        finally:
            self.cleanup()

if __name__ == "__main__":
    test = HanzoStackTest()
    test.run()