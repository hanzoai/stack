"""API service specific integration tests"""

import pytest
import requests
import os
import uuid
from datetime import datetime

API_URL = os.getenv("API_URL", "http://api:8000")


class TestAPIService:
    """Test API service functionality"""
    
    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup test data"""
        self.test_project_id = f"test-project-{uuid.uuid4()}"
        self.headers = {"Authorization": "Bearer test-token"}
    
    def test_health_endpoint(self):
        """Test health check endpoint"""
        response = requests.get(f"{API_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data.get("status") == "healthy"
        assert "version" in data
        assert "database" in data
        assert "redis" in data
        
    def test_project_crud(self):
        """Test project CRUD operations"""
        # Create project
        response = requests.post(
            f"{API_URL}/api/v1/projects",
            json={
                "id": self.test_project_id,
                "name": "Test Project",
                "description": "Integration test project"
            },
            headers=self.headers
        )
        assert response.status_code == 201
        project = response.json()
        assert project["id"] == self.test_project_id
        assert project["name"] == "Test Project"
        
        # Get project
        response = requests.get(
            f"{API_URL}/api/v1/projects/{self.test_project_id}",
            headers=self.headers
        )
        assert response.status_code == 200
        assert response.json()["id"] == self.test_project_id
        
        # Update project
        response = requests.patch(
            f"{API_URL}/api/v1/projects/{self.test_project_id}",
            json={"description": "Updated description"},
            headers=self.headers
        )
        assert response.status_code == 200
        assert response.json()["description"] == "Updated description"
        
        # List projects
        response = requests.get(
            f"{API_URL}/api/v1/projects",
            headers=self.headers
        )
        assert response.status_code == 200
        projects = response.json()["data"]
        assert any(p["id"] == self.test_project_id for p in projects)
        
        # Delete project
        response = requests.delete(
            f"{API_URL}/api/v1/projects/{self.test_project_id}",
            headers=self.headers
        )
        assert response.status_code == 204
        
    def test_trace_creation(self):
        """Test trace creation and retrieval"""
        # Create trace
        trace_data = {
            "project_id": self.test_project_id,
            "name": "test-trace",
            "input": {"query": "test"},
            "output": {"response": "test response"},
            "metadata": {"test": True},
            "timestamp": datetime.utcnow().isoformat()
        }
        
        response = requests.post(
            f"{API_URL}/api/v1/traces",
            json=trace_data,
            headers=self.headers
        )
        assert response.status_code == 201
        trace = response.json()
        trace_id = trace["id"]
        
        # Get trace
        response = requests.get(
            f"{API_URL}/api/v1/traces/{trace_id}",
            headers=self.headers
        )
        assert response.status_code == 200
        retrieved_trace = response.json()
        assert retrieved_trace["name"] == "test-trace"
        assert retrieved_trace["metadata"]["test"] is True
        
    def test_observation_creation(self):
        """Test observation creation"""
        # First create a trace
        trace_response = requests.post(
            f"{API_URL}/api/v1/traces",
            json={
                "project_id": self.test_project_id,
                "name": "observation-test-trace"
            },
            headers=self.headers
        )
        trace_id = trace_response.json()["id"]
        
        # Create observation
        observation_data = {
            "trace_id": trace_id,
            "type": "generation",
            "name": "test-generation",
            "model": "gpt-3.5-turbo",
            "input": {"messages": [{"role": "user", "content": "Hello"}]},
            "output": {"content": "Hello! How can I help you?"},
            "usage": {
                "prompt_tokens": 10,
                "completion_tokens": 8,
                "total_tokens": 18
            },
            "start_time": datetime.utcnow().isoformat(),
            "end_time": datetime.utcnow().isoformat()
        }
        
        response = requests.post(
            f"{API_URL}/api/v1/observations",
            json=observation_data,
            headers=self.headers
        )
        assert response.status_code == 201
        observation = response.json()
        assert observation["type"] == "generation"
        assert observation["model"] == "gpt-3.5-turbo"
        
    def test_score_creation(self):
        """Test score creation"""
        # Create trace
        trace_response = requests.post(
            f"{API_URL}/api/v1/traces",
            json={
                "project_id": self.test_project_id,
                "name": "score-test-trace"
            },
            headers=self.headers
        )
        trace_id = trace_response.json()["id"]
        
        # Create score
        score_data = {
            "trace_id": trace_id,
            "name": "quality",
            "value": 0.85,
            "data_type": "NUMERIC",
            "comment": "Good quality response"
        }
        
        response = requests.post(
            f"{API_URL}/api/v1/scores",
            json=score_data,
            headers=self.headers
        )
        assert response.status_code == 201
        score = response.json()
        assert score["name"] == "quality"
        assert score["value"] == 0.85
        
    def test_storage_operations(self):
        """Test file storage operations"""
        # Upload file
        files = {"file": ("test.txt", b"Test file content", "text/plain")}
        data = {"project_id": self.test_project_id}
        
        response = requests.post(
            f"{API_URL}/api/v1/storage/upload",
            files=files,
            data=data,
            headers=self.headers
        )
        assert response.status_code == 201
        upload_result = response.json()
        file_id = upload_result["file_id"]
        
        # Get file URL
        response = requests.get(
            f"{API_URL}/api/v1/storage/files/{file_id}/url",
            headers=self.headers
        )
        assert response.status_code == 200
        assert "url" in response.json()
        
        # List files
        response = requests.get(
            f"{API_URL}/api/v1/storage/files",
            params={"project_id": self.test_project_id},
            headers=self.headers
        )
        assert response.status_code == 200
        files = response.json()["data"]
        assert any(f["id"] == file_id for f in files)
        
    def test_pagination(self):
        """Test pagination functionality"""
        # Create multiple traces
        for i in range(25):
            requests.post(
                f"{API_URL}/api/v1/traces",
                json={
                    "project_id": self.test_project_id,
                    "name": f"pagination-test-{i}"
                },
                headers=self.headers
            )
        
        # Test pagination
        response = requests.get(
            f"{API_URL}/api/v1/traces",
            params={
                "project_id": self.test_project_id,
                "page": 1,
                "limit": 10
            },
            headers=self.headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 10
        assert data["total"] >= 25
        assert data["page"] == 1
        assert data["pages"] >= 3
        
    def test_filtering(self):
        """Test filtering functionality"""
        # Create traces with different metadata
        requests.post(
            f"{API_URL}/api/v1/traces",
            json={
                "project_id": self.test_project_id,
                "name": "filter-test",
                "metadata": {"environment": "production"}
            },
            headers=self.headers
        )
        
        requests.post(
            f"{API_URL}/api/v1/traces",
            json={
                "project_id": self.test_project_id,
                "name": "filter-test",
                "metadata": {"environment": "development"}
            },
            headers=self.headers
        )
        
        # Filter by metadata
        response = requests.get(
            f"{API_URL}/api/v1/traces",
            params={
                "project_id": self.test_project_id,
                "metadata.environment": "production"
            },
            headers=self.headers
        )
        assert response.status_code == 200
        traces = response.json()["data"]
        assert all(t["metadata"]["environment"] == "production" for t in traces)
        
    def test_error_handling(self):
        """Test API error handling"""
        # 404 - Not found
        response = requests.get(
            f"{API_URL}/api/v1/projects/non-existent-id",
            headers=self.headers
        )
        assert response.status_code == 404
        
        # 400 - Bad request
        response = requests.post(
            f"{API_URL}/api/v1/traces",
            json={"invalid": "data"},
            headers=self.headers
        )
        assert response.status_code == 400
        
        # 401 - Unauthorized
        response = requests.get(f"{API_URL}/api/v1/projects")
        assert response.status_code == 401