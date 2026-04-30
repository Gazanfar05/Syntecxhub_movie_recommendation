#!/bin/bash

# Run the Flutter app

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FLUTTER_PROJECT_DIR="$SCRIPT_DIR/flutter_app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CineMatch - Movie Recommendation     ║${NC}"
echo -e "${BLUE}║   Flutter App                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter is not installed or not in PATH${NC}"
    echo ""
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✓ Flutter version:${NC}"
flutter --version | head -1
echo ""

# Check if backend is running
echo -e "${YELLOW}Checking backend connectivity...${NC}"
if curl -s --insecure https://localhost:5000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend is running at https://localhost:5000${NC}"
else
    echo -e "${YELLOW}⚠️  Backend is not responding${NC}"
    echo "   Make sure to start the backend first:"
    echo "   ${BLUE}./run_backend.sh${NC}"
    echo ""
    echo "   Continuing anyway... (app will show error if backend is unavailable)"
fi

echo ""

cd "$FLUTTER_PROJECT_DIR"

# Get dependencies
echo -e "${YELLOW}Getting Flutter dependencies...${NC}"
flutter pub get

# Run the app
echo ""
echo -e "${GREEN}✓ Launching Flutter app...${NC}"
echo -e "${YELLOW}Note: First launch may take a few minutes${NC}"
echo ""

flutter run -v

# Cleanup on exit
echo ""
echo -e "${BLUE}Flutter app closed${NC}"
