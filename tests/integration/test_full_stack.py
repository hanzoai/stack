"""Full stack integration tests for Hanzo AI"""

import pytest
import requests
import time
import json
from typing import Dict, Any

# Service URLs from environment
API_URL = "http://api:8000"
CLOUD_URL = "http://cloud:3000"
CHAT_URL = "http://chat:3081"
LLM_GATEWAY_URL = "http://llm-gateway:4000"
SEARCH_URL = "http://search:3000"
IAM_URL = "http://iam:8000"


class TestFullStackIntegration:
    """Test complete workflows across all services"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup test data"""
        self.test_project_id = "test-project-" + str(int(time.time()))
        self.test_user_id = "test-user-" + str(int(time.time()))
        
    def test_llm_gateway_routing(self):
        """Test LLM Gateway can route to multiple providers"""
        # Test OpenAI-compatible endpoint
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/chat/completions",
            json={
                "model": "gpt-3.5-turbo",
                "messages": [{"role": "user", "content": "Hello"}],
                "mock_response": True  # Use mock in test mode
            },
            headers={"Authorization": "Bearer test-key"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "choices" in data
        
        # Test Anthropic-compatible endpoint
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/messages",
            json={
                "model": "claude-3-sonnet",
                "messages": [{"role": "user", "content": "Hello"}],
                "mock_response": True
            },
            headers={"Authorization": "Bearer test-key"}
        )
        assert response.status_code == 200
        
    def test_chat_with_mcp_tools(self):
        """Test Chat service with MCP tool integration"""
        # Create a chat session
        response = requests.post(
            f"{CHAT_URL}/api/conversations",
            json={
                "title": "Integration Test",
                "model": "gpt-3.5-turbo",
                "project_id": self.test_project_id
            }
        )
        assert response.status_code == 201
        conversation_id = response.json()["id"]
        
        # Send message requesting file operation
        response = requests.post(
            f"{CHAT_URL}/api/conversations/{conversation_id}/messages",
            json={
                "content": "List files in the current directory",
                "tools": ["file_list"]
            }
        )
        assert response.status_code == 200
        message = response.json()
        assert message["tool_calls"] is not None
        
    def test_observability_pipeline(self):
        """Test trace/span creation and observability in Cloud"""
        # Create trace via API
        response = requests.post(
            f"{API_URL}/api/v1/traces",
            json={
                "name": "integration-test-trace",
                "project_id": self.test_project_id,
                "metadata": {"test": True}
            }
        )
        assert response.status_code == 201
        trace_id = response.json()["id"]
        
        # Create observation
        response = requests.post(
            f"{API_URL}/api/v1/observations",
            json={
                "trace_id": trace_id,
                "type": "generation",
                "name": "test-generation",
                "model": "gpt-3.5-turbo",
                "input": {"messages": [{"role": "user", "content": "test"}]},
                "output": {"content": "test response"},
                "usage": {"prompt_tokens": 10, "completion_tokens": 5}
            }
        )
        assert response.status_code == 201
        
        # Verify in Cloud (Langfuse)
        time.sleep(2)  # Allow propagation
        response = requests.get(
            f"{CLOUD_URL}/api/public/traces/{trace_id}",
            headers={"Authorization": "Bearer test-public-key"}
        )
        assert response.status_code == 200
        trace = response.json()
        assert trace["name"] == "integration-test-trace"
        
    def test_search_functionality(self):
        """Test Search service with multiple backends"""
        # Index test document
        response = requests.post(
            f"{SEARCH_URL}/api/index",
            json={
                "id": "test-doc-1",
                "title": "Hanzo AI Integration",
                "content": "This is a test document for Hanzo AI search",
                "project_id": self.test_project_id
            }
        )
        assert response.status_code in [200, 201]
        
        # Search for document
        time.sleep(1)  # Allow indexing
        response = requests.get(
            f"{SEARCH_URL}/api/search",
            params={"q": "Hanzo AI", "project_id": self.test_project_id}
        )
        assert response.status_code == 200
        results = response.json()
        assert len(results["hits"]) > 0
        assert "test-doc-1" in [hit["id"] for hit in results["hits"]]
        
    def test_iam_authentication_flow(self):
        """Test IAM service authentication"""
        # Create test organization
        response = requests.post(
            f"{IAM_URL}/api/add-organization",
            json={
                "name": "Test Org",
                "displayName": "Test Organization"
            }
        )
        assert response.status_code == 200
        org_name = response.json()["name"]
        
        # Create test user
        response = requests.post(
            f"{IAM_URL}/api/add-user",
            json={
                "owner": org_name,
                "name": self.test_user_id,
                "email": f"{self.test_user_id}@test.com",
                "password": "TestPass123!"
            }
        )
        assert response.status_code == 200
        
        # Test login
        response = requests.post(
            f"{IAM_URL}/api/login",
            json={
                "username": self.test_user_id,
                "password": "TestPass123!"
            }
        )
        assert response.status_code == 200
        assert "token" in response.json()
        
    def test_cross_service_workflow(self):
        """Test a complete workflow across multiple services"""
        # 1. Authenticate via IAM
        auth_response = requests.post(
            f"{IAM_URL}/api/login",
            json={"username": "admin", "password": "admin123"}
        )
        token = auth_response.json().get("token", "test-token")
        
        # 2. Create a project via API
        project_response = requests.post(
            f"{API_URL}/api/v1/projects",
            json={"name": "Integration Test Project"},
            headers={"Authorization": f"Bearer {token}"}
        )
        project_id = project_response.json()["id"]
        
        # 3. Start a chat conversation
        chat_response = requests.post(
            f"{CHAT_URL}/api/conversations",
            json={
                "project_id": project_id,
                "model": "gpt-3.5-turbo"
            },
            headers={"Authorization": f"Bearer {token}"}
        )
        conversation_id = chat_response.json()["id"]
        
        # 4. Send a message (creates trace in background)
        message_response = requests.post(
            f"{CHAT_URL}/api/conversations/{conversation_id}/messages",
            json={"content": "What is Hanzo AI?"},
            headers={"Authorization": f"Bearer {token}"}
        )
        
        # 5. Verify trace in Cloud
        time.sleep(3)
        traces_response = requests.get(
            f"{CLOUD_URL}/api/public/traces",
            params={"project_id": project_id},
            headers={"Authorization": "Bearer test-public-key"}
        )
        traces = traces_response.json()["data"]
        assert len(traces) > 0
        
        # 6. Search for the conversation
        search_response = requests.get(
            f"{SEARCH_URL}/api/search",
            params={"q": "Hanzo AI", "project_id": project_id}
        )
        assert search_response.status_code == 200
        
    def test_agent_orchestration(self):
        """Test Agent service multi-agent workflows"""
        # Create agent workflow
        response = requests.post(
            f"{API_URL}/api/v1/agents/workflows",
            json={
                "name": "Test Workflow",
                "agents": [
                    {
                        "id": "researcher",
                        "type": "research",
                        "model": "gpt-3.5-turbo"
                    },
                    {
                        "id": "writer",
                        "type": "writer",
                        "model": "gpt-3.5-turbo"
                    }
                ],
                "connections": [
                    {"from": "researcher", "to": "writer"}
                ]
            }
        )
        assert response.status_code == 201
        workflow_id = response.json()["id"]
        
        # Execute workflow
        response = requests.post(
            f"{API_URL}/api/v1/agents/workflows/{workflow_id}/execute",
            json={"input": "Research and write about AI safety"}
        )
        assert response.status_code == 200
        execution_id = response.json()["execution_id"]
        
        # Check execution status
        max_attempts = 30
        for _ in range(max_attempts):
            response = requests.get(
                f"{API_URL}/api/v1/agents/executions/{execution_id}"
            )
            if response.json()["status"] == "completed":
                break
            time.sleep(1)
        
        assert response.json()["status"] == "completed"
        
    def test_storage_operations(self):
        """Test MinIO storage operations"""
        # Upload file via API
        files = {"file": ("test.txt", b"Hello Hanzo AI", "text/plain")}
        response = requests.post(
            f"{API_URL}/api/v1/storage/upload",
            files=files,
            data={"project_id": self.test_project_id}
        )
        assert response.status_code == 201
        file_id = response.json()["file_id"]
        
        # Get file URL
        response = requests.get(
            f"{API_URL}/api/v1/storage/files/{file_id}/url"
        )
        assert response.status_code == 200
        assert "url" in response.json()
        
    def test_rate_limiting(self):
        """Test rate limiting across services"""
        # Make multiple requests rapidly
        responses = []
        for _ in range(150):
            response = requests.get(f"{API_URL}/api/v1/health")
            responses.append(response.status_code)
            
        # Should hit rate limit at some point
        assert 429 in responses
        
    def test_service_health_endpoints(self):
        """Test all service health endpoints"""
        services = [
            (API_URL, "/health"),
            (CLOUD_URL, "/api/health"),
            (CHAT_URL, "/api/health"),
            (LLM_GATEWAY_URL, "/health"),
            (SEARCH_URL, "/api/health"),
            (IAM_URL, "/api/health")
        ]
        
        for base_url, health_path in services:
            response = requests.get(f"{base_url}{health_path}")
            assert response.status_code == 200
            data = response.json()
            assert data.get("status") in ["healthy", "ok", True]