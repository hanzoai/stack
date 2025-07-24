#!/usr/bin/env python3
import requests
import json

# Test IDE's LLM functionality through its API
ide_url = "http://localhost:3002"

# First check if IDE is running
try:
    health = requests.get(f"{ide_url}/health")
    print(f"IDE Health Check: {health.status_code}")
    
    # Get IDE info
    info = requests.get(f"{ide_url}/api/info")
    print(f"IDE Info: {info.json()}")
    
    # Get available agents
    agents = requests.get(f"{ide_url}/api/agents")
    print(f"Available Agents: {agents.json()}")
    
except Exception as e:
    print(f"Error connecting to IDE: {e}")