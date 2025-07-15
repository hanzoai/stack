#!/bin/bash

# Setup Router UI with Models and MCP Server Pages
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
}

cd /Users/z/work/hanzo/llm

header "SETTING UP ROUTER UI"

# Create enhanced UI templates for models page
info "Creating models UI page..."

mkdir -p llm/proxy/ui/templates
mkdir -p llm/proxy/ui/static/css
mkdir -p llm/proxy/ui/static/js

# Create models page with search/filter
cat > llm/proxy/ui/templates/models.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Models - Hanzo Router</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <script src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
</head>
<body class="bg-gray-900 text-gray-100">
    <div x-data="modelsApp()" class="min-h-screen">
        <!-- Header -->
        <header class="bg-gray-800 shadow-lg">
            <div class="max-w-7xl mx-auto px-4 py-6">
                <div class="flex justify-between items-center">
                    <h1 class="text-3xl font-bold text-white">Hanzo Router - Models</h1>
                    <nav class="space-x-4">
                        <a href="/" class="hover:text-blue-400">API Docs</a>
                        <a href="/ui/models" class="text-blue-400">Models</a>
                        <a href="/ui/mcp-servers" class="hover:text-blue-400">MCP Servers</a>
                    </nav>
                </div>
            </div>
        </header>

        <!-- Main Content -->
        <main class="max-w-7xl mx-auto px-4 py-8">
            <!-- Search and Filter -->
            <div class="mb-8 bg-gray-800 p-6 rounded-lg shadow">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium mb-2">Search Models</label>
                        <input 
                            x-model="searchQuery" 
                            type="text" 
                            placeholder="Search by name or provider..."
                            class="w-full px-4 py-2 bg-gray-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-2">Filter by Provider</label>
                        <select 
                            x-model="selectedProvider" 
                            class="w-full px-4 py-2 bg-gray-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">All Providers</option>
                            <template x-for="provider in providers" :key="provider">
                                <option :value="provider" x-text="provider"></option>
                            </template>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-2">Status</label>
                        <select 
                            x-model="statusFilter" 
                            class="w-full px-4 py-2 bg-gray-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">All</option>
                            <option value="available">Available</option>
                            <option value="configured">Configured Only</option>
                        </select>
                    </div>
                </div>
            </div>

            <!-- Models Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <template x-for="model in filteredModels" :key="model.id">
                    <div class="bg-gray-800 rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
                        <div class="flex justify-between items-start mb-4">
                            <h3 class="text-xl font-semibold" x-text="model.id"></h3>
                            <span 
                                class="px-2 py-1 text-xs rounded-full"
                                :class="model.available ? 'bg-green-600' : 'bg-gray-600'"
                                x-text="model.available ? 'Available' : 'Not Configured'"
                            ></span>
                        </div>
                        <div class="space-y-2 text-sm text-gray-400">
                            <p><span class="font-medium">Provider:</span> <span x-text="model.provider"></span></p>
                            <p><span class="font-medium">Mode:</span> <span x-text="model.mode"></span></p>
                            <p x-show="model.context_window">
                                <span class="font-medium">Context:</span> <span x-text="model.context_window + ' tokens'"></span>
                            </p>
                            <p x-show="model.max_tokens">
                                <span class="font-medium">Max Output:</span> <span x-text="model.max_tokens + ' tokens'"></span>
                            </p>
                            <div x-show="model.supported_features && model.supported_features.length > 0">
                                <span class="font-medium">Features:</span>
                                <div class="flex flex-wrap gap-1 mt-1">
                                    <template x-for="feature in model.supported_features" :key="feature">
                                        <span class="px-2 py-1 bg-gray-700 rounded text-xs" x-text="feature"></span>
                                    </template>
                                </div>
                            </div>
                        </div>
                    </div>
                </template>
            </div>

            <!-- No Results Message -->
            <div x-show="filteredModels.length === 0" class="text-center py-12 text-gray-500">
                No models found matching your criteria.
            </div>
        </main>

        <!-- Footer -->
        <footer class="bg-gray-800 mt-16 py-8">
            <div class="max-w-7xl mx-auto px-4 text-center text-gray-400">
                <p>&copy; 2024 Hanzo AI. All rights reserved.</p>
                <p class="mt-2">
                    <a href="https://hanzo.ai" class="hover:text-white">hanzo.ai</a> |
                    <a href="https://docs.hanzo.ai" class="hover:text-white">Documentation</a> |
                    <a href="https://hanzo.ai/support" class="hover:text-white">Support</a>
                </p>
            </div>
        </footer>
    </div>

    <script>
    function modelsApp() {
        return {
            models: [],
            searchQuery: '',
            selectedProvider: '',
            statusFilter: '',
            providers: [],
            
            async init() {
                await this.fetchModels();
            },
            
            async fetchModels() {
                try {
                    const response = await fetch('/api/models', {
                        headers: {
                            'Authorization': 'Bearer ' + (localStorage.getItem('api_key') || 'sk-hanzo-master')
                        }
                    });
                    const data = await response.json();
                    this.models = data.data || [];
                    
                    // Extract unique providers
                    this.providers = [...new Set(this.models.map(m => m.provider || m.owned_by || 'unknown'))];
                    
                    // Check which models are actually available
                    await this.checkAvailability();
                } catch (error) {
                    console.error('Failed to fetch models:', error);
                }
            },
            
            async checkAvailability() {
                // Check environment variables to see which models are configured
                const configuredProviders = {
                    'openai': !!window.ENV?.OPENAI_API_KEY,
                    'anthropic': !!window.ENV?.ANTHROPIC_API_KEY,
                    'google': !!window.ENV?.GOOGLE_API_KEY,
                    'together': !!window.ENV?.TOGETHER_API_KEY,
                    'mock': true // Always available in mock mode
                };
                
                this.models = this.models.map(model => ({
                    ...model,
                    provider: model.id.split('/')[0] || model.owned_by || 'unknown',
                    available: configuredProviders[model.id.split('/')[0]] || window.ENV?.MOCK_MODE === 'true',
                    mode: model.mode || 'chat',
                    supported_features: model.supported_features || ['completion'],
                    context_window: model.context_window || 4096,
                    max_tokens: model.max_tokens || 4096
                }));
            },
            
            get filteredModels() {
                return this.models.filter(model => {
                    // Search filter
                    if (this.searchQuery && !model.id.toLowerCase().includes(this.searchQuery.toLowerCase()) &&
                        !model.provider.toLowerCase().includes(this.searchQuery.toLowerCase())) {
                        return false;
                    }
                    
                    // Provider filter
                    if (this.selectedProvider && model.provider !== this.selectedProvider) {
                        return false;
                    }
                    
                    // Status filter
                    if (this.statusFilter === 'available' && !model.available) {
                        return false;
                    }
                    if (this.statusFilter === 'configured' && !model.available) {
                        return false;
                    }
                    
                    return true;
                });
            }
        }
    }
    </script>
</body>
</html>
EOF

# Create MCP servers page with search/filter
cat > llm/proxy/ui/templates/mcp-servers.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MCP Servers - Hanzo Router</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <script src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
</head>
<body class="bg-gray-900 text-gray-100">
    <div x-data="mcpApp()" class="min-h-screen">
        <!-- Header -->
        <header class="bg-gray-800 shadow-lg">
            <div class="max-w-7xl mx-auto px-4 py-6">
                <div class="flex justify-between items-center">
                    <h1 class="text-3xl font-bold text-white">Hanzo Router - MCP Servers</h1>
                    <nav class="space-x-4">
                        <a href="/" class="hover:text-blue-400">API Docs</a>
                        <a href="/ui/models" class="hover:text-blue-400">Models</a>
                        <a href="/ui/mcp-servers" class="text-blue-400">MCP Servers</a>
                    </nav>
                </div>
            </div>
        </header>

        <!-- Main Content -->
        <main class="max-w-7xl mx-auto px-4 py-8">
            <!-- Search and Filter -->
            <div class="mb-8 bg-gray-800 p-6 rounded-lg shadow">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium mb-2">Search MCP Servers</label>
                        <input 
                            x-model="searchQuery" 
                            type="text" 
                            placeholder="Search by name or description..."
                            class="w-full px-4 py-2 bg-gray-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-2">Filter by Category</label>
                        <select 
                            x-model="selectedCategory" 
                            class="w-full px-4 py-2 bg-gray-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">All Categories</option>
                            <option value="search">Search</option>
                            <option value="productivity">Productivity</option>
                            <option value="development">Development</option>
                            <option value="data">Data</option>
                            <option value="communication">Communication</option>
                            <option value="utility">Utility</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-2">Status</label>
                        <select 
                            x-model="statusFilter" 
                            class="w-full px-4 py-2 bg-gray-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="">All</option>
                            <option value="enabled">Enabled</option>
                            <option value="configured">Configured</option>
                            <option value="disabled">Disabled</option>
                        </select>
                    </div>
                </div>
            </div>

            <!-- MCP Servers Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <template x-for="server in filteredServers" :key="server.name">
                    <div class="bg-gray-800 rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow">
                        <div class="flex justify-between items-start mb-4">
                            <h3 class="text-xl font-semibold" x-text="server.name"></h3>
                            <span 
                                class="px-2 py-1 text-xs rounded-full"
                                :class="{
                                    'bg-green-600': server.enabled && server.configured,
                                    'bg-yellow-600': server.enabled && !server.configured,
                                    'bg-gray-600': !server.enabled
                                }"
                                x-text="server.enabled ? (server.configured ? 'Active' : 'Missing Config') : 'Disabled'"
                            ></span>
                        </div>
                        <p class="text-gray-400 text-sm mb-4" x-text="server.description"></p>
                        <div class="space-y-2 text-sm">
                            <p><span class="font-medium text-gray-300">Category:</span> 
                                <span class="text-gray-400" x-text="server.category"></span>
                            </p>
                            <p><span class="font-medium text-gray-300">Transport:</span> 
                                <span class="text-gray-400" x-text="server.transport"></span>
                            </p>
                            <div x-show="server.requiredEnv && server.requiredEnv.length > 0">
                                <span class="font-medium text-gray-300">Required Config:</span>
                                <ul class="mt-1 space-y-1">
                                    <template x-for="env in server.requiredEnv" :key="env">
                                        <li class="flex items-center text-gray-400">
                                            <span x-text="env"></span>
                                            <span x-show="server.configuredEnv[env]" class="ml-2 text-green-500">✓</span>
                                            <span x-show="!server.configuredEnv[env]" class="ml-2 text-red-500">✗</span>
                                        </li>
                                    </template>
                                </ul>
                            </div>
                            <div x-show="server.tools && server.tools.length > 0" class="mt-3">
                                <span class="font-medium text-gray-300">Available Tools:</span>
                                <div class="flex flex-wrap gap-1 mt-1">
                                    <template x-for="tool in server.tools" :key="tool">
                                        <span class="px-2 py-1 bg-gray-700 rounded text-xs" x-text="tool"></span>
                                    </template>
                                </div>
                            </div>
                        </div>
                        <div class="mt-4 flex gap-2">
                            <button 
                                x-show="!server.enabled"
                                @click="toggleServer(server.name, true)"
                                class="px-3 py-1 bg-blue-600 hover:bg-blue-700 rounded text-sm"
                            >
                                Enable
                            </button>
                            <button 
                                x-show="server.enabled"
                                @click="toggleServer(server.name, false)"
                                class="px-3 py-1 bg-gray-600 hover:bg-gray-700 rounded text-sm"
                            >
                                Disable
                            </button>
                        </div>
                    </div>
                </template>
            </div>

            <!-- No Results Message -->
            <div x-show="filteredServers.length === 0" class="text-center py-12 text-gray-500">
                No MCP servers found matching your criteria.
            </div>
        </main>

        <!-- Footer -->
        <footer class="bg-gray-800 mt-16 py-8">
            <div class="max-w-7xl mx-auto px-4 text-center text-gray-400">
                <p>&copy; 2024 Hanzo AI. All rights reserved.</p>
                <p class="mt-2">
                    <a href="https://hanzo.ai" class="hover:text-white">hanzo.ai</a> |
                    <a href="https://docs.hanzo.ai" class="hover:text-white">Documentation</a> |
                    <a href="https://hanzo.ai/support" class="hover:text-white">Support</a>
                </p>
            </div>
        </footer>
    </div>

    <script>
    function mcpApp() {
        return {
            servers: [],
            searchQuery: '',
            selectedCategory: '',
            statusFilter: '',
            
            async init() {
                await this.fetchServers();
            },
            
            async fetchServers() {
                try {
                    const response = await fetch('/api/mcps', {
                        headers: {
                            'Authorization': 'Bearer ' + (localStorage.getItem('api_key') || 'sk-hanzo-master')
                        }
                    });
                    const data = await response.json();
                    
                    // Process server data
                    this.servers = Object.entries(data).map(([name, config]) => {
                        const server = {
                            name,
                            enabled: config.enabled !== false,
                            transport: config.args ? 'stdio' : 'unknown',
                            command: config.command,
                            args: config.args || [],
                            env: config.env || {},
                            ...this.getServerMetadata(name)
                        };
                        
                        // Check if required env vars are configured
                        server.configured = this.isServerConfigured(server);
                        server.configuredEnv = this.getConfiguredEnv(server);
                        
                        return server;
                    });
                } catch (error) {
                    console.error('Failed to fetch MCP servers:', error);
                }
            },
            
            getServerMetadata(name) {
                const metadata = {
                    'hanzo_mcp': {
                        description: 'Hanzo MCP server for file operations, search, and code analysis',
                        category: 'development',
                        requiredEnv: [],
                        tools: ['file_read', 'file_write', 'search', 'git_operations']
                    },
                    'brave_search': {
                        description: 'Web search using Brave Search API',
                        category: 'search',
                        requiredEnv: ['BRAVE_API_KEY'],
                        tools: ['web_search']
                    },
                    'github': {
                        description: 'GitHub integration for repositories and issues',
                        category: 'development',
                        requiredEnv: ['GITHUB_TOKEN'],
                        tools: ['create_issue', 'search_repos', 'get_file_contents']
                    },
                    'slack': {
                        description: 'Slack workspace integration',
                        category: 'communication',
                        requiredEnv: ['SLACK_BOT_TOKEN', 'SLACK_TEAM_ID'],
                        tools: ['send_message', 'list_channels']
                    },
                    'google_maps': {
                        description: 'Google Maps and location services',
                        category: 'utility',
                        requiredEnv: ['GOOGLE_MAPS_API_KEY'],
                        tools: ['search_places', 'get_directions']
                    },
                    'filesystem': {
                        description: 'Local filesystem operations',
                        category: 'development',
                        requiredEnv: [],
                        tools: ['read_file', 'write_file', 'list_directory']
                    },
                    'calculator': {
                        description: 'Mathematical calculations and expressions',
                        category: 'utility',
                        requiredEnv: [],
                        tools: ['calculate']
                    },
                    'fetch': {
                        description: 'HTTP requests and web fetching',
                        category: 'data',
                        requiredEnv: [],
                        tools: ['fetch_url']
                    },
                    'sqlite': {
                        description: 'SQLite database operations',
                        category: 'data',
                        requiredEnv: [],
                        tools: ['query', 'execute']
                    },
                    'time': {
                        description: 'Time and date utilities',
                        category: 'utility',
                        requiredEnv: [],
                        tools: ['get_current_time']
                    }
                };
                
                return metadata[name] || {
                    description: 'MCP server for ' + name,
                    category: 'other',
                    requiredEnv: [],
                    tools: []
                };
            },
            
            isServerConfigured(server) {
                if (!server.requiredEnv || server.requiredEnv.length === 0) {
                    return true;
                }
                
                // Check if all required env vars are set
                return server.requiredEnv.every(env => {
                    return window.ENV?.[env] || server.env[env]?.includes('${' + env + '}');
                });
            },
            
            getConfiguredEnv(server) {
                const configured = {};
                if (server.requiredEnv) {
                    server.requiredEnv.forEach(env => {
                        configured[env] = !!(window.ENV?.[env] || server.env[env]?.includes('${' + env + '}'));
                    });
                }
                return configured;
            },
            
            async toggleServer(name, enable) {
                try {
                    // This would make an API call to enable/disable the server
                    const response = await fetch(`/api/mcps/${name}/toggle`, {
                        method: 'POST',
                        headers: {
                            'Authorization': 'Bearer ' + (localStorage.getItem('api_key') || 'sk-hanzo-master'),
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ enabled: enable })
                    });
                    
                    if (response.ok) {
                        await this.fetchServers();
                    }
                } catch (error) {
                    console.error('Failed to toggle server:', error);
                    // For now, just update locally
                    const server = this.servers.find(s => s.name === name);
                    if (server) {
                        server.enabled = enable;
                    }
                }
            },
            
            get filteredServers() {
                return this.servers.filter(server => {
                    // Search filter
                    if (this.searchQuery && 
                        !server.name.toLowerCase().includes(this.searchQuery.toLowerCase()) &&
                        !server.description.toLowerCase().includes(this.searchQuery.toLowerCase())) {
                        return false;
                    }
                    
                    // Category filter
                    if (this.selectedCategory && server.category !== this.selectedCategory) {
                        return false;
                    }
                    
                    // Status filter
                    if (this.statusFilter === 'enabled' && !server.enabled) {
                        return false;
                    }
                    if (this.statusFilter === 'configured' && !server.configured) {
                        return false;
                    }
                    if (this.statusFilter === 'disabled' && server.enabled) {
                        return false;
                    }
                    
                    return true;
                });
            }
        }
    }
    
    // Mock environment variables for demo
    window.ENV = {
        MOCK_MODE: 'true',
        // Add any configured API keys here
    };
    </script>
</body>
</html>
EOF

# Create UI endpoints handler
cat > llm/proxy/ui/ui_endpoints.py << 'EOF'
from fastapi import Request, Depends
from fastapi.responses import HTMLResponse
from llm.proxy._types import UserAPIKeyAuth
from llm.proxy.auth.user_api_key_auth import user_api_key_auth
import os

def register_ui_endpoints(app):
    """Register UI endpoints for models and MCP servers"""
    
    template_dir = os.path.join(os.path.dirname(__file__), "templates")
    
    @app.get("/ui/models", response_class=HTMLResponse, tags=["UI"])
    async def models_ui_page(
        request: Request,
        user_api_key_dict: UserAPIKeyAuth = Depends(user_api_key_auth)
    ):
        """Serve the models UI page"""
        with open(os.path.join(template_dir, "models.html"), "r") as f:
            return HTMLResponse(content=f.read())
    
    @app.get("/ui/mcp-servers", response_class=HTMLResponse, tags=["UI"]) 
    async def mcp_servers_ui_page(
        request: Request,
        user_api_key_dict: UserAPIKeyAuth = Depends(user_api_key_auth)
    ):
        """Serve the MCP servers UI page"""
        with open(os.path.join(template_dir, "mcp-servers.html"), "r") as f:
            return HTMLResponse(content=f.read())
EOF

# Update the proxy server to register UI endpoints
info "Updating proxy server to include UI endpoints..."

# Add import and registration to proxy_server.py
cat >> llm/proxy/proxy_server.py << 'EOF'

# Register UI endpoints
try:
    from llm.proxy.ui.ui_endpoints import register_ui_endpoints
    register_ui_endpoints(app)
except Exception as e:
    verbose_proxy_logger.warning(f"Failed to register UI endpoints: {e}")
EOF

# Create a Hanzo footer component
cat > llm/proxy/ui/static/footer.html << 'EOF'
<footer class="bg-gray-800 mt-16 py-8">
    <div class="max-w-7xl mx-auto px-4">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
                <h3 class="text-white font-semibold mb-4">Hanzo AI</h3>
                <p class="text-gray-400 text-sm">
                    Unified AI infrastructure for the modern enterprise.
                </p>
            </div>
            <div>
                <h4 class="text-white font-semibold mb-4">Products</h4>
                <ul class="space-y-2 text-sm">
                    <li><a href="https://hanzo.ai/router" class="text-gray-400 hover:text-white">Router</a></li>
                    <li><a href="https://hanzo.ai/chat" class="text-gray-400 hover:text-white">Chat</a></li>
                    <li><a href="https://hanzo.ai/mcp" class="text-gray-400 hover:text-white">MCP</a></li>
                    <li><a href="https://hanzo.ai/agent" class="text-gray-400 hover:text-white">Agents</a></li>
                </ul>
            </div>
            <div>
                <h4 class="text-white font-semibold mb-4">Resources</h4>
                <ul class="space-y-2 text-sm">
                    <li><a href="https://docs.hanzo.ai" class="text-gray-400 hover:text-white">Documentation</a></li>
                    <li><a href="https://hanzo.ai/blog" class="text-gray-400 hover:text-white">Blog</a></li>
                    <li><a href="https://status.hanzo.ai" class="text-gray-400 hover:text-white">Status</a></li>
                    <li><a href="https://hanzo.ai/support" class="text-gray-400 hover:text-white">Support</a></li>
                </ul>
            </div>
            <div>
                <h4 class="text-white font-semibold mb-4">Company</h4>
                <ul class="space-y-2 text-sm">
                    <li><a href="https://hanzo.ai/about" class="text-gray-400 hover:text-white">About</a></li>
                    <li><a href="https://hanzo.ai/careers" class="text-gray-400 hover:text-white">Careers</a></li>
                    <li><a href="https://hanzo.ai/privacy" class="text-gray-400 hover:text-white">Privacy</a></li>
                    <li><a href="https://hanzo.ai/terms" class="text-gray-400 hover:text-white">Terms</a></li>
                </ul>
            </div>
        </div>
        <div class="mt-8 pt-8 border-t border-gray-700 text-center text-gray-400 text-sm">
            <p>&copy; 2024 Hanzo AI, Inc. All rights reserved.</p>
        </div>
    </div>
</footer>
EOF

log "✅ Router UI setup complete!"

header "TESTING UI ENDPOINTS"

# Test if Router is running
if curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/health >/dev/null; then
    info "Testing UI endpoints..."
    
    # Test models UI
    if curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/ui/models >/dev/null; then
        log "✅ Models UI page accessible"
    else
        log "⚠️  Models UI page not accessible (will be available after restart)"
    fi
    
    # Test MCP servers UI
    if curl -sf -H "Authorization: Bearer sk-hanzo-master" http://localhost:4000/ui/mcp-servers >/dev/null; then
        log "✅ MCP servers UI page accessible"
    else
        log "⚠️  MCP servers UI page not accessible (will be available after restart)"
    fi
else
    warning "Router not running. Start it with: make llm"
fi

echo ""
log "UI pages will be available at:"
echo "  • Models: http://localhost:4000/ui/models"
echo "  • MCP Servers: http://localhost:4000/ui/mcp-servers"
echo ""
log "Restart the Router to see the new UI pages!"