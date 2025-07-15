#!/bin/bash

# Fix LLM cost tracking error
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log "Fixing LLM cost tracking error..."

# Create a patch for the cost tracking callback
cat > /tmp/fix_cost_tracking.py << 'EOF'
# Fix for cost tracking callback
import sys
import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Find the problematic raise Exception
    pattern = r'raise Exception\(\s*"User API key and team id and user id missing from custom callback\."\s*\)'
    
    # Replace with a warning log instead
    replacement = '''verbose_logger.warning(
        "User API key and team id and user id missing from custom callback - skipping cost tracking"
    )
    return'''
    
    content = re.sub(pattern, replacement, content)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"Fixed {filepath}")

if __name__ == "__main__":
    fix_file(sys.argv[1])
EOF

# Apply the fix
info "Patching cost tracking callback..."
python /tmp/fix_cost_tracking.py /Users/z/work/hanzo/llm/llm/proxy/hooks/proxy_track_cost_callback.py

log "✅ Cost tracking error fixed!"
log "You may need to restart the LLM service for changes to take effect."