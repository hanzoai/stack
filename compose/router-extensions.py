"""
Hanzo Router Extensions
Adds unified API routing capabilities to LiteLLM proxy
"""
from fastapi import FastAPI, Request, Response
from fastapi.responses import StreamingResponse
import httpx
import os
from typing import Optional

async def setup_proxy_routes(app: FastAPI):
    """Add proxy routes to other Hanzo services"""
    
    # Get service URLs from environment
    RUNTIME_URL = os.getenv("RUNTIME_URL", "http://runtime:3000")
    SERVICES_URL = os.getenv("SERVICES_URL", "http://services:3000")
    CHAT_URL = os.getenv("CHAT_URL", "http://chat:3081")
    
    # Create HTTP client
    client = httpx.AsyncClient(timeout=30.0)
    
    async def proxy_request(request: Request, target_url: str, strip_prefix: Optional[str] = None):
        """Generic proxy handler"""
        # Build target path
        path = request.url.path
        if strip_prefix and path.startswith(strip_prefix):
            path = path[len(strip_prefix):]
        
        # Build full URL
        url = f"{target_url}{path}"
        if request.url.query:
            url += f"?{request.url.query}"
        
        # Forward the request
        headers = dict(request.headers)
        headers.pop("host", None)
        
        # Read body for non-streaming requests
        body = await request.body()
        
        # Make the request
        response = await client.request(
            method=request.method,
            url=url,
            headers=headers,
            content=body,
            follow_redirects=True
        )
        
        # Return response
        return Response(
            content=response.content,
            status_code=response.status_code,
            headers=dict(response.headers)
        )
    
    # Runtime routes
    @app.api_route("/runtime/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD", "PATCH"])
    async def proxy_runtime(request: Request, path: str):
        return await proxy_request(request, RUNTIME_URL, "/runtime")
    
    # Services routes
    @app.api_route("/services/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD", "PATCH"])
    async def proxy_services(request: Request, path: str):
        return await proxy_request(request, SERVICES_URL, "/services")
    
    # Chat routes
    @app.api_route("/chat/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD", "PATCH"])
    async def proxy_chat(request: Request, path: str):
        return await proxy_request(request, CHAT_URL, "/chat")
    
    # Unified execute endpoint (direct to runtime)
    @app.post("/execute")
    async def unified_execute(request: Request):
        """Execute code through unified API"""
        return await proxy_request(request, f"{RUNTIME_URL}/api/execute")
    
    # Unified health check
    @app.get("/health/unified")
    async def unified_health():
        """Check health of all services"""
        health = {"status": "ok", "services": {}}
        
        # Check each service
        services = [
            ("runtime", f"{RUNTIME_URL}/api/health"),
            ("services", f"{SERVICES_URL}/health"),
            ("chat", f"{CHAT_URL}/health")
        ]
        
        for name, url in services:
            try:
                response = await client.get(url, timeout=5.0)
                health["services"][name] = {
                    "status": "ok" if response.status_code == 200 else "error",
                    "code": response.status_code
                }
            except Exception as e:
                health["services"][name] = {
                    "status": "error",
                    "error": str(e)
                }
        
        # Overall status
        if all(s.get("status") == "ok" for s in health["services"].values()):
            health["status"] = "ok"
        else:
            health["status"] = "degraded"
        
        return health

# This will be called by LiteLLM when the app starts
async def initialize_extensions(app: FastAPI):
    await setup_proxy_routes(app)
    print("✅ Hanzo Router Extensions loaded")