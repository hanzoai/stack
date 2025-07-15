#!/bin/bash

# Browser-based Integration Tests for Hanzo Stack
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log "Hanzo Stack Browser Integration Tests"
log "====================================="

# Check if Chrome is installed
if ! command -v google-chrome &> /dev/null && ! command -v chromium &> /dev/null; then
    error "Chrome/Chromium not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install --cask google-chrome
    else
        sudo apt-get update && sudo apt-get install -y chromium-browser
    fi
fi

# Install Playwright if needed
info "Setting up Playwright..."
pip install playwright pytest-playwright 2>/dev/null || true
playwright install chromium

# Create browser test script
cat > /tmp/browser_integration_test.py << 'EOF'
import asyncio
import json
from playwright.async_api import async_playwright
import pytest

class HanzoStackBrowserTest:
    def __init__(self):
        self.results = []
        self.browser = None
        self.context = None
        
    async def setup(self):
        """Setup browser and context"""
        playwright = await async_playwright().start()
        self.browser = await playwright.chromium.launch(
            headless=True,
            args=['--no-sandbox', '--disable-setuid-sandbox']
        )
        self.context = await self.browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            ignore_https_errors=True
        )
        
    async def teardown(self):
        """Cleanup browser"""
        if self.context:
            await self.context.close()
        if self.browser:
            await self.browser.close()
            
    async def test_infrastructure_ui(self):
        """Test infrastructure web UIs"""
        print("\n🧪 Testing Infrastructure Web UIs...")
        
        # Test MinIO Console
        try:
            page = await self.context.new_page()
            await page.goto("http://localhost:9001", wait_until="networkidle")
            await page.wait_for_selector("text=MinIO Console", timeout=5000)
            await page.screenshot(path="/tmp/minio-console.png")
            self.results.append(("MinIO Console", True, "UI loaded successfully"))
            print("✅ MinIO Console accessible")
        except Exception as e:
            self.results.append(("MinIO Console", False, str(e)))
            print(f"❌ MinIO Console failed: {e}")
        finally:
            await page.close()
            
        # Test Meilisearch
        try:
            page = await self.context.new_page()
            await page.goto("http://localhost:7700", wait_until="networkidle")
            # Meilisearch has a simple JSON response
            content = await page.content()
            if "status" in content:
                self.results.append(("Meilisearch", True, "API accessible"))
                print("✅ Meilisearch accessible")
            else:
                self.results.append(("Meilisearch", False, "Unexpected response"))
                print("❌ Meilisearch unexpected response")
        except Exception as e:
            self.results.append(("Meilisearch", False, str(e)))
            print(f"❌ Meilisearch failed: {e}")
        finally:
            await page.close()
            
    async def test_api_endpoints(self):
        """Test API endpoints via browser"""
        print("\n🧪 Testing API Endpoints via Browser...")
        
        # Test LLM Router
        try:
            page = await self.context.new_page()
            response = await page.goto("http://localhost:4000/health")
            data = await response.json()
            if data.get("status") == "healthy":
                self.results.append(("LLM Router /health", True, "Healthy"))
                print("✅ LLM Router health check passed")
            else:
                self.results.append(("LLM Router /health", False, "Unhealthy"))
                print("❌ LLM Router unhealthy")
            await page.close()
        except Exception as e:
            self.results.append(("LLM Router /health", False, str(e)))
            print(f"❌ LLM Router failed: {e}")
            
        # Test API Service
        try:
            page = await self.context.new_page()
            response = await page.goto("http://localhost:8000/health")
            data = await response.json()
            if data.get("status") == "healthy":
                self.results.append(("API /health", True, "Healthy"))
                print("✅ API health check passed")
            else:
                self.results.append(("API /health", False, "Unhealthy"))
                print("❌ API unhealthy")
            await page.close()
        except Exception as e:
            self.results.append(("API /health", False, str(e)))
            print(f"❌ API failed: {e}")
            
    async def test_api_interactions(self):
        """Test complex API interactions"""
        print("\n🧪 Testing API Interactions...")
        
        # Create project via API
        try:
            page = await self.context.new_page()
            
            # Make POST request to create project
            response = await page.request.post(
                "http://localhost:8000/api/v1/projects",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": "Bearer test-token"
                },
                data={
                    "name": "Browser Test Project",
                    "description": "Created via headless Chrome"
                }
            )
            
            if response.ok:
                data = await response.json()
                project_id = data.get("id")
                self.results.append(("Create Project", True, f"Created: {project_id}"))
                print(f"✅ Created project: {project_id}")
                
                # Create trace for the project
                trace_response = await page.request.post(
                    "http://localhost:8000/api/v1/traces",
                    headers={
                        "Content-Type": "application/json",
                        "Authorization": "Bearer test-token"
                    },
                    data={
                        "project_id": project_id,
                        "name": "browser-test-trace",
                        "input": {"test": "browser"},
                        "output": {"result": "success"}
                    }
                )
                
                if trace_response.ok:
                    trace_data = await trace_response.json()
                    trace_id = trace_data.get("id")
                    self.results.append(("Create Trace", True, f"Created: {trace_id}"))
                    print(f"✅ Created trace: {trace_id}")
                else:
                    self.results.append(("Create Trace", False, "Failed to create"))
                    print("❌ Failed to create trace")
            else:
                self.results.append(("Create Project", False, "Failed to create"))
                print("❌ Failed to create project")
                
            await page.close()
        except Exception as e:
            self.results.append(("API Interactions", False, str(e)))
            print(f"❌ API interaction failed: {e}")
            
    async def test_llm_chat_completion(self):
        """Test LLM chat completion"""
        print("\n🧪 Testing LLM Chat Completion...")
        
        try:
            page = await self.context.new_page()
            
            response = await page.request.post(
                "http://localhost:4000/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": "Bearer sk-test"
                },
                data={
                    "model": "gpt-3.5-turbo",
                    "messages": [
                        {"role": "user", "content": "What is 2+2?"}
                    ]
                }
            )
            
            if response.ok:
                data = await response.json()
                if "choices" in data and len(data["choices"]) > 0:
                    content = data["choices"][0]["message"]["content"]
                    self.results.append(("LLM Completion", True, f"Response: {content[:50]}..."))
                    print(f"✅ LLM response: {content[:50]}...")
                else:
                    self.results.append(("LLM Completion", False, "No choices in response"))
                    print("❌ LLM response missing choices")
            else:
                self.results.append(("LLM Completion", False, f"HTTP {response.status}"))
                print(f"❌ LLM request failed: HTTP {response.status}")
                
            await page.close()
        except Exception as e:
            self.results.append(("LLM Completion", False, str(e)))
            print(f"❌ LLM completion failed: {e}")
            
    async def test_performance(self):
        """Test performance metrics"""
        print("\n🧪 Testing Performance Metrics...")
        
        try:
            page = await self.context.new_page()
            
            # Measure API response time
            start_time = asyncio.get_event_loop().time()
            await page.goto("http://localhost:8000/health")
            api_time = (asyncio.get_event_loop().time() - start_time) * 1000
            
            self.results.append(("API Response Time", True, f"{api_time:.2f}ms"))
            print(f"✅ API response time: {api_time:.2f}ms")
            
            # Measure LLM response time
            start_time = asyncio.get_event_loop().time()
            await page.goto("http://localhost:4000/health")
            llm_time = (asyncio.get_event_loop().time() - start_time) * 1000
            
            self.results.append(("LLM Response Time", True, f"{llm_time:.2f}ms"))
            print(f"✅ LLM response time: {llm_time:.2f}ms")
            
            await page.close()
        except Exception as e:
            self.results.append(("Performance Test", False, str(e)))
            print(f"❌ Performance test failed: {e}")
            
    async def run_all_tests(self):
        """Run all browser tests"""
        await self.setup()
        
        try:
            await self.test_infrastructure_ui()
            await self.test_api_endpoints()
            await self.test_api_interactions()
            await self.test_llm_chat_completion()
            await self.test_performance()
        finally:
            await self.teardown()
            
        # Print summary
        print("\n" + "="*50)
        print("Browser Test Summary")
        print("="*50)
        
        passed = sum(1 for _, success, _ in self.results if success)
        failed = sum(1 for _, success, _ in self.results if not success)
        
        for test_name, success, message in self.results:
            status = "✅ PASS" if success else "❌ FAIL"
            print(f"{test_name:<30} {status} - {message}")
            
        print("="*50)
        print(f"Total: {len(self.results)} | Passed: {passed} | Failed: {failed}")
        
        return failed == 0

async def main():
    tester = HanzoStackBrowserTest()
    success = await tester.run_all_tests()
    exit(0 if success else 1)

if __name__ == "__main__":
    asyncio.run(main())
EOF

# Run the browser tests
log "Running browser integration tests..."
python /tmp/browser_integration_test.py