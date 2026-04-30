#!/bin/bash

# CineMatch Backend - Simple HTTP Server
# Run this to start the movie recommendation backend

echo "CineMatch Backend Startup"
echo "=================================="

# Check if venv exists, create if not
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
fi

# Activate venv
source .venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -q flask flask-cors numpy pandas scikit-learn

# Start server
echo ""
echo "Starting CineMatch backend..."
echo "Open in browser: http://localhost:8000"
echo ""

python3 backend_enhanced.py --host 0.0.0.0 --port 8000
