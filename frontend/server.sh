#!/bin/bash
# Frontend server with API proxy support for SUITER

PORT=${1:-8080}
FRONTEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting SUITER Frontend Server on http://localhost:$PORT"
echo "Serving files from: $FRONTEND_DIR"

# Check if Python is available
if command -v python3 &> /dev/null; then
    cd "$FRONTEND_DIR"
    python3 proxy_server.py $PORT
elif command -v python &> /dev/null; then
    cd "$FRONTEND_DIR"
    python proxy_server.py $PORT
else
    echo "Error: Python is required to run the server"
    exit 1
fi
