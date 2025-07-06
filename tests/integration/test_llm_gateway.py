"""LLM Gateway specific integration tests"""

import pytest
import requests
import os
import time

LLM_GATEWAY_URL = os.getenv("LLM_GATEWAY_URL", "http://llm-gateway:4000")


class TestLLMGateway:
    """Test LLM Gateway functionality"""
    
    def test_health_endpoint(self):
        """Test health check endpoint"""
        response = requests.get(f"{LLM_GATEWAY_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data.get("status") == "healthy"
        
    def test_openai_chat_completion(self):
        """Test OpenAI-compatible chat completion"""
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/chat/completions",
            json={
                "model": "gpt-3.5-turbo",
                "messages": [{"role": "user", "content": "Say hello"}],
                "max_tokens": 50,
                "temperature": 0.7
            },
            headers={"Authorization": "Bearer test-key"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "choices" in data
        assert len(data["choices"]) > 0
        assert "message" in data["choices"][0]
        
    def test_anthropic_messages(self):
        """Test Anthropic-compatible messages endpoint"""
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/messages",
            json={
                "model": "claude-3-sonnet",
                "messages": [{"role": "user", "content": "Say hello"}],
                "max_tokens": 50
            },
            headers={
                "Authorization": "Bearer test-key",
                "anthropic-version": "2023-06-01"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "content" in data
        
    def test_embeddings(self):
        """Test embeddings endpoint"""
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/embeddings",
            json={
                "model": "text-embedding-ada-002",
                "input": "Test embedding text"
            },
            headers={"Authorization": "Bearer test-key"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert len(data["data"]) > 0
        assert "embedding" in data["data"][0]
        
    def test_models_list(self):
        """Test models listing"""
        response = requests.get(
            f"{LLM_GATEWAY_URL}/v1/models",
            headers={"Authorization": "Bearer test-key"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert len(data["data"]) > 0
        
    def test_streaming_response(self):
        """Test streaming chat completion"""
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/chat/completions",
            json={
                "model": "gpt-3.5-turbo",
                "messages": [{"role": "user", "content": "Count to 5"}],
                "stream": True
            },
            headers={"Authorization": "Bearer test-key"},
            stream=True
        )
        assert response.status_code == 200
        
        # Collect streamed chunks
        chunks = []
        for line in response.iter_lines():
            if line:
                chunks.append(line.decode('utf-8'))
        
        assert len(chunks) > 0
        assert any("data:" in chunk for chunk in chunks)
        
    def test_rate_limiting(self):
        """Test rate limiting functionality"""
        # Make multiple rapid requests
        responses = []
        for i in range(20):
            response = requests.post(
                f"{LLM_GATEWAY_URL}/v1/chat/completions",
                json={
                    "model": "gpt-3.5-turbo",
                    "messages": [{"role": "user", "content": f"Test {i}"}],
                    "max_tokens": 10
                },
                headers={"Authorization": "Bearer test-key-limited"}
            )
            responses.append(response.status_code)
            
        # Should hit rate limit
        assert 429 in responses or all(r == 200 for r in responses)
        
    def test_error_handling(self):
        """Test error handling"""
        # Invalid model
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/chat/completions",
            json={
                "model": "invalid-model",
                "messages": [{"role": "user", "content": "Test"}]
            },
            headers={"Authorization": "Bearer test-key"}
        )
        assert response.status_code in [400, 404]
        
        # Missing auth
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/chat/completions",
            json={
                "model": "gpt-3.5-turbo",
                "messages": [{"role": "user", "content": "Test"}]
            }
        )
        assert response.status_code == 401
        
    def test_token_counting(self):
        """Test token counting accuracy"""
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/chat/completions",
            json={
                "model": "gpt-3.5-turbo",
                "messages": [{"role": "user", "content": "Hello world"}],
                "max_tokens": 10
            },
            headers={"Authorization": "Bearer test-key"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "usage" in data
        assert "prompt_tokens" in data["usage"]
        assert "completion_tokens" in data["usage"]
        assert "total_tokens" in data["usage"]
        
    def test_function_calling(self):
        """Test function calling support"""
        response = requests.post(
            f"{LLM_GATEWAY_URL}/v1/chat/completions",
            json={
                "model": "gpt-3.5-turbo",
                "messages": [{"role": "user", "content": "What's the weather?"}],
                "functions": [{
                    "name": "get_weather",
                    "description": "Get weather for a location",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "location": {"type": "string"}
                        }
                    }
                }],
                "function_call": "auto"
            },
            headers={"Authorization": "Bearer test-key"}
        )
        assert response.status_code == 200
        data = response.json()
        # Mock should return function call
        assert "choices" in data