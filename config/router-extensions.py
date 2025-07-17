"""
Router extensions for Hanzo Stack integration
Handles Cloud API key validation and project-based access control
"""

import os
import httpx
from typing import Optional, Dict, Any
from router.proxy._types import UserAPIKeyAuth
from router.integrations.custom_auth import CustomAuth

class HanzoCloudAuth(CustomAuth):
    """
    Custom authentication handler that validates API keys against Hanzo Cloud
    and enforces project-based access control
    """
    
    def __init__(self):
        self.cloud_api_url = os.getenv("CLOUD_API_URL", "http://cloud-web:3001")
        self.cloud_api_key = os.getenv("CLOUD_API_KEY", "sk-cloud-admin")
        self.iam_url = os.getenv("IAM_URL", "http://iam:3000")
        self.client = httpx.AsyncClient()
    
    async def async_pre_call_hook(
        self,
        user_api_key_dict: UserAPIKeyAuth,
        cache: Any,
        data: Dict[str, Any],
        call_type: str,
    ) -> Optional[Dict[str, Any]]:
        """
        Pre-call hook to validate API keys and inject metadata
        """
        api_key = user_api_key_dict.api_key
        
        # Skip validation for master key
        if api_key == os.getenv("MASTER_KEY"):
            return data
        
        try:
            # Validate API key with Cloud
            response = await self.client.post(
                f"{self.cloud_api_url}/api/public/validate",
                headers={"Authorization": f"Bearer {api_key}"},
                json={"scope": call_type}
            )
            
            if response.status_code != 200:
                raise Exception("Invalid API key")
            
            key_data = response.json()
            
            # Inject metadata for Langfuse tracking
            if "metadata" not in data:
                data["metadata"] = {}
            
            data["metadata"].update({
                "project_id": key_data.get("projectId"),
                "organization_id": key_data.get("organizationId"),
                "user_id": key_data.get("userId"),
                "key_id": key_data.get("keyId"),
            })
            
            # Update Langfuse tracking
            if "langfuseMetadata" not in data:
                data["langfuseMetadata"] = {}
            
            data["langfuseMetadata"].update({
                "sessionId": key_data.get("projectId"),
                "userId": key_data.get("userId"),
                "tags": [f"org:{key_data.get('organizationId')}", f"project:{key_data.get('projectId')}"]
            })
            
        except Exception as e:
            print(f"API key validation failed: {e}")
            # Allow fallback to default validation
            pass
        
        return data
    
    async def async_post_call_success_hook(
        self,
        user_api_key_dict: UserAPIKeyAuth,
        response: Any,
    ) -> Optional[Any]:
        """
        Post-call hook to track usage in Cloud
        """
        try:
            # Report usage back to Cloud
            usage_data = {
                "model": response.get("model"),
                "usage": response.get("usage", {}),
                "keyId": user_api_key_dict.token,
            }
            
            await self.client.post(
                f"{self.cloud_api_url}/api/public/usage",
                headers={"Authorization": f"Bearer {self.cloud_api_key}"},
                json=usage_data
            )
        except Exception as e:
            print(f"Usage tracking failed: {e}")
        
        return response


# Register the custom auth handler
custom_auth = HanzoCloudAuth()