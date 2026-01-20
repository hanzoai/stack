#!/bin/bash
# Fix for Chat service startup script issue

# Check if running in Docker
if [ -f /.dockerenv ]; then
    echo "Running in Docker container"

    # Try different startup commands
    if npm run start 2>/dev/null; then
        echo "Started with 'npm run start'"
    elif npm run serve 2>/dev/null; then
        echo "Started with 'npm run serve'"
    elif npm run dev 2>/dev/null; then
        echo "Started with 'npm run dev'"
    elif node server.js 2>/dev/null; then
        echo "Started with 'node server.js'"
    elif node index.js 2>/dev/null; then
        echo "Started with 'node index.js'"
    else
        echo "Error: Could not find appropriate startup script"
        echo "Available scripts:"
        npm run
        exit 1
    fi
else
    echo "This script should be run inside the Chat Docker container"
    exit 1
fi